#!/bin/bash

# Exercise 5 Alert Testing Script
# This script tests different alerting scenarios to validate alert policies

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

# Get service IPs
get_service_ips() {
    export EXTERNAL_IP=$(kubectl get service sre-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    export PROMETHEUS_IP=$(kubectl get service prometheus-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    export ALERTMANAGER_IP=$(kubectl get service alertmanager-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    
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
    if [ -n "$ALERTMANAGER_IP" ] && [ "$ALERTMANAGER_IP" != "null" ]; then
        print_status "Using Alertmanager at: $ALERTMANAGER_IP"
    fi
}

# Check current alert status
check_alert_status() {
    print_status "Checking current alert status..."
    
    # Query Prometheus for active alerts
    local active_alerts=$(curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=ALERTS" | jq -r '.data.result | length')
    print_status "Active alerts: $active_alerts"
    
    # List active alerts
    curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=ALERTS{alertstate=\"firing\"}" | \
        jq -r '.data.result[] | "\(.metric.alertname): \(.metric.severity)"' | \
        while read alert; do
            if [ -n "$alert" ]; then
                print_warning "  Active: $alert"
            fi
        done
    
    if [ -n "$ALERTMANAGER_IP" ] && [ "$ALERTMANAGER_IP" != "null" ]; then
        print_status "Check Alertmanager at: http://$ALERTMANAGER_IP:9093"
    fi
    print_status "Check Prometheus alerts at: http://$PROMETHEUS_IP:9090/alerts"
}

# Test availability alerting by making service unavailable
test_availability_alerts() {
    local duration=${1:-180}  # Default 3 minutes
    
    print_status "Testing availability alerts for $duration seconds..."
    print_warning "This will make the service temporarily unavailable!"
    
    # Scale down to 0 replicas
    local original_replicas=$(kubectl get deployment sre-demo-app -o jsonpath='{.spec.replicas}')
    print_status "Current replicas: $original_replicas"
    
    print_status "Scaling down to 0 replicas..."
    kubectl scale deployment sre-demo-app --replicas=0
    
    # Wait for scale down
    kubectl wait --for=delete pod -l app=sre-demo-app --timeout=60s
    print_status "Service is now unavailable"
    
    # Monitor for alerts
    local end_time=$((SECONDS + duration))
    local alert_triggered=false
    
    print_status "Monitoring for ServiceUnavailable alert..."
    while [ $SECONDS -lt $end_time ]; do
        # Check if alert is firing
        local alert_status=$(curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=ALERTS{alertname=\"ServiceUnavailable\",alertstate=\"firing\"}" | jq -r '.data.result | length')
        
        if [ "$alert_status" -gt 0 ]; then
            if [ "$alert_triggered" = false ]; then
                print_success "✅ ServiceUnavailable alert triggered!"
                alert_triggered=true
            fi
        fi
        
        local remaining=$((end_time - SECONDS))
        print_status "Waiting for alerts... ${remaining}s remaining"
        sleep 10
    done
    
    # Restore service
    print_status "Restoring service (scaling back to $original_replicas replicas)..."
    kubectl scale deployment sre-demo-app --replicas=$original_replicas
    kubectl wait --for=condition=available --timeout=120s deployment/sre-demo-app
    
    print_success "Service restored"
    
    if [ "$alert_triggered" = true ]; then
        print_success "✅ Availability alerting test PASSED"
    else
        print_error "❌ Availability alerting test FAILED - No alert triggered"
    fi
}

# Test latency alerting by injecting artificial delays
test_latency_alerts() {
    local duration=${1:-300}  # Default 5 minutes
    
    print_status "Testing latency alerts for $duration seconds..."
    print_warning "This will cause high latency for the service!"
    
    # Create a chaos pod that overloads the system to cause latency
    print_status "Starting latency injection..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: latency-chaos-job
spec:
  template:
    spec:
      containers:
      - name: chaos
        image: alpine/curl
        command:
        - /bin/sh
        - -c
        - |
          echo "Starting latency chaos test..."
          for i in \$(seq 1 $duration); do
            for j in \$(seq 1 20); do
              curl -s http://sre-demo-service/stores > /dev/null &
            done
            sleep 1
          done
          echo "Latency chaos test completed"
      restartPolicy: Never
  backoffLimit: 1
EOF

    # Monitor for high latency alerts
    local end_time=$((SECONDS + duration))
    local alert_triggered=false
    
    print_status "Monitoring for HighLatency alert..."
    while [ $SECONDS -lt $end_time ]; do
        # Check current P95 latency
        local p95_latency=$(curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=histogram_quantile(0.95,%20sum(rate(http_request_duration_seconds_bucket[5m]))%20by%20(le))" | jq -r '.data.result[0].value[1] // "0"')
        
        # Check if high latency alert is firing
        local alert_status=$(curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=ALERTS{alertname=\"HighLatency\",alertstate=\"firing\"}" | jq -r '.data.result | length')
        
        if [ "$alert_status" -gt 0 ]; then
            if [ "$alert_triggered" = false ]; then
                print_success "✅ HighLatency alert triggered! P95: ${p95_latency}s"
                alert_triggered=true
            fi
        fi
        
        local remaining=$((end_time - SECONDS))
        print_status "P95 latency: ${p95_latency}s, waiting... ${remaining}s remaining"
        sleep 15
    done
    
    # Clean up chaos job
    print_status "Cleaning up latency test..."
    kubectl delete job latency-chaos-job --ignore-not-found=true
    
    if [ "$alert_triggered" = true ]; then
        print_success "✅ Latency alerting test PASSED"
    else
        print_warning "⚠️  Latency alerting test INCONCLUSIVE - May need more load"
    fi
}

# Test error rate alerting by simulating application errors
test_error_rate_alerts() {
    local duration=${1:-240}  # Default 4 minutes
    
    print_status "Testing error rate alerts for $duration seconds..."
    print_warning "This will cause elevated error rates!"
    
    # Create chaos to generate errors by hitting non-existent endpoints
    print_status "Starting error rate injection..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: error-chaos-job
spec:
  template:
    spec:
      containers:
      - name: chaos
        image: alpine/curl
        command:
        - /bin/sh
        - -c
        - |
          echo "Starting error rate chaos test..."
          for i in \$(seq 1 $duration); do
            # Generate mix of good and bad requests
            curl -s http://sre-demo-service/ > /dev/null &
            curl -s http://sre-demo-service/stores > /dev/null &
            # Generate 500 errors by hitting non-existent endpoints
            for j in \$(seq 1 5); do
              curl -s http://sre-demo-service/nonexistent > /dev/null &
              curl -s http://sre-demo-service/error > /dev/null &
            done
            sleep 1
          done
          echo "Error rate chaos test completed"
      restartPolicy: Never
  backoffLimit: 1
EOF

    # Monitor for error rate alerts
    local end_time=$((SECONDS + duration))
    local alert_triggered=false
    
    print_status "Monitoring for HighErrorRate alert..."
    while [ $SECONDS -lt $end_time ]; do
        # Check current error rate
        local error_rate=$(curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=sum(rate(http_requests_total{status_code=~\"5..\"}[5m]))%20/%20sum(rate(http_requests_total[5m]))%20*%20100" | jq -r '.data.result[0].value[1] // "0"')
        
        # Check if high error rate alert is firing
        local alert_status=$(curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=ALERTS{alertname=\"HighErrorRate\",alertstate=\"firing\"}" | jq -r '.data.result | length')
        
        if [ "$alert_status" -gt 0 ]; then
            if [ "$alert_triggered" = false ]; then
                print_success "✅ HighErrorRate alert triggered! Error rate: ${error_rate}%"
                alert_triggered=true
            fi
        fi
        
        local remaining=$((end_time - SECONDS))
        print_status "Error rate: ${error_rate}%, waiting... ${remaining}s remaining"
        sleep 15
    done
    
    # Clean up chaos job
    print_status "Cleaning up error rate test..."
    kubectl delete job error-chaos-job --ignore-not-found=true
    
    if [ "$alert_triggered" = true ]; then
        print_success "✅ Error rate alerting test PASSED"
    else
        print_warning "⚠️  Error rate alerting test INCONCLUSIVE - Check alert thresholds"
    fi
}

# Test SLO burn rate alerts
test_slo_burn_rate_alerts() {
    print_status "Testing SLO burn rate alerts..."
    print_status "This combines availability and latency degradation..."
    
    # Run combined load that should trigger burn rate alerts
    local duration=300  # 5 minutes
    
    print_status "Starting combined chaos test for $duration seconds..."
    
    # Scale down slightly to cause some availability issues
    local original_replicas=$(kubectl get deployment sre-demo-app -o jsonpath='{.spec.replicas}')
    kubectl scale deployment sre-demo-app --replicas=1
    
    # Create heavy load with errors
    cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: slo-chaos-job
spec:
  template:
    spec:
      containers:
      - name: chaos
        image: alpine/curl
        command:
        - /bin/sh
        - -c
        - |
          echo "Starting SLO burn rate test..."
          for i in \$(seq 1 $duration); do
            # Heavy load to cause latency and some errors
            for j in \$(seq 1 30); do
              curl -s http://sre-demo-service/stores > /dev/null &
              if [ \$((j % 5)) -eq 0 ]; then
                curl -s http://sre-demo-service/nonexistent > /dev/null &
              fi
            done
            sleep 1
          done
          echo "SLO burn rate test completed"
      restartPolicy: Never
  backoffLimit: 1
EOF

    # Monitor for SLO burn rate alerts
    local end_time=$((SECONDS + duration))
    local alert_triggered=false
    
    print_status "Monitoring for SLO burn rate alerts..."
    while [ $SECONDS -lt $end_time ]; do
        # Check for SLO burn rate alerts
        local burn_alerts=$(curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=ALERTS{alertname=~\".*SLO.*\",alertstate=\"firing\"}" | jq -r '.data.result | length')
        
        if [ "$burn_alerts" -gt 0 ]; then
            if [ "$alert_triggered" = false ]; then
                print_success "✅ SLO burn rate alert triggered!"
                alert_triggered=true
            fi
        fi
        
        local remaining=$((end_time - SECONDS))
        print_status "SLO burn alerts: $burn_alerts, waiting... ${remaining}s remaining"
        sleep 20
    done
    
    # Clean up
    print_status "Cleaning up SLO test..."
    kubectl delete job slo-chaos-job --ignore-not-found=true
    kubectl scale deployment sre-demo-app --replicas=$original_replicas
    kubectl wait --for=condition=available --timeout=120s deployment/sre-demo-app
    
    if [ "$alert_triggered" = true ]; then
        print_success "✅ SLO burn rate alerting test PASSED"
    else
        print_warning "⚠️  SLO burn rate alerting test INCONCLUSIVE"
    fi
}

# Generate comprehensive test report
generate_test_report() {
    print_status "Generating alert test report..."
    
    local report_file="alert-test-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "Alert Testing Report"
        echo "==================="
        echo "Generated: $(date)"
        echo "Cluster: $(kubectl config current-context)"
        echo ""
        
        echo "Service Endpoints:"
        echo "- SRE Demo App: http://$EXTERNAL_IP"
        echo "- Prometheus: http://$PROMETHEUS_IP:9090"
        echo "- Alertmanager: http://$ALERTMANAGER_IP:9093"
        echo ""
        
        echo "Alert Rules Status:"
        kubectl get configmap prometheus-alerts -o yaml | grep -A5 -B5 "alert:" || echo "Alert rules not found"
        echo ""
        
        echo "Current Active Alerts:"
        curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=ALERTS{alertstate=\"firing\"}" | \
            jq -r '.data.result[] | "- \(.metric.alertname) (\(.metric.severity)): \(.metric.summary // "No summary")"' || echo "No active alerts"
        echo ""
        
        echo "Recommendations:"
        echo "- Review alert thresholds if tests failed"
        echo "- Verify notification channels are configured"
        echo "- Test escalation procedures manually"
        echo "- Update playbooks based on test results"
        
    } | tee $report_file
    
    print_success "Test report saved to: $report_file"
}

# Main execution
main() {
    local test_type=${1:-"all"}
    
    print_status "Starting alert testing: $test_type"
    
    # Initialize
    if ! get_service_ips; then
        exit 1
    fi
    
    # Show initial status
    check_alert_status
    echo ""
    
    case $test_type in
        "availability")
            test_availability_alerts ${2:-180}
            ;;
        "latency") 
            test_latency_alerts ${2:-300}
            ;;
        "error-rate")
            test_error_rate_alerts ${2:-240}
            ;;
        "slo")
            test_slo_burn_rate_alerts
            ;;
        "all")
            print_status "Running comprehensive alert testing..."
            test_availability_alerts 180
            sleep 30  # Cool down period
            test_latency_alerts 200  
            sleep 30  # Cool down period
            test_error_rate_alerts 180
            sleep 30  # Cool down period
            test_slo_burn_rate_alerts
            ;;
        "status")
            check_alert_status
            ;;
        "report")
            generate_test_report
            ;;
        "help")
            echo "Usage: $0 [test_type] [duration]"
            echo ""
            echo "Test Types:"
            echo "  availability  Test availability alerts by scaling to 0"
            echo "  latency       Test latency alerts with load injection"
            echo "  error-rate    Test error rate alerts with bad requests"
            echo "  slo           Test SLO burn rate alerts"
            echo "  all           Run all tests sequentially (default)"
            echo "  status        Show current alert status"
            echo "  report        Generate comprehensive test report"
            echo "  help          Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 availability 300    # Test availability alerts for 5 minutes"
            echo "  $0 latency            # Test latency alerts with default duration"
            echo "  $0 status             # Check current alerts"
            ;;
        *)
            print_error "Unknown test type: $test_type"
            print_status "Use '$0 help' for usage information"
            return 1
            ;;
    esac
    
    echo ""
    print_status "Alert testing completed!"
    print_status "Check these URLs for results:"
    echo "  Prometheus Alerts: http://$PROMETHEUS_IP:9090/alerts"
    if [ -n "$ALERTMANAGER_IP" ] && [ "$ALERTMANAGER_IP" != "null" ]; then
        echo "  Alertmanager: http://$ALERTMANAGER_IP:9093"
    fi
    echo "  Google Cloud Monitoring: https://console.cloud.google.com/monitoring/alerting?project=$(gcloud config get-value project 2>/dev/null)"
}

# Run main function with arguments
main "$@"