#!/bin/bash

# Exercise 7 Production Tests Script
# Comprehensive testing for production readiness validation

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

# Get service endpoints
get_endpoints() {
    export EXTERNAL_IP=$(kubectl get service sre-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    export PROMETHEUS_IP=$(kubectl get service prometheus-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    
    if [[ -z "$EXTERNAL_IP" || "$EXTERNAL_IP" == "null" ]]; then
        print_error "SRE demo app external IP not available"
        return 1
    fi
    
    print_status "Using endpoints:"
    echo "  • Application: $EXTERNAL_IP"
    echo "  • Prometheus: ${PROMETHEUS_IP:-not available}"
    return 0
}

# Test security hardening
test_security() {
    print_status "Testing security hardening..."
    
    local tests_passed=0
    local tests_failed=0
    
    # Test 1: Network policies
    if kubectl get networkpolicy sre-demo-network-policy &>/dev/null; then
        print_success "✓ Network policies configured"
        ((tests_passed++))
    else
        print_error "✗ Network policies missing"
        ((tests_failed++))
    fi
    
    # Test 2: Pod security context
    local run_as_user=$(kubectl get deployment sre-demo-app -o jsonpath='{.spec.template.spec.securityContext.runAsUser}')
    if [[ "$run_as_user" == "1001" ]]; then
        print_success "✓ Non-root security context configured"
        ((tests_passed++))
    else
        print_error "✗ Security context not properly configured"
        ((tests_failed++))
    fi
    
    # Test 3: Resource limits
    local cpu_limits=$(kubectl get deployment sre-demo-app -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}')
    if [[ -n "$cpu_limits" ]]; then
        print_success "✓ Resource limits configured: CPU=$cpu_limits"
        ((tests_passed++))
    else
        print_error "✗ Resource limits not configured"
        ((tests_failed++))
    fi
    
    # Test 4: Security headers
    if [[ -n "$EXTERNAL_IP" ]]; then
        local security_headers=$(curl -s -I http://$EXTERNAL_IP/ | grep -E "(X-Frame-Options|X-Content-Type-Options)" | wc -l)
        if [[ "$security_headers" -gt 0 ]]; then
            print_success "✓ Security headers present"
            ((tests_passed++))
        else
            print_error "✗ Security headers missing"
            ((tests_failed++))
        fi
    fi
    
    print_status "Security tests: $tests_passed passed, $tests_failed failed"
    return $tests_failed
}

# Test cost optimization
test_cost_optimization() {
    print_status "Testing cost optimization..."
    
    local tests_passed=0
    local tests_failed=0
    
    # Test 1: HPA configuration
    if kubectl get hpa sre-demo-hpa-optimized &>/dev/null; then
        local min_replicas=$(kubectl get hpa sre-demo-hpa-optimized -o jsonpath='{.spec.minReplicas}')
        local max_replicas=$(kubectl get hpa sre-demo-hpa-optimized -o jsonpath='{.spec.maxReplicas}')
        print_success "✓ HPA configured: $min_replicas-$max_replicas replicas"
        ((tests_passed++))
    else
        print_error "✗ HPA not configured"
        ((tests_failed++))
    fi
    
    # Test 2: Resource requests
    local cpu_request=$(kubectl get deployment sre-demo-app -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')
    local memory_request=$(kubectl get deployment sre-demo-app -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}')
    if [[ -n "$cpu_request" && -n "$memory_request" ]]; then
        print_success "✓ Resource requests configured: CPU=$cpu_request, Memory=$memory_request"
        ((tests_passed++))
    else
        print_error "✗ Resource requests not properly configured"
        ((tests_failed++))
    fi
    
    # Test 3: VPA (if available)
    if kubectl get vpa sre-demo-vpa &>/dev/null; then
        print_success "✓ VPA configured for automatic right-sizing"
        ((tests_passed++))
    else
        print_warning "⚠ VPA not available (acceptable for some environments)"
    fi
    
    # Test 4: Resource utilization
    if command -v kubectl top &>/dev/null; then
        local cpu_usage=$(kubectl top pod -l app=sre-demo-app --no-headers 2>/dev/null | awk '{sum += $2} END {print sum}' || echo "0m")
        if [[ -n "$cpu_usage" ]]; then
            print_success "✓ Resource monitoring working: CPU usage=$cpu_usage"
            ((tests_passed++))
        else
            print_warning "⚠ Resource metrics not available yet"
        fi
    fi
    
    print_status "Cost optimization tests: $tests_passed passed, $tests_failed failed"
    return $tests_failed
}

# Test disaster recovery capabilities
test_disaster_recovery() {
    print_status "Testing disaster recovery capabilities..."
    
    local tests_passed=0
    local tests_failed=0
    
    # Test 1: Backup job configuration
    if kubectl get cronjob database-backup &>/dev/null; then
        local schedule=$(kubectl get cronjob database-backup -o jsonpath='{.spec.schedule}')
        print_success "✓ Backup job configured: $schedule"
        ((tests_passed++))
    else
        print_warning "⚠ Backup job not found (may be external)"
    fi
    
    # Test 2: Pod disruption budget
    if kubectl get pdb sre-demo-pdb-cost-optimized &>/dev/null; then
        local max_unavailable=$(kubectl get pdb sre-demo-pdb-cost-optimized -o jsonpath='{.spec.maxUnavailable}')
        print_success "✓ Pod disruption budget configured: max unavailable=$max_unavailable"
        ((tests_passed++))
    else
        print_error "✗ Pod disruption budget not configured"
        ((tests_failed++))
    fi
    
    # Test 3: Multi-replica deployment
    local current_replicas=$(kubectl get deployment sre-demo-app -o jsonpath='{.status.readyReplicas}')
    local desired_replicas=$(kubectl get deployment sre-demo-app -o jsonpath='{.spec.replicas}')
    if [[ "$current_replicas" -ge 2 && "$current_replicas" == "$desired_replicas" ]]; then
        print_success "✓ Multi-replica deployment: $current_replicas replicas"
        ((tests_passed++))
    else
        print_error "✗ Insufficient replicas for HA: $current_replicas/$desired_replicas"
        ((tests_failed++))
    fi
    
    # Test 4: Storage backup configuration
    local project_id=$(gcloud config get-value project 2>/dev/null)
    local bucket_name="sre-demo-backup-production-$project_id"
    if gsutil ls gs://$bucket_name &>/dev/null; then
        print_success "✓ Backup storage configured: $bucket_name"
        ((tests_passed++))
    else
        print_warning "⚠ Backup storage not found"
    fi
    
    print_status "Disaster recovery tests: $tests_passed passed, $tests_failed failed"
    return $tests_failed
}

# Test performance under load
test_performance() {
    local duration=${1:-60}
    local concurrency=${2:-10}
    
    print_status "Testing performance with load (${duration}s, ${concurrency} concurrent)..."
    
    if [[ -z "$EXTERNAL_IP" ]]; then
        print_error "External IP not available for performance testing"
        return 1
    fi
    
    local tests_passed=0
    local tests_failed=0
    
    # Generate load and collect metrics
    print_status "Generating load for $duration seconds..."
    
    local start_time=$(date +%s)
    local end_time=$((start_time + duration))
    local request_count=0
    local success_count=0
    local total_response_time=0
    
    # Background load generation
    for ((i=1; i<=concurrency; i++)); do
        {
            while [[ $(date +%s) -lt $end_time ]]; do
                local response_time=$(curl -o /dev/null -s -w "%{time_total}" http://$EXTERNAL_IP/ 2>/dev/null || echo "0")
                if [[ "$?" -eq 0 ]]; then
                    ((success_count++))
                    total_response_time=$(echo "$total_response_time + $response_time" | bc -l)
                fi
                ((request_count++))
                sleep 0.1
            done
        } &
    done
    
    # Wait for load test completion
    wait
    
    # Calculate metrics
    local success_rate=0
    local avg_response_time=0
    if [[ $request_count -gt 0 ]]; then
        success_rate=$(echo "scale=2; $success_count * 100 / $request_count" | bc -l)
    fi
    if [[ $success_count -gt 0 ]]; then
        avg_response_time=$(echo "scale=3; $total_response_time / $success_count" | bc -l)
    fi
    
    print_status "Performance results:"
    echo "  • Total requests: $request_count"
    echo "  • Successful requests: $success_count"
    echo "  • Success rate: ${success_rate}%"
    echo "  • Average response time: ${avg_response_time}s"
    
    # Validate performance
    if (( $(echo "$success_rate >= 95" | bc -l) )); then
        print_success "✓ Success rate acceptable: ${success_rate}%"
        ((tests_passed++))
    else
        print_error "✗ Success rate too low: ${success_rate}%"
        ((tests_failed++))
    fi
    
    if (( $(echo "$avg_response_time <= 1.0" | bc -l) )); then
        print_success "✓ Response time acceptable: ${avg_response_time}s"
        ((tests_passed++))
    else
        print_error "✗ Response time too high: ${avg_response_time}s"
        ((tests_failed++))
    fi
    
    print_status "Performance tests: $tests_passed passed, $tests_failed failed"
    return $tests_failed
}

# Test backup and restore procedures
test_backup_validation() {
    print_status "Testing backup validation..."
    
    local tests_passed=0
    local tests_failed=0
    
    # Test backup storage accessibility
    local project_id=$(gcloud config get-value project 2>/dev/null)
    local bucket_name="sre-demo-backup-production-$project_id"
    
    if gsutil ls gs://$bucket_name &>/dev/null; then
        print_success "✓ Backup storage accessible"
        ((tests_passed++))
        
        # Test backup creation
        local test_file="test-backup-$(date +%s).txt"
        echo "Test backup validation" > /tmp/$test_file
        
        if gsutil cp /tmp/$test_file gs://$bucket_name/test/ &>/dev/null; then
            print_success "✓ Backup write operation successful"
            ((tests_passed++))
            
            # Test backup retrieval
            if gsutil cp gs://$bucket_name/test/$test_file /tmp/restored-$test_file &>/dev/null; then
                print_success "✓ Backup read operation successful"
                ((tests_passed++))
                
                # Cleanup test files
                rm -f /tmp/$test_file /tmp/restored-$test_file
                gsutil rm gs://$bucket_name/test/$test_file &>/dev/null || true
            else
                print_error "✗ Backup read operation failed"
                ((tests_failed++))
            fi
        else
            print_error "✗ Backup write operation failed"
            ((tests_failed++))
        fi
    else
        print_error "✗ Backup storage not accessible"
        ((tests_failed++))
    fi
    
    # Test database backup job
    if kubectl get cronjob database-backup &>/dev/null; then
        local last_schedule=$(kubectl get cronjob database-backup -o jsonpath='{.status.lastScheduleTime}')
        if [[ -n "$last_schedule" ]]; then
            print_success "✓ Database backup job active (last: $last_schedule)"
            ((tests_passed++))
        else
            print_warning "⚠ Database backup job not yet executed"
        fi
    else
        print_warning "⚠ Database backup job not found"
    fi
    
    print_status "Backup validation tests: $tests_passed passed, $tests_failed failed"
    return $tests_failed
}

# Test compliance and governance
test_compliance() {
    print_status "Testing compliance and governance..."
    
    local tests_passed=0
    local tests_failed=0
    
    # Test audit logging
    if kubectl get events --field-selector type=Warning | head -1 &>/dev/null; then
        print_success "✓ Audit logging functional"
        ((tests_passed++))
    else
        print_warning "⚠ Audit logging status unclear"
    fi
    
    # Test resource quotas
    if kubectl get quota sre-demo-quota &>/dev/null; then
        local cpu_used=$(kubectl get quota sre-demo-quota -o jsonpath='{.status.used.requests\.cpu}')
        local cpu_hard=$(kubectl get quota sre-demo-quota -o jsonpath='{.status.hard.requests\.cpu}')
        print_success "✓ Resource quota enforced: CPU $cpu_used/$cpu_hard"
        ((tests_passed++))
    else
        print_error "✗ Resource quota not configured"
        ((tests_failed++))
    fi
    
    # Test service account configuration
    local sa_name=$(kubectl get deployment sre-demo-app -o jsonpath='{.spec.template.spec.serviceAccountName}')
    if [[ "$sa_name" == "sre-demo-serviceaccount" ]]; then
        print_success "✓ Dedicated service account configured"
        ((tests_passed++))
    else
        print_error "✗ Service account not properly configured"
        ((tests_failed++))
    fi
    
    # Test RBAC
    if kubectl get role sre-demo-role &>/dev/null; then
        print_success "✓ RBAC role configured"
        ((tests_passed++))
    else
        print_error "✗ RBAC role not found"
        ((tests_failed++))
    fi
    
    print_status "Compliance tests: $tests_passed passed, $tests_failed failed"
    return $tests_failed
}

# Test monitoring coverage
test_monitoring_coverage() {
    print_status "Testing monitoring coverage..."
    
    local tests_passed=0
    local tests_failed=0
    
    # Test Prometheus metrics
    if [[ -n "$PROMETHEUS_IP" ]]; then
        local app_metrics=$(curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=up{job=\"sre-demo-app\"}" | jq -r '.data.result | length' 2>/dev/null)
        if [[ "$app_metrics" -gt 0 ]]; then
            print_success "✓ Application metrics available in Prometheus"
            ((tests_passed++))
        else
            print_error "✗ Application metrics not found in Prometheus"
            ((tests_failed++))
        fi
    else
        print_warning "⚠ Prometheus not accessible for testing"
    fi
    
    # Test application metrics endpoint
    if [[ -n "$EXTERNAL_IP" ]]; then
        local metrics_response=$(curl -s http://$EXTERNAL_IP/metrics | head -1)
        if [[ -n "$metrics_response" ]]; then
            print_success "✓ Application metrics endpoint responding"
            ((tests_passed++))
        else
            print_error "✗ Application metrics endpoint not responding"
            ((tests_failed++))
        fi
    fi
    
    # Test production info endpoint
    if [[ -n "$EXTERNAL_IP" ]]; then
        local prod_info=$(curl -s http://$EXTERNAL_IP/production-info | jq -r '.security.hardened' 2>/dev/null)
        if [[ "$prod_info" == "true" ]]; then
            print_success "✓ Production info endpoint validates security hardening"
            ((tests_passed++))
        else
            print_error "✗ Production info endpoint not properly configured"
            ((tests_failed++))
        fi
    fi
    
    print_status "Monitoring coverage tests: $tests_passed passed, $tests_failed failed"
    return $tests_failed
}

# Run comprehensive production test suite
run_comprehensive_tests() {
    print_status "Running comprehensive production test suite..."
    
    local total_failures=0
    
    if ! get_endpoints; then
        print_error "Cannot get service endpoints for testing"
        exit 1
    fi
    
    # Run all test categories
    test_security || ((total_failures++))
    echo ""
    
    test_cost_optimization || ((total_failures++))
    echo ""
    
    test_disaster_recovery || ((total_failures++))
    echo ""
    
    test_performance 60 5 || ((total_failures++))
    echo ""
    
    test_backup_validation || ((total_failures++))
    echo ""
    
    test_compliance || ((total_failures++))
    echo ""
    
    test_monitoring_coverage || ((total_failures++))
    echo ""
    
    # Generate summary report
    if [[ $total_failures -eq 0 ]]; then
        print_success "🎉 ALL PRODUCTION TESTS PASSED!"
        print_status "Your SRE platform is production-ready"
    else
        print_error "❌ $total_failures test categories failed"
        print_status "Review failures and remediate before production deployment"
    fi
    
    return $total_failures
}

# Generate test report
generate_test_report() {
    local report_file="production-test-report-$(date +%Y%m%d-%H%M%S).json"
    
    print_status "Generating production test report..."
    
    cat > $report_file << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "cluster": "$(kubectl config current-context)",
  "external_ip": "${EXTERNAL_IP:-null}",
  "test_results": {
    "security_hardening": "$(test_security &>/dev/null && echo "PASS" || echo "FAIL")",
    "cost_optimization": "$(test_cost_optimization &>/dev/null && echo "PASS" || echo "FAIL")",
    "disaster_recovery": "$(test_disaster_recovery &>/dev/null && echo "PASS" || echo "FAIL")",
    "performance": "$(test_performance 30 3 &>/dev/null && echo "PASS" || echo "FAIL")",
    "backup_validation": "$(test_backup_validation &>/dev/null && echo "PASS" || echo "FAIL")",
    "compliance": "$(test_compliance &>/dev/null && echo "PASS" || echo "FAIL")",
    "monitoring_coverage": "$(test_monitoring_coverage &>/dev/null && echo "PASS" || echo "FAIL")"
  },
  "deployment_info": {
    "replicas": $(kubectl get deployment sre-demo-app -o jsonpath='{.spec.replicas}' 2>/dev/null || echo 0),
    "ready_replicas": $(kubectl get deployment sre-demo-app -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0),
    "image": "$(kubectl get deployment sre-demo-app -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)"
  }
}
EOF

    print_success "Test report generated: $report_file"
    cat $report_file | jq .
}

# Main execution
main() {
    local test_type=${1:-"comprehensive"}
    
    case $test_type in
        "security")
            get_endpoints && test_security
            ;;
        "cost")
            test_cost_optimization
            ;;
        "disaster-recovery")
            test_disaster_recovery
            ;;
        "performance")
            get_endpoints && test_performance ${2:-60} ${3:-5}
            ;;
        "backup-validation")
            test_backup_validation
            ;;
        "compliance")
            test_compliance
            ;;
        "monitoring")
            get_endpoints && test_monitoring_coverage
            ;;
        "comprehensive")
            run_comprehensive_tests
            ;;
        "report")
            get_endpoints 2>/dev/null || true
            generate_test_report
            ;;
        "help")
            echo "Usage: $0 [test_type] [options]"
            echo ""
            echo "Test Types:"
            echo "  security           Test security hardening"
            echo "  cost              Test cost optimization"
            echo "  disaster-recovery Test DR capabilities"
            echo "  performance       Test performance [duration] [concurrency]"
            echo "  backup-validation Test backup procedures"
            echo "  compliance        Test compliance and governance"
            echo "  monitoring        Test monitoring coverage"
            echo "  comprehensive     Run all tests (default)"
            echo "  report           Generate test report"
            echo "  help             Show this help"
            echo ""
            echo "Examples:"
            echo "  $0                           # Run all tests"
            echo "  $0 security                  # Security tests only"
            echo "  $0 performance 120 10       # 2min load test, 10 concurrent"
            echo "  $0 report                    # Generate JSON report"
            ;;
        *)
            print_error "Unknown test type: $test_type"
            print_status "Use '$0 help' for usage information"
            return 1
            ;;
    esac
}

# Run main function
main "$@"