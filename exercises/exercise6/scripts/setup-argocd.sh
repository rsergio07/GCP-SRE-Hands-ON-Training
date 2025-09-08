#!/bin/bash

# ArgoCD Setup Script for Exercise 6
# This script installs and configures ArgoCD for GitOps deployment

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is available
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        log_error "kubectl cannot connect to cluster"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Create ArgoCD namespace
create_namespace() {
    log_info "Creating ArgoCD namespace..."
    
    if kubectl get namespace argocd &> /dev/null; then
        log_warning "ArgoCD namespace already exists"
    else
        kubectl create namespace argocd
        log_success "ArgoCD namespace created"
    fi
}

# Install ArgoCD
install_argocd() {
    log_info "Installing ArgoCD components..."
    
    # Install ArgoCD using stable release
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    log_success "ArgoCD installation manifest applied"
}

# Configure LoadBalancer service
configure_loadbalancer() {
    log_info "Configuring LoadBalancer access..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: argocd-server-lb
  namespace: argocd
  labels:
    app.kubernetes.io/component: server
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

    log_success "LoadBalancer service configured"
}

# Wait for ArgoCD to be ready
wait_for_argocd() {
    log_info "Waiting for ArgoCD components to be ready..."
    
    # Wait for deployments to be available
    kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd
    kubectl wait --for=condition=available --timeout=600s deployment/argocd-repo-server -n argocd
    kubectl wait --for=condition=available --timeout=600s deployment/argocd-dex-server -n argocd
    kubectl wait --for=condition=available --timeout=600s deployment/argocd-applicationset-controller -n argocd
    
    log_success "ArgoCD components are ready"
}

# Wait for LoadBalancer IP
wait_for_loadbalancer() {
    log_info "Waiting for LoadBalancer IP assignment..."
    
    for i in {1..30}; do
        EXTERNAL_IP=$(kubectl get service argocd-server-lb -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        
        if [[ -n "$EXTERNAL_IP" && "$EXTERNAL_IP" != "null" ]]; then
            log_success "LoadBalancer IP assigned: $EXTERNAL_IP"
            echo "ARGOCD_IP=$EXTERNAL_IP"
            return 0
        fi
        
        log_info "Waiting for LoadBalancer IP... (attempt $i/30)"
        sleep 10
    done
    
    log_warning "LoadBalancer IP not assigned within timeout. Check manually with:"
    log_warning "kubectl get service argocd-server-lb -n argocd"
}

# Get initial admin password
get_admin_password() {
    log_info "Retrieving initial admin password..."
    
    # Wait for secret to be created
    for i in {1..12}; do
        if kubectl get secret argocd-initial-admin-secret -n argocd &> /dev/null; then
            PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
            log_success "Initial admin password retrieved"
            echo "ARGOCD_PASSWORD=$PASSWORD"
            return 0
        fi
        log_info "Waiting for admin secret... (attempt $i/12)"
        sleep 5
    done
    
    log_error "Could not retrieve admin password"
    return 1
}

# Display connection information
display_info() {
    log_info "ArgoCD installation completed!"
    echo ""
    echo "======================================================"
    echo "           ArgoCD Access Information"
    echo "======================================================"
    
    EXTERNAL_IP=$(kubectl get service argocd-server-lb -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
    PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "not available")
    
    echo "URL: https://$EXTERNAL_IP"
    echo "Username: admin"
    echo "Password: $PASSWORD"
    echo ""
    echo "Note: Accept the self-signed certificate in your browser"
    echo "======================================================"
}

# Main installation flow
main() {
    log_info "Starting ArgoCD installation for Exercise 6..."
    
    check_prerequisites
    create_namespace
    install_argocd
    configure_loadbalancer
    wait_for_argocd
    wait_for_loadbalancer
    get_admin_password
    display_info
    
    log_success "ArgoCD setup completed successfully!"
}

# Handle script interruption
trap 'log_error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"