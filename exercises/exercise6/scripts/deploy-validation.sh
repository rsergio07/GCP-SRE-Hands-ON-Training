#!/bin/bash

# Exercise 6 Deployment Validation Script
# This script validates deployments using SLO metrics and monitoring data

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# SLO thresholds for deployment validation
AVAILABILITY_THRESHOLD=99.0    # 99% minimum during deployment
LATENCY_THRESHOLD=0.8         # 800ms P95 maximum
ERROR_RATE_THRESHOLD=5.0      # 5% maximum error rate
BUSINESS_SUCCESS_THRESHOLD=95.0 # 95% minimum business operation success

# Get service endpoints
get_endpoints() {
    export EXTERNAL_IP=$(kubectl get service sre-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    export PROMETHEUS_IP=$(kubectl get service prometheus-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    
    if [ -z "$EXTERNAL_IP" ] || [ "$EXTERNAL_IP" = "null" ]; then
        print_error "Cannot find SRE demo app external IP"
        return 1
    fi
    
    if [ -z "$PROMETHEUS_IP" ] || [ "$PROMETHEUS_IP" = "null" ]; then
        print_error "Cannot find Prometheus external IP"
        return 1
    fi
    
    print_status "Using SRE app at: $EXTERNAL_IP"
    print_status "Using Prometheus at: $PROMETHEUS_IP"
    return 0
}

# Check deployment health
check_deployment_health() {
    print_status "Checking deployment health..."
    
    # Check pod status
    local ready_pods=$(kubectl get pods -l app=sre-demo-app -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | wc -w)
    local total_pods=$(kubectl get pods -l app=sre-demo-app --no-headers | wc -l)
    
    if [ "$ready_pods" -eq "$total_pods" ] && [ "$ready_pods" -gt 0 ]; then
        print_success "Deployment health: $ready_pods/$total_pods pods ready"
    else
        print_error "Deployment health: $ready_pods/$total_pods pods ready"
        return 1
    fi
    
    # Check service endpoints
    local endpoints=$(kubectl get endpoints sre-demo-service -o jsonpath='{.subsets[*].addresses[*].ip}' | wc -w)
    if [ "$endpoints" -gt 0 ]; then
        print_success "Service endpoints: $endpoints ready"
    else
        print_error "Service endpoints: No endpoints ready"
        return 1
    fi
    
    return 0
}

# Validate SLO compliance
validate_slo_compliance() {
    local validation_window=${1:-"5m"}
    
    print_status "Validating SLO compliance over $validation_window..."
    
    # Availability SLO check
    local availability_query="(sum(rate(http_requests_total{status_code!~\"5..\"}[$validation_window])) / sum(rate(http_requests_total[$validation_window]))) * 100"
    local availability=$(curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=$availability_query" | jq -r '.data.result[0].value[1] // "0"' 2>/dev/null)
    
    if (( $(echo "$availability >= $AVAILABILITY_THRESHOLD" | bc -l) )); then
        print_success "✅ Availability SLO: ${availability}% (threshold: ${AVAILABILITY_THRESHOLD}%)"
    else
        print_error "❌ Availability SLO: ${availability}% (threshold: ${AVAILABILITY_THRESHOLD}%)"
        return 1
    fi
    
    # Latency SLO check
    local latency_query="histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[$validation_window])) by (le))"
    local latency=$(curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=$latency_query" | jq -r '.data.result[0].value[1] // "0"' 2>/dev/null)
    
    if (( $(echo "$latency <= $LATENCY_THRESHOLD" | bc -l) )); then
        print_success "✅ Latency SLO: ${latency}s P95 (threshold: ${LATENCY_THRESHOLD}s)"
    else
        print_error "❌ Latency SLO: ${latency}s P95 (threshold: ${LATENCY_THRESHOLD}s)"
        return 1
    fi
    
    # Error rate check
    local error_rate_query="(sum(rate(http_requests_total{status_code=~\"5..\"}[$validation_window])) / sum(rate(http_requests_total[$validation_window]))) * 100"
    local error_rate=$(curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=$error_rate_query" | jq -r '.data.result[0].value[1] // "0"' 2>/dev/null)
    
    if (( $(echo "$error_rate <= $ERROR_RATE_THRESHOLD" | bc -l) )); then
        print_success "✅ Error Rate: ${error_rate}% (threshold: ${ERROR_RATE_THRESHOLD}%)"
    else
        print_error "❌ Error Rate: ${error_rate}% (threshold: ${ERROR_RATE_THRESHOLD}%)"
        return 1
    fi
    
    # Business operation success rate
    local business_query="(sum(rate(business_operations_total{status=\"success\"}[$validation_window])) / sum(rate(business_operations_total[$validation_window]))) * 100"
    local business_success=$(curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=$business_query" | jq -r '.data.result[0].value[1] // "0"' 2>/dev/null)
    
    if (( $(echo "$business_success >= $BUSINESS_SUCCESS_THRESHOLD" | bc -l) )); then
        print_success "✅ Business Success Rate: ${business_success}% (threshold: ${BUSINESS_SUCCESS_THRESHOLD}%)"
    else
        print_error "❌ Business Success Rate: ${business_success}% (threshold: ${BUSINESS_SUCCESS_THRESHOLD}%)"
        return 1
    fi
    
    print_success "All SLO validations passed"
    return 0
}

# Test application endpoints
test_application_endpoints() {
    print_status "Testing application endpoints..."
    
    local test_count=0
    local success_count=0
    
    # Test home endpoint
    ((test_count++))
    if curl -s --max-time 10 "http://$EXTERNAL_IP/" > /dev/null; then
        print_success "Home endpoint (/) responding"
        ((success_count++))
    else
        print_error "Home endpoint (/) failed"
    fi
    
    # Test stores endpoint
    ((test_count++))
    if curl -s --max-time 10 "http://$EXTERNAL_IP/stores" > /dev/null; then
        print_success "Stores endpoint (/stores) responding"
        ((success_count++))
    else
        print_error "Stores endpoint (/stores) failed"
    fi
    
    # Test health endpoint
    ((test_count++))
    if curl -s --max-time 10 "http://$EXTERNAL_IP/health" > /dev/null; then
        print_success "Health endpoint (/health) responding"
        ((success_count++))
    else
        print_error "Health endpoint (/health) failed"
    fi
    
    # Test deployment info endpoint
    ((test_count++))
    if curl -s --max-time 10 "http://$EXTERNAL_IP/deployment" > /dev/null; then
        print_success "Deployment endpoint (/deployment) responding"
        ((success_count++))
    else
        print_error "Deployment endpoint (/deployment) failed"
    fi
    
    # Test metrics endpoint
    ((test_count++))
    if curl -s --max-time 10 "http://$EXTERNAL_IP/metrics" > /dev/null; then
        print_success "Metrics endpoint (/metrics) responding"
        ((success_count++))
    else
        print_error "Metrics endpoint (/metrics) failed"
    fi
    
    local success_rate=$((success_count * 100 / test_count))
    if [ $success_rate -ge 80 ]; then
        print_success "Endpoint tests: $success_count/$test_count passed (${success_rate}%)"
        return 0
    else
        print_error "Endpoint tests: $success_count/$test_count passed (${success_rate}%)"
        return 1
    fi
}

# Generate validation load
generate_validation_load() {
    local duration=${1:-60}
    
    print_status "Generating validation load for $duration seconds..."
    
    local end_time=$((SECONDS + duration))
    local request_count=0
    
    while [ $SECONDS -lt $end_time ]; do
        # Generate diverse request patterns
        curl -s http://$EXTERNAL_IP/ > /dev/null &
        curl -s http://$EXTERNAL_IP/stores > /dev/null &
        curl -s http://$EXTERNAL_IP/health > /dev/null &
        curl -s http://$EXTERNAL_IP/deployment > /dev/null &
        
        if [ $((request_count % 4)) -eq 0 ]; then
            curl -s http://$EXTERNAL_IP/stores/1 > /dev/null &
        fi
        
        ((request_count += 4))
        
        if [ $((request_count % 40)) -eq 0 ]; then
            local remaining=$((end_time - SECONDS))
            print_status "Load generation: $request_count requests, ${remaining}s remaining"
        fi
        
        wait
        sleep 1
    done
    
    print_success "Validation load complete: $request_count requests generated"
}

# Comprehensive deployment validation
comprehensive_validation() {
    local validation_duration=${1:-120}
    
    print_status "Running comprehensive deployment validation..."
    
    # Step 1: Check deployment health
    if ! check_deployment_health; then
        print_error "Deployment health check failed"
        return 1
    fi
    
    # Step 2: Test application endpoints
    if ! test_application_endpoints; then
        print_error "Application endpoint tests failed"
        return 1
    fi
    
    # Step 3: Generate load for metrics
    print_status "Generating load to establish baseline metrics..."
    generate_validation_load 60 &
    load_pid=$!
    
    # Step 4: Wait for metrics to stabilize
    sleep 30
    
    # Step 5: Validate SLO compliance
    if ! validate_slo_compliance "5m"; then
        print_error "SLO validation failed"
        kill $load_pid 2>/dev/null || true
        return 1
    fi
    
    # Wait for load generation to complete
    wait $load_pid
    
    # Step 6: Final SLO validation after load
    print_status "Final SLO validation after load generation..."
    if ! validate_slo_compliance "5m"; then
        print_error "Final SLO validation failed"
        return 1
    fi
    
    print_success "Comprehensive deployment validation passed!"
    return 0
}

# Create validation report
create_validation_report() {
    local report_file="deployment-validation-$(date +%Y%m%d-%H%M%S).json"
    
    print_status "Creating validation report..."
    
    # Get current metrics
    local availability_query="(sum(rate(http_requests_total{status_code!~\"5..\"}[5m])) / sum(rate(http_requests_total[5m]))) * 100"
    local availability=$(curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=$availability_query" | jq -r '.data.result[0].value[1] // "0"' 2>/dev/null)
    
    local latency_query="histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))"
    local latency=$(curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=$latency_query" | jq -r '.data.result[0].value[1] // "0"' 2>/dev/null)
    
    local error_rate_query="(sum(rate(http_requests_total{status_code=~\"5..\"}[5m])) / sum(rate(http_requests_total[5m]))) * 100"
    local error_rate=$(curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=$error_rate_query" | jq -r '.data.result[0].value[1] // "0"' 2>/dev/null)
    
    # Create JSON report
    cat > $report_file << EOF
{
  "validation_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "deployment_info": {
    "image": "$(kubectl get deployment sre-demo-app -o jsonpath='{.spec.template.spec.containers[0].image}')",
    "replicas": $(kubectl get deployment sre-demo-app -o jsonpath='{.spec.replicas}'),
    "ready_replicas": $(kubectl get deployment sre-demo-app -o jsonpath='{.status.readyReplicas}')
  },
  "slo_metrics": {
    "availability": {
      "value": $availability,
      "threshold": $AVAILABILITY_THRESHOLD,
      "passed": $(echo "$availability >= $AVAILABILITY_THRESHOLD" | bc -l)
    },
    "latency_p95": {
      "value": $latency,
      "threshold": $LATENCY_THRESHOLD,
      "passed": $(echo "$latency <= $LATENCY_THRESHOLD" | bc -l)
    },
    "error_rate": {
      "value": $error_rate,
      "threshold": $ERROR_RATE_THRESHOLD,
      "passed": $(echo "$error_rate <= $ERROR_RATE_THRESHOLD" | bc -l)
    }
  },
  "validation_result": "$([ $? -eq 0 ] && echo "PASSED" || echo "FAILED")"
}
EOF

    print_success "Validation report created: $report_file"
    cat $report_file | jq .
}

# Main execution
main() {
    local operation=${1:-"validate"}
    local duration=${2:-120}
    
    case $operation in
        "validate")
            print_status "Starting deployment validation..."
            if get_endpoints; then
                comprehensive_validation $duration
                create_validation_report
            else
                print_error "Cannot get service endpoints for validation"
                exit 1
            fi
            ;;
        "test")
            print_status "Running validation tests..."
            if get_endpoints; then
                test_application_endpoints
                validate_slo_compliance "5m"
            else
                print_error "Cannot get service endpoints for testing"
                exit 1
            fi
            ;;
        "slo")
            print_status "Checking SLO compliance..."
            if get_endpoints; then
                validate_slo_compliance "5m"
            else
                print_error "Cannot get service endpoints for SLO check"
                exit 1
            fi
            ;;
        "load")
            print_status "Generating validation load..."
            if get_endpoints; then
                generate_validation_load $duration
            else
                print_error "Cannot get service endpoints for load generation"
                exit 1
            fi
            ;;
        "health")
            check_deployment_health
            ;;
        "report")
            if get_endpoints; then
                create_validation_report
            else
                print_error "Cannot get service endpoints for report generation"
                exit 1
            fi
            ;;
        "help")
            echo "Usage: $0 [operation] [duration]"
            echo ""
            echo "Operations:"
            echo "  validate    Run comprehensive deployment validation (default)"
            echo "  test        Test application endpoints and basic SLO compliance"
            echo "  slo         Check SLO compliance only"
            echo "  load        Generate validation load for specified duration"
            echo "  health      Check deployment health only"
            echo "  report      Generate validation report"
            echo "  help        Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 validate 180    # Full validation with 3-minute load test"
            echo "  $0 slo            # Quick SLO compliance check"
            echo "  $0 load 300       # Generate load for 5 minutes"
            ;;
        *)
            print_error "Unknown operation: $operation"
            print_status "Use '$0 help' for usage information"
            return 1
            ;;
    esac
}

# Run main function with arguments
main "$@"