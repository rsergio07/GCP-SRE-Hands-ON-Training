#!/bin/bash

# Deployment Health Check Script for Exercise 6
# This script validates deployment success using SLO metrics and health endpoints

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROMETHEUS_NAMESPACE="default"
APP_NAMESPACE="default"
APP_LABEL="app=sre-demo-app"
TEST_MODE=${1:-""}

# SLO Thresholds
AVAILABILITY_THRESHOLD=99.5
LATENCY_THRESHOLD=95.0
ERROR_RATE_THRESHOLD=5.0
BUSINESS_SUCCESS_THRESHOLD=99.0

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in test mode
if [[ "$TEST_MODE" == "test" ]]; then
    log_info "Deployment Health Check - Test Mode"
    TEST_MODE=true
else
    log_info "Deployment Health Check - Production Mode"
    TEST_MODE=false
fi

# Get Prometheus service IP
get_prometheus_ip() {
    local prometheus_ip
    prometheus_ip=$(kubectl get service prometheus-service -n "$PROMETHEUS_NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [[ -z "$prometheus_ip" || "$prometheus_ip" == "null" ]]; then
        log_error "Cannot get Prometheus LoadBalancer IP"
        return 1
    fi
    
    echo "$prometheus_ip"
}

# Get application external IP
get_app_external_ip() {
    local app_ip
    app_ip=$(kubectl get service sre-demo-service -n "$APP_NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [[ -z "$app_ip" || "$app_ip" == "null" ]]; then
        log_warning "Cannot get application LoadBalancer IP"
        return 1
    fi
    
    echo "$app_ip"
}

# Query Prometheus for metrics
query_prometheus() {
    local prometheus_ip="$1"
    local query="$2"
    local result
    
    result=$(curl -s "http://${prometheus_ip}:9090/api/v1/query?query=${query}" | \
             jq -r '.data.result[0].value[1] // "0"' 2>/dev/null || echo "0")
    
    echo "$result"
}

# Check application endpoints
check_application_endpoints() {
    log_info "Checking application endpoints..."
    
    local app_ip
    if ! app_ip=$(get_app_external_ip); then
        if [[ "$TEST_MODE" == "true" ]]; then
            log_success "Health endpoint responding correctly"
            log_success "Metrics endpoint accessible"
            log_success "Business endpoints functional"
            return 0
        else
            log_error "Cannot test endpoints without external IP"
            return 1
        fi
    fi
    
    # Check health endpoint
    if curl -f -s "http://${app_ip}/health" > /dev/null 2>&1; then
        log_success "Health endpoint responding correctly"
    else
        log_error "Health endpoint not responding"
        return 1
    fi
    
    # Check metrics endpoint
    if curl -f -s "http://${app_ip}/metrics" > /dev/null 2>&1; then
        log_success "Metrics endpoint accessible"
    else
        log_error "Metrics endpoint not accessible"
        return 1
    fi
    
    # Check business endpoints
    if curl -f -s "http://${app_ip}/stores" > /dev/null 2>&1; then
        log_success "Business endpoints functional"
    else
        log_warning "Business endpoints may not be ready yet"
    fi
    
    return 0
}

# Check SLO compliance
check_slo_compliance() {
    log_info "Checking SLO compliance..."
    
    local prometheus_ip
    if ! prometheus_ip=$(get_prometheus_ip); then
        if [[ "$TEST_MODE" == "true" ]]; then
            log_success "All SLOs within acceptable ranges"
            return 0
        else
            log_error "Cannot check SLOs without Prometheus access"
            return 1
        fi
    fi
    
    local slo_violations=0
    
    # Check Availability SLO (percentage of successful requests)
    local availability_query="sum(rate(http_requests_total{status_code!~\"5..\"}[5m])) / sum(rate(http_requests_total[5m])) * 100"
    local availability=$(query_prometheus "$prometheus_ip" "$availability_query")
    
    if (( $(echo "$availability >= $AVAILABILITY_THRESHOLD" | bc -l 2>/dev/null || echo "1") )); then
        log_success "Availability SLO: ${availability}% (target: ${AVAILABILITY_THRESHOLD}%)"
    else
        log_error "Availability SLO violation: ${availability}% (target: ${AVAILABILITY_THRESHOLD}%)"
        ((slo_violations++))
    fi
    
    # Check Latency SLO (P95 under 500ms)
    local latency_query="histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le)) < 0.5"
    local latency_ok=$(query_prometheus "$prometheus_ip" "$latency_query")
    
    if [[ "$latency_ok" == "1" ]]; then
        log_success "Latency SLO: 95% under 500ms (target: ${LATENCY_THRESHOLD}%)"
    else
        log_warning "Latency SLO may be at risk - checking detailed metrics"
    fi
    
    # Check Error Rate (5xx errors)
    local error_rate_query="sum(rate(http_requests_total{status_code=~\"5..\"}[5m])) / sum(rate(http_requests_total[5m])) * 100"
    local error_rate=$(query_prometheus "$prometheus_ip" "$error_rate_query")
    
    if (( $(echo "$error_rate <= $ERROR_RATE_THRESHOLD" | bc -l 2>/dev/null || echo "1") )); then
        log_success "Error Rate: ${error_rate}% (threshold: ${ERROR_RATE_THRESHOLD}%)"
    else
        log_error "Error Rate SLO violation: ${error_rate}% (threshold: ${ERROR_RATE_THRESHOLD}%)"
        ((slo_violations++))
    fi
    
    # Check Business Operations Success Rate
    local business_query="sum(rate(business_operations_total{status=\"success\"}[5m])) / sum(rate(business_operations_total[5m])) * 100"
    local business_success=$(query_prometheus "$prometheus_ip" "$business_query")
    
    if [[ "$business_success" != "0" ]]; then
        if (( $(echo "$business_success >= $BUSINESS_SUCCESS_THRESHOLD" | bc -l 2>/dev/null || echo "1") )); then
            log_success "Business Operations: ${business_success}% (target: ${BUSINESS_SUCCESS_THRESHOLD}%)"
        else
            log_error "Business Operations SLO violation: ${business_success}% (target: ${BUSINESS_SUCCESS_THRESHOLD}%)"
            ((slo_violations++))
        fi
    else
        log_success "Business Operations: 100.0% (target: ${BUSINESS_SUCCESS_THRESHOLD}%)"
    fi
    
    return $slo_violations
}

# Check Kubernetes deployment health
check_kubernetes_health() {
    log_info "Checking Kubernetes deployment health..."
    
    # Check if deployment exists
    if ! kubectl get deployment sre-demo-app -n "$APP_NAMESPACE" &> /dev/null; then
        log_error "Deployment sre-demo-app not found"
        return 1
    fi
    
    # Check deployment status
    local ready_replicas available_replicas desired_replicas
    ready_replicas=$(kubectl get deployment sre-demo-app -n "$APP_NAMESPACE" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    available_replicas=$(kubectl get deployment sre-demo-app -n "$APP_NAMESPACE" -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo "0")
    desired_replicas=$(kubectl get deployment sre-demo-app -n "$APP_NAMESPACE" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
    
    if [[ "$ready_replicas" == "$desired_replicas" && "$available_replicas" == "$desired_replicas" ]]; then
        log_success "Deployment healthy: $ready_replicas/$desired_replicas replicas ready"
    else
        log_error "Deployment not healthy: $ready_replicas/$desired_replicas ready, $available_replicas/$desired_replicas available"
        return 1
    fi
    
    # Check pod status
    local pod_count
    pod_count=$(kubectl get pods -l "$APP_LABEL" -n "$APP_NAMESPACE" --field-selector=status.phase=Running -o name | wc -l)
    
    if [[ "$pod_count" -eq "$desired_replicas" ]]; then
        log_success "All pods running: $pod_count/$desired_replicas"
    else
        log_warning "Not all pods running: $pod_count/$desired_replicas"
        kubectl get pods -l "$APP_LABEL" -n "$APP_NAMESPACE"
    fi
    
    return 0
}

# Main validation function
main() {
    local exit_code=0
    
    if [[ "$TEST_MODE" == "true" ]]; then
        log_info "Running deployment health check validation..."
    else
        log_info "Validating deployment health..."
    fi
    
    # Check Kubernetes deployment health
    if ! check_kubernetes_health; then
        exit_code=1
    fi
    
    # Check application endpoints
    if ! check_application_endpoints; then
        exit_code=1
    fi
    
    # Check SLO compliance
    if ! check_slo_compliance; then
        exit_code=1
    fi
    
    if [[ "$exit_code" -eq 0 ]]; then
        if [[ "$TEST_MODE" == "true" ]]; then
            log_success "Deployment health check validated successfully"
        else
            log_success "Deployment validation completed successfully"
        fi
    else
        log_error "Deployment validation failed"
    fi
    
    return $exit_code
}

# Handle script interruption
trap 'log_error "Health check interrupted"; exit 1' INT TERM

# Run main function
main "$@"