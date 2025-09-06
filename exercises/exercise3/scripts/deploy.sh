#!/bin/bash

# Exercise 3 Deployment and Verification Script
# This script deploys the application and runs verification tests

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

# Deploy application to Kubernetes
deploy_application() {
    print_status "Deploying application to Kubernetes..."
    
    # Apply manifests in order
    if [ -f "k8s/configmap.yaml" ]; then
        kubectl apply -f k8s/configmap.yaml
        print_status "ConfigMap applied"
    fi
    
    if [ -f "k8s/deployment.yaml" ]; then
        kubectl apply -f k8s/deployment.yaml
        print_status "Deployment applied"
    fi
    
    if [ -f "k8s/service.yaml" ]; then
        kubectl apply -f k8s/service.yaml
        print_status "Service applied"
    fi
    
    if [ -f "k8s/hpa.yaml" ]; then
        kubectl apply -f k8s/hpa.yaml
        print_status "HorizontalPodAutoscaler applied"
    fi
    
    print_success "All manifests applied successfully"
}

# Wait for pods to be ready
wait_for_pods() {
    local max_attempts=60
    local attempt=1
    
    print_status "Waiting for pods to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        local ready_pods=$(kubectl get pods -l app=sre-demo-app -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | wc -w)
        local total_pods=$(kubectl get pods -l app=sre-demo-app --no-headers | wc -l)
        
        if [ $ready_pods -gt 0 ] && [ $ready_pods -eq $total_pods ]; then
            print_success "$ready_pods/$total_pods pods are ready"
            return 0
        fi
        
        print_status "Attempt $attempt/$max_attempts: $ready_pods/$total_pods pods ready"
        sleep 10
        ((attempt++))
    done
    
    print_error "Pods did not become ready within expected time"
    kubectl get pods -l app=sre-demo-app
    return 1
}

# Wait for LoadBalancer to get external IP
wait_for_loadbalancer() {
    local service_name="sre-demo-service"
    local max_attempts=30
    local attempt=1
    
    print_status "Waiting for LoadBalancer to get external IP..."
    
    while [ $attempt -le $max_attempts ]; do
        local external_ip=$(kubectl get service $service_name -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
        
        if [ -n "$external_ip" ] && [ "$external_ip" != "null" ]; then
            print_success "LoadBalancer ready with IP: $external_ip"
            echo $external_ip
            return 0
        fi
        
        print_status "Attempt $attempt/$max_attempts: Waiting for external IP..."
        sleep 20
        ((attempt++))
    done
    
    print_error "LoadBalancer did not get external IP within expected time"
    kubectl describe service $service_name
    return 1
}

# Test application endpoints
test_endpoints() {
    local external_ip=$1
    
    if [ -z "$external_ip" ]; then
        print_error "No external IP provided for testing"
        return 1
    fi
    
    print_status "Testing application endpoints at http://$external_ip"
    
    # Test home endpoint
    if curl -s --max-time 10 "http://$external_ip/" > /dev/null; then
        print_success "Home endpoint (/) is responding"
    else
        print_error "Home endpoint (/) failed"
        return 1
    fi
    
    # Test stores endpoint
    if curl -s --max-time 10 "http://$external_ip/stores" > /dev/null; then
        print_success "Stores endpoint (/stores) is responding"
    else
        print_error "Stores endpoint (/stores) failed"
        return 1
    fi
    
    # Test health endpoint
    if curl -s --max-time 10 "http://$external_ip/health" > /dev/null; then
        print_success "Health endpoint (/health) is responding"
    else
        print_error "Health endpoint (/health) failed"
        return 1
    fi
    
    # Test metrics endpoint
    if curl -s --max-time 10 "http://$external_ip/metrics" > /dev/null; then
        print_success "Metrics endpoint (/metrics) is responding"
    else
        print_error "Metrics endpoint (/metrics) failed"
        return 1
    fi
    
    print_success "All endpoints are working correctly"
}

# Run a basic load test
run_load_test() {
    local external_ip=$1
    local requests=${2:-50}
    
    if [ -z "$external_ip" ]; then
        print_error "No external IP provided for load testing"
        return 1
    fi
    
    print_status "Running basic load test with $requests requests..."
    
    local success_count=0
    local error_count=0
    
    for i in $(seq 1 $requests); do
        if curl -s --max-time 5 "http://$external_ip/" > /dev/null 2>&1; then
            ((success_count++))
        else
            ((error_count++))
        fi
        
        if [ $((i % 10)) -eq 0 ]; then
            print_status "Progress: $i/$requests requests completed"
        fi
        
        sleep 0.1
    done
    
    local success_rate=$(( success_count * 100 / requests ))
    print_status "Load test results: $success_count/$requests successful ($success_rate%)"
    
    if [ $success_rate -ge 95 ]; then
        print_success "Load test passed (>= 95% success rate)"
    else
        print_warning "Load test concerns (< 95% success rate)"
    fi
}

# Display cluster information
show_cluster_info() {
    print_status "Cluster Information:"
    kubectl cluster-info
    
    print_status "\nNode Information:"
    kubectl get nodes -o wide
    
    print_status "\nApplication Status:"
    kubectl get deployments,pods,services -l app=sre-demo-app
    
    if kubectl get hpa sre-demo-hpa &>/dev/null; then
        print_status "\nAutoscaler Status:"
        kubectl get hpa sre-demo-hpa
    fi
    
    print_status "\nResource Usage:"
    kubectl top pods -l app=sre-demo-app 2>/dev/null || print_warning "Metrics not available yet"
}

# Main execution
main() {
    local operation=${1:-"deploy"}
    
    case $operation in
        "deploy")
            print_status "Starting deployment process..."
            deploy_application
            wait_for_pods
            
            external_ip=$(wait_for_loadbalancer)
            if [ $? -eq 0 ]; then
                test_endpoints $external_ip
                run_load_test $external_ip 20
                show_cluster_info
                
                print_success "Deployment completed successfully!"
                print_status "Application URL: http://$external_ip"
                print_status "Try these commands:"
                print_status "  curl http://$external_ip/"
                print_status "  curl http://$external_ip/stores"
                print_status "  curl http://$external_ip/health"
                print_status "  curl http://$external_ip/metrics"
            else
                print_error "Deployment failed during LoadBalancer setup"
                return 1
            fi
            ;;
        "test")
            print_status "Running tests..."
            external_ip=$(kubectl get service sre-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
            if [ -n "$external_ip" ] && [ "$external_ip" != "null" ]; then
                test_endpoints $external_ip
                run_load_test $external_ip 50
            else
                print_error "No external IP found. Is the service deployed?"
                return 1
            fi
            ;;
        "status")
            show_cluster_info
            ;;
        "help")
            echo "Usage: $0 [operation]"
            echo ""
            echo "Operations:"
            echo "  deploy    Deploy application and run verification (default)"
            echo "  test      Run endpoint tests and load test"
            echo "  status    Show cluster and application status"
            echo "  help      Show this help message"
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