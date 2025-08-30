#!/bin/bash

# Exercise 6 GitOps Setup Script
# This script deploys ArgoCD and configures GitOps for the SRE demo application

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
    
    # Check if gcloud is configured
    if ! gcloud config get-value project &>/dev/null; then
        print_error "gcloud is not configured with a project"
        exit 1
    fi
    
    # Check if SRE demo app exists (from previous exercises)
    if ! kubectl get deployment sre-demo-app &>/dev/null; then
        print_warning "SRE demo app not found. This will be created by ArgoCD."
    fi
    
    print_success "Prerequisites check completed"
}

# Install ArgoCD CLI
install_argocd_cli() {
    print_status "Installing ArgoCD CLI..."
    
    if command -v argocd &> /dev/null; then
        print_success "ArgoCD CLI already installed"
        return 0
    fi
    
    # Download and install ArgoCD CLI
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    rm argocd-linux-amd64
    
    print_success "ArgoCD CLI installed successfully"
}

# Deploy ArgoCD
deploy_argocd() {
    print_status "Deploying ArgoCD..."
    
    # Create argocd namespace
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    
    # Install ArgoCD
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    print_status "Waiting for ArgoCD pods to be ready..."
    kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd
    kubectl wait --for=condition=available --timeout=600s deployment/argocd-repo-server -n argocd
    kubectl wait --for=condition=available --timeout=600s deployment/argocd-application-controller -n argocd
    
    print_success "ArgoCD deployed successfully"
}

# Configure ArgoCD LoadBalancer
configure_argocd_access() {
    print_status "Configuring ArgoCD external access..."
    
    # Create LoadBalancer service for ArgoCD server
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: argocd-server-loadbalancer
  namespace: argocd
  labels:
    app.kubernetes.io/name: argocd-server
    app.kubernetes.io/part-of: argocd
spec:
  type: LoadBalancer
  ports:
  - name: https
    port: 443
    protocol: TCP
    targetPort: 8080
  - name: grpc
    port: 80
    protocol: TCP
    targetPort: 8080
  selector:
    app.kubernetes.io/name: argocd-server
EOF

    print_status "Waiting for ArgoCD LoadBalancer to get external IP..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        local external_ip=$(kubectl get service argocd-server-loadbalancer -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
        
        if [ -n "$external_ip" ] && [ "$external_ip" != "null" ]; then
            print_success "ArgoCD LoadBalancer ready with IP: $external_ip"
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

# Configure ArgoCD initial setup
configure_argocd() {
    local argocd_ip=$1
    
    print_status "Configuring ArgoCD..."
    
    # Get initial admin password
    local admin_password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "")
    
    if [ -z "$admin_password" ]; then
        print_error "Could not retrieve ArgoCD admin password"
        return 1
    fi
    
    print_success "ArgoCD admin password: $admin_password"
    
    # Login to ArgoCD CLI (using HTTP for simplicity in this exercise)
    export ARGOCD_OPTS="--insecure"
    
    # Wait for ArgoCD server to be responsive
    print_status "Waiting for ArgoCD server to be responsive..."
    local max_attempts=20
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -k -s "https://$argocd_ip" > /dev/null 2>&1; then
            print_success "ArgoCD server is responsive"
            break
        fi
        
        print_status "Attempt $attempt/$max_attempts: Waiting for ArgoCD server..."
        sleep 15
        ((attempt++))
        
        if [ $attempt -gt $max_attempts ]; then
            print_error "ArgoCD server not responsive within expected time"
            return 1
        fi
    done
    
    # Configure ArgoCD CLI
    argocd login $argocd_ip --username admin --password "$admin_password" --insecure
    
    print_success "ArgoCD configured successfully"
    
    # Store credentials for later use
    echo "ARGOCD_IP=$argocd_ip" > .argocd-config
    echo "ARGOCD_PASSWORD=$admin_password" >> .argocd-config
    
    return 0
}

# Set up GitOps repository configuration
setup_gitops_repo() {
    print_status "Setting up GitOps repository configuration..."
    
    # Get current git repository info
    local git_origin=$(git config --get remote.origin.url 2>/dev/null || echo "")
    local github_repo=""
    
    if [[ $git_origin == *"github.com"* ]]; then
        github_repo=$(echo "$git_origin" | sed 's/.*github.com[:/]\([^/]*\/[^/]*\).*/\1/' | sed 's/\.git$//')
        print_status "Detected GitHub repository: $github_repo"
    else
        print_warning "Could not detect GitHub repository from git config"
        print_status "Please update k8s/argocd-app.yaml manually with your repository URL"
    fi
    
    # Update ArgoCD application manifest with actual repository
    if [ -n "$github_repo" ]; then
        sed -i "s|YOUR_USERNAME/kubernetes-sre-cloud-native|$github_repo|g" k8s/argocd-app.yaml
        print_success "Updated ArgoCD application with repository: $github_repo"
    fi
    
    # Update deployment manifest with project ID
    local project_id=$(gcloud config get-value project 2>/dev/null)
    if [ -n "$project_id" ]; then
        sed -i "s/PROJECT_ID/$project_id/g" k8s/deployment.yaml
        print_success "Updated deployment manifest with project ID: $project_id"
    fi
}

