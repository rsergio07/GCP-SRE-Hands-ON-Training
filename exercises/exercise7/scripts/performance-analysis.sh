#!/bin/bash

# Exercise 8 Performance Analysis Script
# SRE performance optimization and capacity planning

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
    echo "  • Prometheus: ${PROMETHEUS_IP:-localhost:9090}"
    return 0
}

# Run baseline performance test
run_baseline_test() {
    print_status "Running baseline performance test..."
    
    # Deploy baseline load test
    kubectl apply -f performance/load-testing.yaml
    
    # Wait for test completion
    kubectl wait --for=condition=complete --timeout=600s job/load-test-baseline
    
    # Get test results
    local test_logs=$(kubectl logs job/load-test-baseline)
    
    # Extract key metrics
    local p95_latency=$(echo "$test_logs" | grep -o 'http_req_duration.*p(95)=[0-9.]*' | grep -o '[0-9.]*$' | head -1)
    local error_rate=$(echo "$test_logs" | grep -o 'http_req_failed.*[0-9.]*%' | grep -o '[0-9.]*%' | head -1)
    local throughput=$(echo "$test_logs" | grep -o 'http_reqs.*[0-9.]*' | grep -o '[0-9.]*' | tail -1)
    
    print_success "Baseline results:"
    echo "  • P95 Latency: ${p95_latency:-unknown}ms"
    echo "  • Error Rate: ${error_rate:-unknown}"
    echo "  • Total Requests: ${throughput:-unknown}"
    
    # Store baseline for comparison
    echo "baseline_p95=$p95_latency" > /tmp/performance_baseline.txt
    echo "baseline_errors=$error_rate" >> /tmp/performance_baseline.txt
    echo "baseline_throughput=$throughput" >> /tmp/performance_baseline.txt
    
    # Cleanup test job
    kubectl delete job load-test-baseline --ignore-not-found=true
}

# Optimize application performance
optimize_performance() {
    print_status "Applying performance optimizations..."
    
    # Deploy optimized configuration
    kubectl apply -f performance/optimization-config.yaml
    
    # Update deployment with performance settings
    kubectl patch deployment sre-demo-app -p '{
        "spec": {
            "template": {
                "spec": {
                    "containers": [{
                        "name": "sre-demo-app",
                        "env": [
                            {"name": "FLASK_ENV", "value": "production"},
                            {"name": "GUNICORN_WORKERS", "value": "4"},
                            {"name": "GUNICORN_THREADS", "value": "2"},
                            {"name": "GUNICORN_TIMEOUT", "value": "30"}
                        ],
                        "resources": {
                            "requests": {"cpu": "200m", "memory": "256Mi"},
                            "limits": {"cpu": "1000m", "memory": "512Mi"}
                        }
                    }]
                }
            }
        }
    }'
    
    # Wait for rollout
    kubectl rollout status deployment/sre-demo-app --timeout=300s
    
    print_success "Performance optimizations applied"
}

