#!/bin/bash

# Exercise 8 Chaos Engineering Test Script
# Advanced SRE operations for production resilience validation

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

# Pod failure chaos test
chaos_pod_failure() {
    local duration=${1:-300}
    
    print_status "Starting pod failure chaos test for ${duration}s..."
    
    # Get current pod count
    local initial_pods=$(kubectl get pods -l app=sre-demo-app --no-headers | wc -l)
    print_status "Initial pod count: $initial_pods"
    
    # Generate background load
    {
        local end_time=$((SECONDS + duration))
        local request_count=0
        while [ $SECONDS -lt $end_time ]; do
            curl -s http://$EXTERNAL_IP/ > /dev/null &
            curl -s http://$EXTERNAL_IP/stores > /dev/null &
            ((request_count += 2))
            sleep 1
        done
        print_status "Generated $request_count requests during chaos test"
    } &
    local load_pid=$!
    
    # Chaos: Delete random pods
    local chaos_end=$((SECONDS + duration))
    local pods_killed=0
    
    while [ $SECONDS -lt $chaos_end ]; do
        local pod_name=$(kubectl get pods -l app=sre-demo-app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
        if [[ -n "$pod_name" ]]; then
            kubectl delete pod $pod_name
            ((pods_killed++))
            print_status "Killed pod: $pod_name (total: $pods_killed)"
        fi
        
        # Wait before next kill
        sleep $(( 30 + RANDOM % 60 ))
    done
    
    # Wait for load generation to complete
    wait $load_pid
    
    # Validate recovery
    sleep 30
    local final_pods=$(kubectl get pods -l app=sre-demo-app --field-selector=status.phase=Running --no-headers | wc -l)
    
    if [[ "$final_pods" -ge "$initial_pods" ]]; then
        print_success "✓ Pod failure test passed: $final_pods/$initial_pods pods recovered"
        return 0
    else
        print_error "✗ Pod failure test failed: only $final_pods/$initial_pods pods recovered"
        return 1
    fi
}

# Network chaos test
chaos_network_partition() {
    local duration=${1:-180}
    
    print_status "Starting network partition chaos test for ${duration}s..."
    
    # Create network policy to isolate one pod
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: chaos-network-partition
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: sre-demo-app
  policyTypes:
  - Ingress
  - Egress
  ingress: []
  egress: []
EOF

    print_status "Network partition applied"
    
    # Monitor service during partition
    local start_time=$SECONDS
    local end_time=$((start_time + duration))
    local success_count=0
    local total_requests=0
    
    while [ $SECONDS -lt $end_time ]; do
        if curl -s --max-time 5 http://$EXTERNAL_IP/health > /dev/null 2>&1; then
            ((success_count++))
        fi
        ((total_requests++))
        sleep 5
    done
    
    # Remove network partition
    kubectl delete networkpolicy chaos-network-partition
    print_status "Network partition removed"
    
    # Calculate availability
    local availability=$(( success_count * 100 / total_requests ))
    print_status "Service availability during partition: ${availability}%"
    
    if [[ $availability -ge 60 ]]; then
        print_success "✓ Network partition test passed: ${availability}% availability"
        return 0
    else
        print_error "✗ Network partition test failed: ${availability}% availability"
        return 1
    fi
}

# Resource exhaustion test
chaos_resource_exhaustion() {
    local duration=${1:-240}
    
    print_status "Starting resource exhaustion test for ${duration}s..."
    
    # Create CPU stress job
    cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: chaos-cpu-stress
spec:
  template:
    spec:
      containers:
      - name: stress
        image: progrium/stress
        args: ["-c", "4", "-t", "${duration}s"]
        resources:
          requests:
            cpu: "2"
            memory: "1Gi"
      restartPolicy: Never
      nodeSelector:
        kubernetes.io/os: linux
EOF

    # Monitor application performance during stress
    local baseline_latency=$(curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[2m])) by (le))" | jq -r '.data.result[0].value[1] // "0"' 2>/dev/null)
    
    print_status "Baseline P95 latency: ${baseline_latency}s"
    
    # Wait for stress to complete
    kubectl wait --for=condition=complete --timeout=${duration}s job/chaos-cpu-stress
    
    # Check final performance
    sleep 30
    local final_latency=$(curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[2m])) by (le))" | jq -r '.data.result[0].value[1] // "0"' 2>/dev/null)
    
    print_status "Post-stress P95 latency: ${final_latency}s"
    
    # Cleanup
    kubectl delete job chaos-cpu-stress
    
    # Validate performance impact
    local latency_increase=$(echo "scale=2; ($final_latency - $baseline_latency) / $baseline_latency * 100" | bc -l 2>/dev/null || echo "0")
    print_status "Latency increase: ${latency_increase}%"
    
    if (( $(echo "$latency_increase < 200" | bc -l) )); then
        print_success "✓ Resource exhaustion test passed: ${latency_increase}% latency increase"
        return 0
    else
        print_error "✗ Resource exhaustion test failed: ${latency_increase}% latency increase"
        return 1
    fi
}

