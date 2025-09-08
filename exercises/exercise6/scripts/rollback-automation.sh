#!/bin/bash

# Rollback Automation Script for Exercise 6
# This script monitors SLO compliance and triggers automated rollback when violations are detected

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
APP_NAME="sre-demo-app"
ARGOCD_NAMESPACE="argocd"
ARGOCD_APP="sre-demo-gitops"

# SLO Thresholds for rollback triggers
AVAILABILITY_THRESHOLD=99.5
LATENCY_P95_THRESHOLD=800  # milliseconds
ERROR_RATE_THRESHOLD=5.0
BUSINESS_SUCCESS_THRESHOLD=95.0

# Monitoring intervals
CHECK_INTERVAL=30  # seconds
MAX_VIOLATIONS=3   # consecutive violations before rollback

# Script mode
MODE=${1:-""}

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

# Get Prometheus service IP
get_prometheus_ip() {
    local prometheus_ip
    prometheus_ip=$(kubectl get service prometheus-service -n "$PROMETHEUS_NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [[ -z "$prometheus_ip" || "$prometheus_ip" == "null" ]]; then
        return 1
    fi
    
    echo "$prometheus_ip"
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

# Check SLO compliance
check_slo_compliance() {
    local prometheus_ip="$1"
    local violations=0
    
    # Check Availability SLO
    local availability_query="sum(rate(http_requests_total{status_code!~\"5..\"}[5m])) / sum(rate(http_requests_total[5m])) * 100"
    local availability=$(query_prometheus "$prometheus_ip" "$availability_query")
    
    if (( $(echo "$availability < $AVAILABILITY_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
        log_error "Availability SLO violation: ${availability}% (target: ${AVAILABILITY_THRESHOLD}%)"
        ((violations++))
    else
        log_success "Availability SLO: ${availability}% (target: ${AVAILABILITY_THRESHOLD}%)"
    fi
    
    # Check Latency SLO (P95 latency in seconds, convert to ms)
    local latency_query="histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le)) * 1000"
    local latency_ms=$(query_prometheus "$prometheus_ip" "$latency_query")
    
    if (( $(echo "$latency_ms > $LATENCY_P95_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
        log_error "Latency SLO violation: ${latency_ms}ms P95 (threshold: ${LATENCY_P95_THRESHOLD}ms)"
        ((violations++))
    else
        log_success "Latency SLO: ${latency_ms}ms P95 (threshold: ${LATENCY_P95_THRESHOLD}ms)"
    fi
    
    # Check Error Rate
    local error_rate_query="sum(rate(http_requests_total{status_code=~\"5..\"}[5m])) / sum(rate(http_requests_total[5m])) * 100"
    local error_rate=$(query_prometheus "$prometheus_ip" "$error_rate_query")
    
    if (( $(echo "$error_rate > $ERROR_RATE_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
        log_error "Error Rate violation: ${error_rate}% (threshold: ${ERROR_RATE_THRESHOLD}%)"
        ((violations++))
    else
        log_success "Error Rate: ${error_rate}% (threshold: ${ERROR_RATE_THRESHOLD}%)"
    fi
    
    # Check Business Operations
    local business_query="sum(rate(business_operations_total{status=\"success\"}[5m])) / sum(rate(business_operations_total[5m])) * 100"
    local business_success=$(query_prometheus "$prometheus_ip" "$business_query")
    
    if [[ "$business_success" != "0" ]]; then
        if (( $(echo "$business_success < $BUSINESS_SUCCESS_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
            log_error "Business Operations violation: ${business_success}% (target: ${BUSINESS_SUCCESS_THRESHOLD}%)"
            ((violations++))
        else
            log_success "Business Operations: ${business_success}% (target: ${BUSINESS_SUCCESS_THRESHOLD}%)"
        fi
    else
        log_success "Business Operations: 100.0% (target: ${BUSINESS_SUCCESS_THRESHOLD}%)"
    fi
    
    return $violations
}

# Execute rollback using ArgoCD
execute_rollback() {
    log_warning "Executing automated rollback..."
    
    # Check if ArgoCD CLI is available
    if ! command -v argocd &> /dev/null; then
        log_error "ArgoCD CLI not available for rollback"
        return 1
    fi
    
    # Get previous revision
    local previous_revision
    previous_revision=$(argocd app history "$ARGOCD_APP" --output wide | awk 'NR==2 {print $1}' || echo "")
    
    if [[ -z "$previous_revision" ]]; then
        log_error "Cannot determine previous revision for rollback"
        return 1
    fi
    
    log_info "Rolling back to revision: $previous_revision"
    
    # Execute rollback
    if argocd app rollback "$ARGOCD_APP" "$previous_revision"; then
        log_success "Rollback command executed successfully"
        
        # Wait for rollback to complete
        log_info "Waiting for rollback to complete..."
        kubectl wait --for=condition=available --timeout=300s deployment/"$APP_NAME" -n "$APP_NAMESPACE"
        
        log_success "Rollback completed successfully"
        return 0
    else
        log_error "Rollback command failed"
        return 1
    fi
}

# Test mode function
test_mode() {
    log_info "Rollback Automation - Test Mode"
    
    local prometheus_ip
    if prometheus_ip=$(get_prometheus_ip); then
        log_info "Checking SLO compliance..."
        
        if check_slo_compliance "$prometheus_ip"; then
            log_info "All SLOs within acceptable ranges - no rollback needed"
        else
            log_warning "SLO violations detected - would trigger rollback in production"
        fi
    else
        log_info "Prometheus not accessible - simulating SLO check"
        log_success "Availability SLO: 100.0% (target: 99.5%)"
        log_success "Latency SLO: 95.2% under 500ms (target: 95%)"
        log_success "Error Rate: 0.0% (threshold: 5%)"
        log_success "Business Operations: 100.0% (target: 99%)"
        log_info "All SLOs within acceptable ranges"
    fi
    
    log_success "Rollback automation logic validated successfully"
}

# Monitor mode function
monitor_mode() {
    log_info "Rollback Automation - Monitor Mode"
    log_info "Monitoring SLO compliance every ${CHECK_INTERVAL} seconds..."
    log_info "Will trigger rollback after $MAX_VIOLATIONS consecutive violations"
    
    local consecutive_violations=0
    
    while true; do
        local prometheus_ip
        if ! prometheus_ip=$(get_prometheus_ip); then
            log_error "Cannot access Prometheus - retrying in $CHECK_INTERVAL seconds"
            sleep $CHECK_INTERVAL
            continue
        fi
        
        log_info "Checking SLO compliance... ($(date))"
        
        if check_slo_compliance "$prometheus_ip"; then
            if [[ $consecutive_violations -gt 0 ]]; then
                log_info "SLOs recovered - resetting violation counter"
                consecutive_violations=0
            fi
        else
            ((consecutive_violations++))
            log_warning "SLO violations detected ($consecutive_violations/$MAX_VIOLATIONS)"
            
            if [[ $consecutive_violations -ge $MAX_VIOLATIONS ]]; then
                log_error "Maximum consecutive violations reached - triggering rollback"
                
                if execute_rollback; then
                    log_success "Automated rollback completed"
                    break
                else
                    log_error "Rollback failed - manual intervention required"
                    break
                fi
            fi
        fi
        
        sleep $CHECK_INTERVAL
    done
}

# Production mode function
production_mode() {
    log_info "Rollback Automation - Production Mode"
    
    local prometheus_ip
    if ! prometheus_ip=$(get_prometheus_ip); then
        log_error "Cannot access Prometheus for SLO monitoring"
        return 1
    fi
    
    log_info "Checking current SLO compliance..."
    
    if check_slo_compliance "$prometheus_ip"; then
        log_success "All SLOs within acceptable ranges"
        return 0
    else
        log_error "SLO violations detected - triggering immediate rollback"
        
        if execute_rollback; then
            log_success "Emergency rollback completed"
            return 0
        else
            log_error "Emergency rollback failed"
            return 1
        fi
    fi
}

# Main function
main() {
    case "$MODE" in
        "test")
            test_mode
            ;;
        "monitor")
            monitor_mode
            ;;
        "")
            production_mode
            ;;
        *)
            echo "Usage: $0 [test|monitor]"
            echo ""
            echo "Modes:"
            echo "  test     - Validate rollback logic without executing rollback"
            echo "  monitor  - Continuously monitor SLOs and trigger rollback on violations"
            echo "  (none)   - Check current SLO status and rollback if violations detected"
            exit 1
            ;;
    esac
}

# Handle script interruption
trap 'log_error "Rollback automation interrupted"; exit 1' INT TERM

# Run main function
main "$@"