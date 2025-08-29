#!/bin/bash

# Exercise 3 Setup Script
# This script automates the initial setup for deploying to GKE

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI is not installed"
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Get project ID from user or environment
get_project_id() {
    if [ -z "$PROJECT_ID" ]; then
        PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
        if [ -z "$PROJECT_ID" ]; then
            print_error "No project ID found. Please set PROJECT_ID environment variable or run 'gcloud config set project YOUR_PROJECT_ID'"
            exit 1
        fi
    fi
    
    print_status "Using project: $PROJECT_ID"
}

# Enable required APIs
enable_apis() {
    print_status "Enabling required Google Cloud APIs..."
    
    gcloud services enable container.googleapis.com \
        compute.googleapis.com \
        monitoring.googleapis.com \
        logging.googleapis.com \
        --project=$PROJECT_ID
    
    print_success "APIs enabled successfully"
}

# Create GKE cluster
create_cluster() {
    local cluster_name=${1:-"sre-demo-cluster"}
    local location=${2:-"us-central1"}
    
    print_status "Creating GKE Autopilot cluster: $cluster_name"
    
    if gcloud container clusters describe $cluster_name --location=$location --project=$PROJECT_ID &>/dev/null; then
        print_warning "k8s/deployment.yaml not found"
    fi
    
    print_success "Manifest files updated"
}

# Check if container images exist
check_images() {
    print_status "Checking for container images..."
    
    if gcloud container images list --repository=gcr.io/$PROJECT_ID | grep -q "sre-demo-app"; then
        print_success "Container images found in registry"
        gcloud container images list-tags gcr.io/$PROJECT_ID/sre-demo-app --limit=5
    else
        print_warning "No container images found. Make sure to complete Exercise 2 first"
        print_status "You can check images with: gcloud container images list --repository=gcr.io/$PROJECT_ID"
    fi
}

# Main execution
main() {
    print_status "Starting Exercise 3 GKE setup..."
    
    check_prerequisites
    get_project_id
    enable_apis
    check_images
    
    local cluster_name=${1:-"sre-demo-cluster"}
    local location=${2:-"us-central1"}
    
    create_cluster $cluster_name $location
    wait_for_cluster $cluster_name $location
    configure_kubectl $cluster_name $location
    update_manifests
    
    print_success "Setup complete! You can now deploy your application with:"
    print_status "  kubectl apply -f k8s/"
    print_status ""
    print_status "Monitor deployment with:"
    print_status "  kubectl get pods -w"
    print_status "  kubectl get services"
}

# Handle script arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [cluster-name] [location]"
    echo ""
    echo "Creates a GKE Autopilot cluster and configures kubectl"
    echo ""
    echo "Arguments:"
    echo "  cluster-name    Name for the GKE cluster (default: sre-demo-cluster)"
    echo "  location        GCP location for cluster (default: us-central1)"
    echo ""
    echo "Environment variables:"
    echo "  PROJECT_ID      Google Cloud project ID (required if not set in gcloud config)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Use defaults"
    echo "  $0 my-cluster us-west1               # Custom cluster name and location"
    echo "  PROJECT_ID=my-project $0             # Custom project ID"
    exit 0
fi

# Run main function with arguments
main "$@"Cluster $cluster_name already exists"
        return 0
    fi
    
    gcloud container clusters create-auto $cluster_name \
        --location=$location \
        --project=$PROJECT_ID \
        --async
    
    print_status "Cluster creation initiated. This may take 5-10 minutes..."
    print_status "You can check status with: gcloud container clusters list --location=$location"
}

# Wait for cluster to be ready
wait_for_cluster() {
    local cluster_name=${1:-"sre-demo-cluster"}
    local location=${2:-"us-central1"}
    local max_attempts=30
    local attempt=1
    
    print_status "Waiting for cluster to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        local status=$(gcloud container clusters describe $cluster_name \
            --location=$location \
            --project=$PROJECT_ID \
            --format="value(status)" 2>/dev/null)
        
        if [ "$status" = "RUNNING" ]; then
            print_success "Cluster is ready!"
            return 0
        fi
        
        print_status "Attempt $attempt/$max_attempts: Cluster status is $status"
        sleep 30
        ((attempt++))
    done
    
    print_error "Cluster did not become ready within expected time"
    return 1
}

# Configure kubectl
configure_kubectl() {
    local cluster_name=${1:-"sre-demo-cluster"}
    local location=${2:-"us-central1"}
    
    print_status "Configuring kubectl..."
    
    gcloud container clusters get-credentials $cluster_name \
        --location=$location \
        --project=$PROJECT_ID
    
    # Verify connection
    if kubectl cluster-info &>/dev/null; then
        print_success "kubectl configured successfully"
        kubectl get nodes
    else
        print_error "Failed to configure kubectl"
        return 1
    fi
}

# Update Kubernetes manifests with correct project ID
update_manifests() {
    print_status "Updating Kubernetes manifests with project ID..."
    
    if [ -f "k8s/deployment.yaml" ]; then
        sed -i.bak "s/PROJECT_ID/$PROJECT_ID/g" k8s/deployment.yaml
        print_status "Updated deployment.yaml"
    else
        print_warning "