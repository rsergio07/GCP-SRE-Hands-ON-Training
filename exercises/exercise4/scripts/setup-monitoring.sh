#!/bin/bash

# Exercise 4 Monitoring Setup Script
# This script automates the monitoring stack deployment

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

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if kubectl is configured
    if ! kubectl cluster-info &>/dev/null; then
        print_error "kubectl is not configured or cluster is not accessible"
        exit 1
    fi
    
    # Check if SRE demo app is deployed
    if ! kubectl get deployment sre-demo-app &>/dev/null; then
        print_error "SRE demo app is not deployed. Please complete Exercise 3 first."
        exit 1
    fi
    
    # Check if gcloud is configured
    if ! gcloud config get-value project &>/dev/null; then
        print_error "gcloud is not configured with a project"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Enable Google Cloud APIs
enable_apis() {
    print_status "Enabling required Google Cloud APIs..."
    
    gcloud services enable monitoring.googleapis.com
    gcloud services enable logging.googleapis.com
    gcloud services enable clouddebugger.googleapis.com
    
    print_success "APIs enabled successfully"
}

# Deploy Prometheus
deploy_prometheus() {
    print_status "Deploying Prometheus monitoring stack..."
    
    # Apply Prometheus configuration
    kubectl apply -f k8s/monitoring/prometheus-config.yaml
    kubectl apply -f k8s/monitoring/prometheus-deployment.yaml
    
    print_status "Waiting for Prometheus deployment to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/prometheus
    
    print_success "Prometheus deployed successfully"
}

# Configure Google Cloud Monitoring
configure_gcp_monitoring() {
    print_status "Configuring Google Cloud Monitoring integration..."
    
    # Apply Google Managed Prometheus configuration
    kubectl apply -f k8s/monitoring/gmp-config.yaml
    
    print_success "Google Cloud Monitoring configured"
}

# Create dashboard
create_dashboard() {
    print_status "Creating Google Cloud Monitoring dashboard..."
    
    if [ -f "monitoring/dashboard-config.json" ]; then
        gcloud monitoring dashboards create --config-from-file=monitoring/dashboard-config.json
        print_success "Dashboard created successfully"
    else
        print_warning "Dashboard configuration file not found"
    fi
}

# Wait for services
wait_for_services() {
    local max_attempts=30
    local attempt=1
    
    print_status "Waiting for Prometheus LoadBalancer to get external IP..."
    
    while [ $attempt -le $max_attempts ]; do
        local external_ip=$(kubectl get service prometheus-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
        
        if [ -n "$external_ip" ] && [ "$external_ip" != "null" ]; then
            print_success "Prometheus LoadBalancer ready with IP: $external_ip"
            echo $external_ip
            return 0
        fi
        
        print_status "Attempt $attempt/$max_attempts: Waiting for external IP..."
        sleep 20
        ((attempt++))
    done
    
    print_error "LoadBalancer did not get external IP within expected time"
    return 1
}

# Verify deployment
verify_deployment() {
    local prometheus_ip=$1
    
    print_status "Verifying monitoring stack deployment..."
    
    # Check Prometheus health
    if curl -s --max-time 10 "http://$prometheus_ip:9090/-/healthy" > /dev/null; then
        print_success "Prometheus is healthy"
    else
        print_error "Prometheus health check failed"
        return 1
    fi
    
    # Check if targets are discovered
    sleep 30  # Give time for service discovery
    local targets=$(curl -s "http://$prometheus_ip:9090/api/v1/targets" | grep -o '"health":"up"' | wc -l)
    if [ $targets -gt 0 ]; then
        print_success "Prometheus discovered $targets targets"
    else
        print_warning "No healthy targets discovered yet (this may take a few minutes)"
    fi
    
    print_success "Monitoring stack verification complete"
}

# Display access information
show_access_info() {
    local prometheus_ip=$1
    local project_id=$(gcloud config get-value project)
    
    print_success "Monitoring stack deployment completed!"
    echo ""
    print_status "Access URLs:"
    echo "  Prometheus Web UI: http://$prometheus_ip:9090"
    echo "  Google Cloud Monitoring: https://console.cloud.google.com/monitoring/overview?project=$project_id"
    echo ""
    print_status "Useful Prometheus queries to test:"
    echo "  sum(rate(http_requests_total[5m]))"
    echo "  histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))"
    echo "  sum(rate(business_operations_total[5m])) by (operation_type, status)"
    echo ""
    print_status "Generate some traffic to see metrics:"
    echo "  kubectl get service sre-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
    echo "  curl http://\$EXTERNAL_IP/"
}

# Main execution
main() {
    print_status "Starting Exercise 4 monitoring stack setup..."
    
    check_prerequisites
    enable_apis
    deploy_prometheus
    configure_gcp_monitoring
    create_dashboard
    
    prometheus_ip=$(wait_for_services)
    if [ $? -eq 0 ]; then
        verify_deployment $prometheus_ip
        show_access_info $prometheus_ip
    else
        print_error "Setup failed during LoadBalancer configuration"
        return 1
    fi
}

# Handle script arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0"
    echo ""
    echo "Deploys comprehensive monitoring stack including:"
    echo "  - Prometheus with service discovery"
    echo "  - Google Cloud Monitoring integration"
    echo "  - Custom dashboards"
    echo ""
    echo "Prerequisites:"
    echo "  - Completed Exercise 3 (SRE app deployed to GKE)"
    echo "  - kubectl configured with cluster access"
    echo "  - gcloud configured with project"
    exit 0
fi

# Run main function
main "$@"