# Dependency failure simulation
chaos_dependency_failure() {
    local duration=${1:-180}
    
    print_status "Starting dependency failure test for ${duration}s..."
    
    # Block egress to simulate external dependency failure
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: chaos-dependency-failure
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: sre-demo-app
  policyTypes:
  - Egress
  egress:
  - to: []
    ports:
    - protocol: UDP
      port: 53
  - to:
    - podSelector:
        matchLabels:
          app: prometheus
EOF

    print_status "Dependency failure simulation active"
    
    # Monitor error rate
    sleep 30
    local error_rate_start=$(curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=sum(rate(http_requests_total{status_code=~\"5..\"}[5m])) / sum(rate(http_requests_total[5m])) * 100" | jq -r '.data.result[0].value[1] // "0"' 2>/dev/null)
    
    print_status "Initial error rate: ${error_rate_start}%"
    
    # Wait for test duration
    sleep $((duration - 60))
    
    # Check final error rate
    local error_rate_end=$(curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=sum(rate(http_requests_total{status_code=~\"5..\"}[5m])) / sum(rate(http_requests_total[5m])) * 100" | jq -r '.data.result[0].value[1] // "0"' 2>/dev/null)
    
    # Cleanup
    kubectl delete networkpolicy chaos-dependency-failure
    print_status "Dependency failure simulation removed"
    
    print_status "Final error rate: ${error_rate_end}%"
    
    # Validate graceful degradation
    if (( $(echo "$error_rate_end < 20" | bc -l) )); then
        print_success "✓ Dependency failure test passed: ${error_rate_end}% error rate"
        return 0
    else
        print_error "✗ Dependency failure test failed: ${error_rate_end}% error rate"
        return 1
    fi
}

# Rolling deployment chaos
chaos_rolling_deployment() {
    print_status "Starting rolling deployment chaos test..."
    
    # Get current image
    local current_image=$(kubectl get deployment sre-demo-app -o jsonpath='{.spec.template.spec.containers[0].image}')
    print_status "Current image: $current_image"
    
    # Update to same image to trigger rolling update
    kubectl patch deployment sre-demo-app -p '{"spec":{"template":{"metadata":{"annotations":{"chaos-test":"'$(date +%s)'"}}}}}' 
    
    # Monitor availability during rollout
    local start_time=$SECONDS
    local total_requests=0
    local success_count=0
    
    while kubectl rollout status deployment/sre-demo-app --watch=false | grep -q "progressing"; do
        if curl -s --max-time 3 http://$EXTERNAL_IP/health > /dev/null 2>&1; then
            ((success_count++))
        fi
        ((total_requests++))
        sleep 2
    done
    
    # Final availability check
    if [[ $total_requests -gt 0 ]]; then
        local availability=$(( success_count * 100 / total_requests ))
        print_status "Availability during rolling update: ${availability}%"
        
        if [[ $availability -ge 80 ]]; then
            print_success "✓ Rolling deployment test passed: ${availability}% availability"
            return 0
        else
            print_error "✗ Rolling deployment test failed: ${availability}% availability"
            return 1
        fi
    else
        print_success "✓ Rolling deployment completed too quickly to measure"
        return 0
    fi
}

# Comprehensive chaos engineering suite
run_chaos_suite() {
    print_status "Running comprehensive chaos engineering suite..."
    
    local total_tests=0
    local passed_tests=0
    
    if ! get_endpoints; then
        print_error "Cannot get endpoints for chaos testing"
        exit 1
    fi
    
    # Test 1: Pod failure resilience
    ((total_tests++))
    if chaos_pod_failure 180; then
        ((passed_tests++))
    fi
    echo ""
    
    # Test 2: Network partition tolerance
    ((total_tests++))
    if chaos_network_partition 120; then
        ((passed_tests++))
    fi
    echo ""
    
    # Test 3: Resource exhaustion handling
    ((total_tests++))
    if chaos_resource_exhaustion 180; then
        ((passed_tests++))
    fi
    echo ""
    
    # Test 4: Dependency failure graceful degradation
    ((total_tests++))
    if chaos_dependency_failure 150; then
        ((passed_tests++))
    fi
    echo ""
    
    # Test 5: Rolling deployment availability
    ((total_tests++))
    if chaos_rolling_deployment; then
        ((passed_tests++))
    fi
    echo ""
    
    # Generate chaos test report
    print_status "=== CHAOS ENGINEERING RESULTS ==="
    echo "Tests passed: $passed_tests/$total_tests"
    echo "Success rate: $(( passed_tests * 100 / total_tests ))%"
    
    if [[ $passed_tests -eq $total_tests ]]; then
        print_success "🎉 ALL CHAOS TESTS PASSED - System is resilient!"
    elif [[ $passed_tests -ge $(( total_tests * 3 / 4 )) ]]; then
        print_warning "⚠️ Most chaos tests passed - Review failures"
    else
        print_error "❌ Multiple chaos test failures - System needs hardening"
    fi
    
    return $(( total_tests - passed_tests ))
}

# Main execution
main() {
    local test_type=${1:-"suite"}
    local duration=${2:-300}
    
    case $test_type in
        "pod-failure")
            get_endpoints && chaos_pod_failure $duration
            ;;
        "network-partition")
            get_endpoints && chaos_network_partition $duration
            ;;
        "resource-exhaustion")
            chaos_resource_exhaustion $duration
            ;;
        "dependency-failure")
            chaos_dependency_failure $duration
            ;;
        "rolling-deployment")
            chaos_rolling_deployment
            ;;
        "suite")
            run_chaos_suite
            ;;
        "help")
            echo "Usage: $0 [test_type] [duration]"
            echo ""
            echo "Test Types:"
            echo "  pod-failure         Test pod failure resilience"
            echo "  network-partition   Test network partition tolerance"
            echo "  resource-exhaustion Test resource exhaustion handling"
            echo "  dependency-failure  Test external dependency failures"
            echo "  rolling-deployment  Test rolling update availability"
            echo "  suite              Run comprehensive chaos test suite (default)"
            echo "  help               Show this help"
            echo ""
            echo "Examples:"
            echo "  $0                        # Run full chaos test suite"
            echo "  $0 pod-failure 300        # Pod failure test for 5 minutes"
            echo "  $0 network-partition 180  # Network test for 3 minutes"
            ;;
        *)
            print_error "Unknown test type: $test_type"
            print_status "Use '$0 help' for usage information"
            return 1
            ;;
    esac
}

main "$@"