# Deploy monitoring integrations for GitOps
deploy_gitops_monitoring() {
    print_status "Deploying GitOps monitoring integration..."
    
    # Create monitoring directory if it doesn't exist
    mkdir -p monitoring
    
    # Deploy deployment monitoring alerts
    if [ -f "monitoring/deployment-alerts.yaml" ]; then
        kubectl apply -f monitoring/deployment-alerts.yaml
        print_status "Deployment monitoring alerts configured"
    fi
    
    # Update Prometheus config to include ArgoCD metrics
    if [ -f "k8s/prometheus-argocd-config.yaml" ]; then
        kubectl apply -f k8s/prometheus-argocd-config.yaml
        print_status "Prometheus configured to monitor ArgoCD"
    fi
    
    print_success "GitOps monitoring integration deployed"
}

# Test GitOps deployment
test_gitops() {
    print_status "Testing GitOps deployment..."
    
    # Apply ArgoCD application
    kubectl apply -f k8s/argocd-app.yaml
    
    # Wait for application to be created
    sleep 10
    
    # Check application status
    if argocd app list | grep -q "sre-demo-app"; then
        print_success "ArgoCD application created successfully"
        
        # Get application status
        argocd app get sre-demo-app
        
        # Sync application
        print_status "Performing initial sync..."
        argocd app sync sre-demo-app
        
        # Wait for sync to complete
        argocd app wait sre-demo-app --timeout 300
        
        print_success "Initial GitOps sync completed"
    else
        print_error "ArgoCD application creation failed"
        return 1
    fi
}

# Display setup summary
show_setup_summary() {
    local argocd_ip=$1
    local project_id=$(gcloud config get-value project)
    
    print_success "=== GITOPS SETUP COMPLETED ==="
    echo ""
    print_status "Access Information:"
    echo "  • ArgoCD Web UI: https://$argocd_ip"
    echo "  • Username: admin"
    echo "  • Password: $(cat .argocd-config | grep ARGOCD_PASSWORD | cut -d= -f2)"
    echo ""
    print_status "GitOps Workflow:"
    echo "  1. Make changes to application code in exercises/exercise6/"
    echo "  2. Commit and push to main branch"
    echo "  3. GitHub Actions builds new container image"
    echo "  4. GitHub Actions updates k8s/deployment.yaml"
    echo "  5. ArgoCD detects changes and syncs automatically"
    echo "  6. Deployment validation runs automatically"
    echo ""
    print_status "Key Files Created/Updated:"
    echo "  • k8s/argocd-app.yaml - ArgoCD application definition"
    echo "  • k8s/deployment.yaml - Updated with project ID"
    echo "  • .argocd-config - ArgoCD access credentials"
    echo ""
    print_status "Next Steps:"
    echo "  • Test the GitOps workflow by making a code change"
    echo "  • Monitor deployments in ArgoCD web UI"
    echo "  • Set up deployment validation scripts"
    echo "  • Configure automated rollback procedures"
    echo ""
    print_status "Monitoring Integration:"
    echo "  • Prometheus: http://$(kubectl get service prometheus-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null):9090"
    echo "  • Google Cloud: https://console.cloud.google.com/monitoring?project=$project_id"
    echo ""
}

# Main execution
main() {
    print_status "Starting GitOps setup for Exercise 6..."
    
    check_prerequisites
    install_argocd_cli
    deploy_argocd
    
    argocd_ip=$(configure_argocd_access)
    if [ $? -eq 0 ]; then
        configure_argocd $argocd_ip
        setup_gitops_repo
        deploy_gitops_monitoring
        test_gitops
        show_setup_summary $argocd_ip
    else
        print_error "Setup failed during ArgoCD access configuration"
        return 1
    fi
}

# Handle script arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0"
    echo ""
    echo "Sets up GitOps deployment using ArgoCD for the SRE demo application"
    echo ""
    echo "This script will:"
    echo "  1. Deploy ArgoCD to your GKE cluster"
    echo "  2. Configure external access to ArgoCD"
    echo "  3. Set up GitOps repository monitoring"
    echo "  4. Create ArgoCD application for automated deployments"
    echo "  5. Configure monitoring integration"
    echo ""
    echo "Prerequisites:"
    echo "  - Completed Exercises 1-5"
    echo "  - kubectl configured with GKE cluster access"
    echo "  - gcloud configured with project"
    echo ""
    exit 0
fi

# Run main function
main "$@"