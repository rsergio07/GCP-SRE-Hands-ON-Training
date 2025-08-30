#!/bin/bash

# Exercise 6 Rollback Automation Script
# This script implements automated rollback based on SLO violations and alert conditions

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

# Rollback thresholds - more aggressive than validation thresholds
ROLLBACK_AVAILABILITY_THRESHOLD=95.0   # 95% minimum for rollback trigger
ROLLBACK_ERROR_RATE_THRESHOLD=10.0     # 10% maximum error rate
ROLLBACK_LATENCY_THRESHOLD=2.0         # 2 seconds P95 maximum
ROLLBACK_CHECK_INTERVAL=30             # Check every 30 seconds

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

# Check if rollback is needed based on SLO violations
check_rollback_conditions() {
    local check_window=${1:-"5m"}
    local violations=0
    
    print_status "Checking rollback conditions over $check_window..."
    
    # Check availability
    local availability_query="(sum(rate(http_requests_total{status_code!~\"5..\"}[$check_window])) / sum(rate(http_requests_total[$check_window]))) * 100"
    local availability=$(curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=$availability_query" | jq -r '.data.result[0].value[1] // "100"' 2>/dev/null)
    
    if (( $(echo "$availability < $ROLLBACK_AVAILABILITY_THRESHOLD" | bc -l) )); then
        print_error "🚨 Availability below rollback threshold: ${availability}% < ${ROLLBACK_AVAILABILITY_THRESHOLD}%"
        ((violations++))
    else
        print_success "✅ Availability OK: ${availability}%"
    fi
    
    # Check error rate
    local error_rate_query="(sum(rate(http_requests_total{status_code=~\"5..\"}[$check_window])) / sum(rate(http_requests_total[$check_window]))) * 100"
    local error_rate=$(curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=$error_rate_query" | jq -r '.data.result[0].value[1] // "0"' 2>/dev/null)
    
    if (( $(echo "$error_rate > $ROLLBACK_ERROR_RATE_THRESHOLD" | bc -l) )); then
        print_error "🚨 Error rate above rollback threshold: ${error_rate}% > ${ROLLBACK_ERROR_RATE_THRESHOLD}%"
        ((violations++))
    else
        print_success "✅ Error rate OK: ${error_rate}%"
    fi
    
    # Check latency
    local latency_query="histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[$check_window])) by (le))"
    local latency=$(curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=$latency_query" | jq -r '.data.result[0].value[1] // "0"' 2>/dev/null)
    
    if (( $(echo "$latency > $ROLLBACK_LATENCY_THRESHOLD" | bc -l) )); then
        print_error "🚨 Latency above rollback threshold: ${latency}s > ${ROLLBACK_LATENCY_THRESHOLD}s"
        ((violations++))
    else
        print_success "✅ Latency OK: ${latency}s"
    fi
    
    # Check for active critical alerts
    local critical_alerts=$(curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=ALERTS{alertname=~\"ServiceUnavailable|HighErrorRate|ExtremeLatency\",alertstate=\"firing\"}" | jq -r '.data.result | length' 2>/dev/null)
    
    if [ "$critical_alerts" -gt 0 ]; then
        print_error "🚨 Critical alerts active: $critical_alerts"
        ((violations++))
    else
        print_success "✅ No critical alerts active"
    fi
    
    if [ $violations -gt 0 ]; then
        print_error "Rollback conditions met: $violations violations detected"
        return 1
    else
        print_success "No rollback conditions detected"
        return 0
    fi
}

# Execute rollback using ArgoCD
execute_argocd_rollback() {
    print_status "Executing ArgoCD rollback..."
    
    # Get ArgoCD credentials
    if [ -f ".argocd-config" ]; then
        source .argocd-config
    else
        export ARGOCD_IP=$(kubectl get service argocd-server-loadbalancer -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
        export ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null)
    fi
    
    if [ -z "$ARGOCD_IP" ] || [ -z "$ARGOCD_PASSWORD" ]; then
        print_error "Cannot get ArgoCD credentials for rollback"
        return 1
    fi
    
    # Login to ArgoCD
    export ARGOCD_OPTS="--insecure"
    argocd login $ARGOCD_IP --username admin --password "$ARGOCD_PASSWORD" --insecure
    
    # Get application history
    print_status "Getting application deployment history..."
    argocd app history sre-demo-app | head -10
    
    # Get previous revision
    local previous_revision=$(argocd app history sre-demo-app --output json | jq -r '.[1].revision // .[0].revision')
    
    if [ -z "$previous_revision" ] || [ "$previous_revision" = "null" ]; then
        print_error "Cannot determine previous revision for rollback"
        return 1
    fi
    
    print_status "Rolling back to revision: $previous_revision"
    
    # Execute rollback
    argocd app rollback sre-demo-app $previous_revision
    
    # Wait for rollback to complete
    print_status "Waiting for rollback to complete..."
    argocd app wait sre-demo-app --timeout 300
    
    print_success "ArgoCD rollback completed"
    return 0
}

# Execute manual rollback using kubectl
execute_kubectl_rollback() {
    print_status "Executing kubectl rollback..."
    
    # Get rollback target
    local rollback_revision=$(kubectl rollout history deployment/sre-demo-app --revision=0 | tail -n 2 | head -n 1 | awk '{print $1}')
    
    if [ -z "$rollback_revision" ]; then
        print_error "Cannot determine rollback target"
        return 1
    fi
    
    print_status "Rolling back to revision: $rollback_revision"
    
    # Execute rollback
    kubectl rollout undo deployment/sre-demo-app --to-revision=$rollback_revision
    
    # Wait for rollback to complete
    kubectl rollout status deployment/sre-demo-app --timeout=300s
    
    print_success "kubectl rollback completed"
    return 0
}

# Monitor deployment and trigger rollback if needed
monitor_and_rollback() {
    local monitoring_duration=${1:-300}  # Default 5 minutes
    local rollback_method=${2:-"argocd"}  # argocd or kubectl
    
    print_status "Monitoring deployment for $monitoring_duration seconds..."
    print_status "Rollback method: $rollback_method"
    
    local end_time=$((SECONDS + monitoring_duration))
    local check_count=0
    local violation_count=0
    
    while [ $SECONDS -lt $end_time ]; do
        ((check_count++))
        
        if ! check_rollback_conditions "2m"; then
            ((violation_count++))
            print_warning "SLO violation detected (check $check_count, violation $violation_count)"
            
            # Trigger rollback after 3 consecutive violations
            if [ $violation_count -ge 3 ]; then
                print_error "Multiple SLO violations detected - triggering rollback!"
                
                if [ "$rollback_method" = "argocd" ]; then
                    execute_argocd_rollback
                else
                    execute_kubectl_rollback
                fi
                
                # Validate rollback success
                sleep 60  # Wait for rollback to stabilize
                
                if check_rollback_conditions "2m"; then
                    print_success "Rollback successful - SLOs restored"
                    create_rollback_report "success"
                    return 0
                else
                    print_error "Rollback failed - manual intervention required"
                    create_rollback_report "failed"
                    return 1
                fi
            fi
        else
            print_success "SLO compliance check passed (check $check_count)"
            violation_count=0  # Reset violation count on successful check
        fi
        
        local remaining=$((end_time - SECONDS))
        print_status "Monitoring continues... ${remaining}s remaining"
        sleep $ROLLBACK_CHECK_INTERVAL
    done
    
    print_success "Monitoring completed - no rollback needed"
    create_rollback_report "monitoring_completed"
    return 0
}

# Create rollback report
create_rollback_report() {
    local status=$1
    local report_file="rollback-report-$(date +%Y%m%d-%H%M%S).json"
    
    print_status "Creating rollback report..."
    
    cat > $report_file << EOF
{
  "rollback_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "rollback_status": "$status",
  "deployment_info": {
    "current_image": "$(kubectl get deployment sre-demo-app -o jsonpath='{.spec.template.spec.containers[0].image}')",
    "current_replicas": $(kubectl get deployment sre-demo-app -o jsonpath='{.spec.replicas}'),
    "ready_replicas": $(kubectl get deployment sre-demo-app -o jsonpath='{.status.readyReplicas}'),
    "revision": "$(kubectl get deployment sre-demo-app -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}')"
  },
  "current_slo_metrics": {
    "availability": "$(curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=(sum(rate(http_requests_total{status_code!~\"5..\"}[5m])) / sum(rate(http_requests_total[5m]))) * 100" | jq -r '.data.result[0].value[1] // "0"' 2>/dev/null)",
    "error_rate": "$(curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=(sum(rate(http_requests_total{status_code=~\"5..\"}[5m])) / sum(rate(http_requests_total[5m]))) * 100" | jq -r '.data.result[0].value[1] // "0"' 2>/dev/null)",
    "latency_p95": "$(curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))" | jq -r '.data.result[0].value[1] // "0"' 2>/dev/null)"
  }
}
EOF

    print_success "Rollback report created: $report_file"
    
    # Send notification (placeholder for actual notification system)
    print_status "Rollback notification would be sent to:"
    echo "  • SRE Team Slack: #sre-alerts"
    echo "  • Email: sre-team@company.com"
    echo "  • PagerDuty: High priority incident"
}

# Test rollback procedures
test_rollback() {
    print_status "Testing rollback procedures..."
    
    if ! get_endpoints; then
        exit 1
    fi
    
    # Get current deployment state
    local current_image=$(kubectl get deployment sre-demo-app -o jsonpath='{.spec.template.spec.containers[0].image}')
    local current_revision=$(kubectl get deployment sre-demo-app -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}')
    
    print_status "Current deployment:"
    echo "  Image: $current_image"
    echo "  Revision: $current_revision"
    
    # Create a test deployment that will trigger rollback conditions
    print_status "Creating test deployment with intentional issues..."
    
    # Patch deployment to use excessive resource limits (will cause issues)
    kubectl patch deployment sre-demo-app -p '{
      "spec": {
        "template": {
          "spec": {
            "containers": [{
              "name": "sre-demo-app",
              "env": [
                {"name": "FLASK_ENV", "value": "production"},
                {"name": "LOG_FORMAT", "value": "json"},
                {"name": "LOG_LEVEL", "value": "INFO"},
                {"name": "SIMULATE_FAILURES", "value": "true"},
                {"name": "FAILURE_RATE", "value": "0.15"}
              ]
            }]
          }
        }
      }
    }'
    
    # Wait for deployment
    kubectl rollout status deployment/sre-demo-app --timeout=120s
    
    print_status "Test deployment active - monitoring for rollback conditions..."
    
    # Generate some load to trigger metrics
    print_status "Generating load to trigger rollback conditions..."
    for i in {1..50}; do
        curl -s http://$EXTERNAL_IP/stores > /dev/null &
        curl -s http://$EXTERNAL_IP/ > /dev/null &
    done
    wait
    
    # Wait for metrics to update
    sleep 60
    
    # Check rollback conditions
    if check_rollback_conditions "2m"; then
        print_warning "Test did not trigger rollback conditions - manual rollback for demonstration"
        execute_kubectl_rollback
    else
        print_status "Rollback conditions detected - executing rollback"
        execute_kubectl_rollback
    fi
    
    print_success "Rollback test completed"
}