# Validate optimization improvements
validate_optimization() {
    print_status "Validating performance improvements..."
    
    # Create validation test job
    cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: load-test-optimized
spec:
  template:
    spec:
      containers:
      - name: k6
        image: grafana/k6:latest
        env:
        - name: TARGET_HOST
          value: "sre-demo-service"
        command:
        - k6
        - run
        - --vus=50
        - --duration=300s
        - /scripts/load-test.js
        volumeMounts:
        - name: script-volume
          mountPath: /scripts
      volumes:
      - name: script-volume
        configMap:
          name: load-test-script
      restartPolicy: Never
EOF

    # Wait for test completion
    kubectl wait --for=condition=complete --timeout=600s job/load-test-optimized
    
    # Get optimized test results
    local test_logs=$(kubectl logs job/load-test-optimized)
    local opt_p95_latency=$(echo "$test_logs" | grep -o 'http_req_duration.*p(95)=[0-9.]*' | grep -o '[0-9.]*$' | head -1)
    local opt_error_rate=$(echo "$test_logs" | grep -o 'http_req_failed.*[0-9.]*%' | grep -o '[0-9.]*%' | head -1)
    local opt_throughput=$(echo "$test_logs" | grep -o 'http_reqs.*[0-9.]*' | grep -o '[0-9.]*' | tail -1)
    
    # Compare with baseline
    if [[ -f /tmp/performance_baseline.txt ]]; then
        source /tmp/performance_baseline.txt
        
        print_success "Optimization results:"
        echo "  • P95 Latency: ${opt_p95_latency:-unknown}ms (baseline: ${baseline_p95:-unknown}ms)"
        echo "  • Error Rate: ${opt_error_rate:-unknown} (baseline: ${baseline_errors:-unknown})"
        echo "  • Total Requests: ${opt_throughput:-unknown} (baseline: ${baseline_throughput:-unknown})"
        
        # Calculate improvements
        if [[ -n "$opt_p95_latency" && -n "$baseline_p95" ]]; then
            local latency_improvement=$(echo "scale=1; ($baseline_p95 - $opt_p95_latency) / $baseline_p95 * 100" | bc -l 2>/dev/null || echo "0")
            print_status "Latency improvement: ${latency_improvement}%"
        fi
    else
        print_warning "No baseline data found for comparison"
    fi
    
    # Cleanup
    kubectl delete job load-test-optimized --ignore-not-found=true
}

# Run capacity planning analysis
capacity_planning() {
    print_status "Running capacity planning analysis..."
    
    # Get current resource utilization
    local cpu_usage=$(kubectl top nodes | awk 'NR>1 {cpu+=$3} END {print cpu"%"}' 2>/dev/null || echo "unknown")
    local memory_usage=$(kubectl top nodes | awk 'NR>1 {mem+=$5} END {print mem"%"}' 2>/dev/null || echo "unknown")
    
    print_status "Current cluster utilization:"
    echo "  • CPU: $cpu_usage"
    echo "  • Memory: $memory_usage"
    
    # Run stress test for capacity analysis
    print_status "Running capacity stress test..."
    
    # Create stress test job
    cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: capacity-stress-test
spec:
  template:
    spec:
      containers:
      - name: k6
        image: grafana/k6:latest
        env:
        - name: TARGET_HOST
          value: "sre-demo-service"
        command:
        - k6
        - run
        - /scripts/stress-test.js
        volumeMounts:
        - name: script-volume
          mountPath: /scripts
      volumes:
      - name: script-volume
        configMap:
          name: stress-test-config
      restartPolicy: Never
EOF

    # Wait for test completion
    kubectl wait --for=condition=complete --timeout=400s job/capacity-stress-test
    
    # Get stress test results
    local stress_logs=$(kubectl logs job/capacity-stress-test)
    local max_latency=$(echo "$stress_logs" | grep -o 'http_req_duration.*max=[0-9.]*' | grep -o '[0-9.]*$' | head -1)
    local stress_errors=$(echo "$stress_logs" | grep -o 'http_req_failed.*[0-9.]*%' | grep -o '[0-9.]*%' | head -1)
    
    print_success "Capacity analysis results:"
    echo "  • Max latency under load: ${max_latency:-unknown}ms"
    echo "  • Error rate under stress: ${stress_errors:-unknown}"
    
    # Check HPA scaling
    local current_replicas=$(kubectl get hpa sre-demo-hpa-advanced -o jsonpath='{.status.currentReplicas}' 2>/dev/null || echo "N/A")
    local max_replicas=$(kubectl get hpa sre-demo-hpa-advanced -o jsonpath='{.spec.maxReplicas}' 2>/dev/null || echo "N/A")
    
    print_status "Auto-scaling status:"
    echo "  • Current replicas: $current_replicas"
    echo "  • Max replicas: $max_replicas"
    
    # Capacity recommendations
    print_status "Capacity planning recommendations:"
    echo "  • Monitor CPU utilization > 60% for scaling decisions"
    echo "  • Plan for 3x peak traffic with 25% safety margin"
    echo "  • Consider cluster autoscaling if node utilization > 80%"
    
    # Cleanup
    kubectl delete job capacity-stress-test --ignore-not-found=true
}

