#!/bin/bash

# Exercise 4 Monitoring Verification Script
# This script verifies the monitoring stack is working correctly

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

# Generate load for testing
generate_load() {
    local app_ip=$1
    local duration=${2:-60}
    
    print_status "Generating load for $duration seconds..."
    
    local end_time=$((SECONDS + duration))
    local request_count=0
    
    while [ $SECONDS -lt $end_time ]; do
        # Generate various types of requests
        curl -s http://$app_ip/ > /dev/null &
        curl -s http://$app_ip/stores > /dev/null &
        curl -s http://$app_ip/health > /dev/null &
        curl -s http://$app_ip/stores/1 > /dev/null &
        
        ((request_count += 4))
        
        if [ $((request_count % 40)) -eq 0 ]; then
            local remaining=$((end_time - SECONDS))
            print_status "Load generation: $request_count requests sent, ${remaining}s remaining"
        fi
        
        wait
        sleep 1
    done
    
    print_success "Load generation complete: $request_count total requests"
}

# Test Prometheus queries
test_prometheus_queries() {
    local prometheus_ip=$1
    
    print_status "Testing Prometheus queries..."
    
    local queries=(
        "sum(rate(http_requests_total[5m]))"
        "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))"
        "sum(rate(business_operations_total[5m])) by (operation_type, status)"
        "active_connections_current"
    )
    
    local success_count=0
    
    for query in "${queries[@]}"; do
        local encoded_query=$(echo "$query" | sed 's/ /%20/g' | sed 's/\[/%5B/g' | sed 's/\]/%5D/g' | sed 's/(/%28/g' | sed 's/)/%29/g')
        local response=$(curl -s "http://$prometheus_ip:9090/api/v1/query?query=$encoded_query")
        
        if echo "$response" | grep -q '"status":"success"'; then
            print_success "Query successful: $query"
            ((success_count++))
        else
            print_warning "Query failed or no data: $query"
        fi
    done
    
    if [ $success_count -eq ${#queries[@]} ]; then
        print_success "All Prometheus queries working correctly"
    else
        print_warning "$success_count/${#queries[@]} queries successful"
    fi
    
    return 0
}

# Check service discovery
check_service_discovery() {
    local prometheus_ip=$1
    
    print_status "Checking Prometheus service discovery..."
    
    local targets_response=$(curl -s "http://$prometheus_ip:9090/api/v1/targets")
    local active_targets=$(echo "$targets_response" | grep -o '"health":"up"' | wc -l)
    local total_targets=$(echo "$targets_response" | grep -o '"health":"' | wc -l)
    
    print_status "Active targets: $active_targets/$total_targets"
    
    if [ $active_targets -gt 0 ]; then
        print_success "Service discovery is working"
    else
        print_warning "No active targets found"
    fi
    
    # Check if SRE demo app is being scraped
    if echo "$targets_response" | grep -q "sre-demo-app"; then
        print_success "SRE demo app is being monitored"
    else
        print_warning "SRE demo app not found in targets"
    fi
}

# Verify Google Cloud Monitoring
verify_gcp_monitoring() {
    print_status "Verifying Google Cloud Monitoring integration..."
    
    # Check available metrics
    local custom_metrics=$(gcloud monitoring metrics list --filter="metric.type:custom.googleapis.com" --limit=5 2>/dev/null | wc -l)
    
    if [ $custom_metrics -gt 0 ]; then
        print_success "Custom metrics found in Google Cloud Monitoring"
    else
        print_warning "No custom metrics found yet (may take 5-10 minutes to appear)"
    fi
    
    # Check project monitoring status
    local project_id=$(gcloud config get-value project)
    print_status "Google Cloud Monitoring dashboard: https://console.cloud.google.com/monitoring/overview?project=$project_id"
}

# Check pod and service health
check_infrastructure() {
    print_status "Checking monitoring infrastructure health..."
    
    # Check Prometheus deployment
    local prometheus_ready=$(kubectl get deployment prometheus -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    local prometheus_desired=$(kubectl get deployment prometheus -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")
    
    if [ "$prometheus_ready" = "$prometheus_desired" ]; then
        print_success "Prometheus deployment: $prometheus_ready/$prometheus_desired pods ready"
    else
        print_error "Prometheus deployment: $prometheus_ready/$prometheus_desired pods ready"
        return 1
    fi
    
    # Check SRE demo app
    local app_ready=$(kubectl get deployment sre-demo-app -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    local app_desired=$(kubectl get deployment sre-demo-app -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "2")
    
    if [ "$app_ready" = "$app_desired" ]; then
        print_success "SRE demo app: $app_ready/$app_desired pods ready"
    else
        print_error "SRE demo app: $app_ready/$app_desired pods ready"
        return 1
    fi
    
    # Check services
    local prometheus_ip=$(kubectl get service prometheus-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    local app_ip=$(kubectl get service sre-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    
    if [ -n "$prometheus_ip" ] && [ "$prometheus_ip" != "null" ]; then
        print_success "Prometheus service has external IP: $prometheus_ip"
    else
        print_error "Prometheus service missing external IP"
        return 1
    fi
    
    if [ -n "$app_ip" ] && [ "$app_ip" != "null" ]; then
        print_success "SRE demo app has external IP: $app_ip"
    else
        print_error "SRE demo app missing external IP"
        return 1
    fi
    
    echo "$prometheus_ip $app_ip"
}

# Comprehensive monitoring test
run_monitoring_test() {
    print_status "Running comprehensive monitoring verification..."
    
    # Get service IPs
    local ips
    ips=$(check_infrastructure)
    if [ $? -ne 0 ]; then
        print_error "Infrastructure health check failed"
        return 1
    fi
    
    local prometheus_ip=$(echo $ips | cut -d' ' -f1)
    local app_ip=$(echo $ips | cut -d' ' -f2)
    
    print_status "Using Prometheus at: $prometheus_ip"
    print_status "Using SRE demo app at: $app_ip"
    
    # Generate baseline traffic
    generate_load $app_ip 60 &
    load_pid=$!
    
    # Wait a moment for initial metrics
    sleep 10
    
    # Test Prometheus functionality
    check_service_discovery $prometheus_ip
    test_prometheus_queries $prometheus_ip
    
    # Verify Google Cloud integration
    verify_gcp_monitoring
    
    # Wait for load generation to complete
    wait $load_pid
    
    # Final verification
    print_status "Final verification after load generation..."
    test_prometheus_queries $prometheus_ip
    
    print_success "Comprehensive monitoring test completed!"
}

# Display summary information
show_summary() {
    local prometheus_ip=$1
    local app_ip=$2
    local project_id=$(gcloud config get-value project)
    
    echo ""
    print_success "=== MONITORING STACK VERIFICATION SUMMARY ==="
    echo ""
    print_status "Access Points:"
    echo "  • Prometheus Web UI: http://$prometheus_ip:9090"
    echo "  • SRE Demo Application: http://$app_ip"
    echo "  • Google Cloud Monitoring: https://console.cloud.google.com/monitoring/overview?project=$project_id"
    echo ""
    print_status "Key Queries to Test in Prometheus:"
    echo "  • Request Rate: sum(rate(http_requests_total[5m]))"
    echo "  • Error Rate: sum(rate(http_requests_total{status_code=~\"5..\"}[5m])) / sum(rate(http_requests_total[5m])) * 100"
    echo "  • P95 Latency: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))"
    echo "  • Business Metrics: sum(rate(business_operations_total[5m])) by (operation_type, status)"
    echo ""
    print_status "Next Steps:"
    echo "  • Check dashboards in Google Cloud Console"
    echo "  • Continue to Exercise 5 for alerting setup"
    echo "  • Review monitoring/sre-queries.md for additional query examples"
    echo ""
}

# Main execution
main() {
    local operation=${1:-"full"}
    
    case $operation in
        "infrastructure")
            ips=$(check_infrastructure)
            if [ $? -eq 0 ]; then
                prometheus_ip=$(echo $ips | cut -d' ' -f1)
                app_ip=$(echo $ips | cut -d' ' -f2)
                show_summary $prometheus_ip $app_ip
            fi
            ;;
        "load")
            local app_ip=$(kubectl get service sre-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
            if [ -n "$app_ip" ] && [ "$app_ip" != "null" ]; then
                generate_load $app_ip ${2:-120}
            else
                print_error "Cannot find SRE demo app external IP"
                exit 1
            fi
            ;;
        "queries")
            local prometheus_ip=$(kubectl get service prometheus-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
            if [ -n "$prometheus_ip" ] && [ "$prometheus_ip" != "null" ]; then
                test_prometheus_queries $prometheus_ip
            else
                print_error "Cannot find Prometheus external IP"
                exit 1
            fi
            ;;
        "full")
            run_monitoring_test
            ;;
        "help")
            echo "Usage: $0 [operation]"
            echo ""
            echo "Operations:"
            echo "  full           Run complete monitoring verification (default)"
            echo "  infrastructure Check deployment and service health"
            echo "  load [seconds] Generate load for specified duration (default: 120s)"
            echo "  queries        Test Prometheus queries"
            echo "  help           Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                    # Run full verification"
            echo "  $0 load 300           # Generate load for 5 minutes"
            echo "  $0 infrastructure     # Check infrastructure only"
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