# Continuous monitoring for rollback automation
continuous_monitoring() {
    local monitoring_duration=${1:-1800}  # Default 30 minutes
    
    print_status "Starting continuous rollback monitoring for $monitoring_duration seconds..."
    
    if ! get_endpoints; then
        exit 1
    fi
    
    local end_time=$((SECONDS + monitoring_duration))
    local check_count=0
    local consecutive_violations=0
    
    while [ $SECONDS -lt $end_time ]; do
        ((check_count++))
        
        print_status "Rollback check $check_count..."
        
        if ! check_rollback_conditions "3m"; then
            ((consecutive_violations++))
            print_warning "SLO violation $consecutive_violations detected"
            
            # Trigger rollback after 2 consecutive violations
            if [ $consecutive_violations -ge 2 ]; then
                print_error "Consecutive SLO violations - triggering automated rollback!"
                
                if execute_argocd_rollback; then
                    # Wait for rollback to stabilize
                    sleep 120
                    
                    # Verify rollback restored SLOs
                    if check_rollback_conditions "3m"; then
                        print_success "Automated rollback successful - monitoring continues"
                        consecutive_violations=0
                    else
                        print_error "Rollback failed to restore SLOs - manual intervention required"
                        create_rollback_report "failed"
                        exit 1
                    fi
                else
                    print_error "Rollback execution failed - manual intervention required"
                    create_rollback_report "execution_failed"
                    exit 1
                fi
            fi
        else
            print_success "SLO compliance OK"
            consecutive_violations=0
        fi
        
        local remaining=$((end_time - SECONDS))
        print_status "Next check in ${ROLLBACK_CHECK_INTERVAL}s (${remaining}s total remaining)"
        sleep $ROLLBACK_CHECK_INTERVAL
    done
    
    print_success "Continuous monitoring completed - no rollbacks needed"
    create_rollback_report "monitoring_completed"
}