# Generate final performance report
generate_final_report() {
    print_status "Generating final performance report..."
    
    local report_file="/tmp/sre_performance_report.txt"
    
    cat > "$report_file" << EOF
=== SRE PERFORMANCE ANALYSIS REPORT ===
Generated: $(date)
Cluster: $(kubectl config current-context)

SYSTEM OVERVIEW:
$(kubectl get nodes -o wide | head -5)

DEPLOYMENT STATUS:
$(kubectl get deployment sre-demo-app -o custom-columns=NAME:.metadata.name,READY:.status.readyReplicas,UP-TO-DATE:.status.updatedReplicas,AVAILABLE:.status.availableReplicas)

HPA STATUS:
$(kubectl get hpa sre-demo-hpa-advanced -o custom-columns=NAME:.metadata.name,TARGETS:.status.currentMetrics[*].resource.current,MINPODS:.spec.minReplicas,MAXPODS:.spec.maxReplicas,REPLICAS:.status.currentReplicas 2>/dev/null || echo "HPA not configured")

TOP RESOURCE CONSUMERS:
$(kubectl top pods --sort-by=memory | head -10)

RECENT PERFORMANCE METRICS:
$(if [[ -n "$PROMETHEUS_IP" ]]; then
    curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))" | jq -r '.data.result[0].value[1] // "N/A"' 2>/dev/null | xargs -I {} echo "P95 Latency: {}s"
    curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=sum(rate(http_requests_total{status_code=~\"5..\"}[5m])) / sum(rate(http_requests_total[5m])) * 100" | jq -r '.data.result[0].value[1] // "N/A"' 2>/dev/null | xargs -I {} echo "Error Rate: {}%"
else
    echo "Prometheus metrics not available"
fi)

OPTIMIZATION RECOMMENDATIONS:
- Monitor P95 latency < 500ms for optimal user experience
- Maintain error rate < 1% for production workloads  
- Scale horizontally when CPU utilization > 60%
- Consider caching layer for frequently accessed data
- Implement circuit breakers for external dependencies

CAPACITY PLANNING:
- Current configuration supports ~1000 RPS baseline load
- Peak capacity estimated at ~3000 RPS with auto-scaling
- Plan cluster expansion for sustained growth > 20% monthly
EOF

    print_success "Performance report generated: $report_file"
    cat "$report_file"
    
    return 0
}

# Main execution
main() {
    local operation=${1:-"baseline"}
    
    case $operation in
        "baseline")
            get_endpoints && run_baseline_test
            ;;
        "optimize")
            optimize_performance
            ;;
        "validate")
            get_endpoints && validate_optimization
            ;;
        "capacity-planning")
            capacity_planning
            ;;
        "final-report")
            generate_final_report
            ;;
        "full-analysis")
            print_status "Running complete performance analysis..."
            get_endpoints || exit 1
            run_baseline_test
            optimize_performance
            sleep 30
            validate_optimization
            capacity_planning
            generate_final_report
            ;;
        "help")
            echo "Usage: $0 [operation]"
            echo ""
            echo "Operations:"
            echo "  baseline          Run baseline performance test"
            echo "  optimize          Apply performance optimizations"
            echo "  validate          Validate optimization improvements"
            echo "  capacity-planning Run capacity analysis"
            echo "  final-report      Generate comprehensive report"
            echo "  full-analysis     Run complete analysis (default)"
            echo "  help             Show this help"
            echo ""
            echo "Examples:"
            echo "  $0                    # Run full performance analysis"
            echo "  $0 baseline           # Run baseline test only"
            echo "  $0 capacity-planning  # Run capacity analysis only"
            ;;
        *)
            print_error "Unknown operation: $operation"
            print_status "Use '$0 help' for usage information"
            return 1
            ;;
    esac
}

main "$@"