# Display rollback status
show_rollback_status() {
    print_status "Rollback system status:"
    
    # Check ArgoCD availability
    local argocd_ip=$(kubectl get service argocd-server-loadbalancer -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    if [ -n "$argocd_ip" ] && [ "$argocd_ip" != "null" ]; then
        print_success "ArgoCD available at: https://$argocd_ip"
    else
        print_warning "ArgoCD not accessible via LoadBalancer"
    fi
    
    # Check current deployment status
    local current_image=$(kubectl get deployment sre-demo-app -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
    local ready_replicas=$(kubectl get deployment sre-demo-app -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
    local total_replicas=$(kubectl get deployment sre-demo-app -o jsonpath='{.spec.replicas}' 2>/dev/null)
    
    if [ -n "$current_image" ]; then
        print_status "Current deployment:"
        echo "  Image: $current_image"
        echo "  Replicas: $ready_replicas/$total_replicas"
    else
        print_warning "SRE demo app deployment not found"
    fi
    
    # Check rollout history
    print_status "Recent deployment history:"
    kubectl rollout history deployment/sre-demo-app 2>/dev/null | tail -5 || echo "No deployment history available"
    
    # Check monitoring endpoints
    if get_endpoints; then
        print_success "Monitoring endpoints accessible"
        check_rollback_conditions "5m" || print_warning "Current SLO violations detected"
    else
        print_warning "Monitoring endpoints not accessible"
    fi
}

# Main execution
main() {
    local operation=${1:-"monitor"}
    local duration=${2:-300}
    
    case $operation in
        "monitor")
            monitor_and_rollback $duration "argocd"
            ;;
        "continuous")
            continuous_monitoring $duration
            ;;
        "test")
            test_rollback
            ;;
        "check")
            if get_endpoints; then
                check_rollback_conditions "5m"
            else
                exit 1
            fi
            ;;
        "rollback")
            if get_endpoints; then
                execute_argocd_rollback
            else
                exit 1
            fi
            ;;
        "status")
            show_rollback_status
            ;;
        "help")
            echo "Usage: $0 [operation] [duration]"
            echo ""
            echo "Operations:"
            echo "  monitor      Monitor deployment and rollback if needed (default)"
            echo "  continuous   Run continuous monitoring for extended period"
            echo "  test         Test rollback procedures with simulated issues"
            echo "  check        Check current rollback conditions"
            echo "  rollback     Execute immediate rollback"
            echo "  status       Show rollback system status"
            echo "  help         Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 monitor 600     # Monitor for 10 minutes with auto-rollback"
            echo "  $0 test            # Test rollback procedures"
            echo "  $0 check           # Check current SLO compliance"
            echo "  $0 rollback        # Execute immediate rollback"
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