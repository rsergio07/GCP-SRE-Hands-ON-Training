# Exercise 2: Container Builds and GitHub Actions

## Table of Contents
- [Introduction](#introduction)
- [Learning Objectives](#learning-objectives)
- [Prerequisites](#prerequisites)
- [Theory Foundation](#theory-foundation)
- [Understanding Containerization for SRE](#understanding-containerization-for-sre)
- [Setting Up Exercise 2 Environment](#setting-up-exercise-2-environment)
- [Building Your First Container Image](#building-your-first-container-image)
- [Implementing Cloud-Based CI/CD](#implementing-cloud-based-cicd)
- [Container Registry Management](#container-registry-management)
- [Testing the Complete Pipeline](#testing-the-complete-pipeline)
- [Final Objective](#final-objective)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)

---

## Introduction

In this exercise, you will learn to containerize your SRE application and implement automated builds using GitHub Actions. You'll work in a dedicated Exercise 2 directory with enhanced application files designed for containerization, then create a complete cloud-based CI/CD pipeline that builds, tests, and stores container images.

This approach demonstrates modern software delivery practices where code commits automatically trigger secure, reproducible builds in cloud environments, preparing your application for deployment to Kubernetes clusters.

---

## Learning Objectives

By completing this exercise, you will understand:

- **Container Fundamentals**: Why containers solve deployment consistency problems in SRE environments
- **Multi-Stage Docker Builds**: How to create optimized, secure container images
- **GitHub Actions CI/CD**: How to implement automated testing and building workflows
- **Container Security**: Best practices for scanning and securing containerized applications
- **Registry Management**: How to store and version container images in cloud registries

---

## Prerequisites

Before starting this exercise, ensure you have completed:

- Exercise 1: Cloud Development Environment Setup
- Google Cloud Platform account configured with billing enabled
- GitHub repository forked with Codespaces access
- Understanding of your Flask application's structure and behavior

Note: This exercise builds on concepts from Exercise 1 but uses a separate directory structure.

---

## Theory Foundation

### Container Technology and SRE

**Essential Watching** (20 minutes):
- [Docker in 100 Seconds](https://www.youtube.com/watch?v=Gjnup-PuquQ) by Fireship - Quick container overview
- [Containers vs Virtual Machines](https://www.youtube.com/watch?v=cjXI-yxqGTI) by IBM Technology - Understanding the differences

**Reference Documentation**:
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/) - Official Docker development guidelines
- [Container Security Guide](https://cloud.google.com/architecture/best-practices-for-building-containers) - Google Cloud security recommendations

### CI/CD and GitOps Principles

**Essential Watching** (15 minutes):
- [GitHub Actions in 100 Seconds](https://www.youtube.com/watch?v=R8_veQiYBjI) by Fireship - Quick CI/CD introduction
- [GitOps Explained](https://www.youtube.com/watch?v=f5EpcWp0THw) by TechWorld with Nana - Modern deployment patterns

**Reference Documentation**:
- [GitHub Actions Documentation](https://docs.github.com/en/actions) - Complete workflow automation guide
- [Google Cloud Build Documentation](https://cloud.google.com/build/docs) - Cloud-native CI/CD platform

### Key Concepts You'll Learn

**Container Benefits for SRE** include consistent runtime environments that eliminate "works on my machine" problems, improved resource utilization through lightweight virtualization, and simplified deployment processes that reduce human error in production releases.

**Multi-Stage Builds** optimize container images by separating build dependencies from runtime requirements. This approach reduces image size, minimizes attack surface, and improves deployment speed while maintaining all necessary runtime components.

**Automated CI/CD Pipelines** ensure that every code change undergoes consistent testing, building, and security scanning before deployment. This automation reduces manual intervention, catches issues early, and provides audit trails for compliance requirements.

---

## Understanding Containerization for SRE

Your SRE application from Exercise 1 demonstrated observability patterns, but production deployments require consistent, reproducible environments across different infrastructure. Containers solve this problem by packaging your application with all its dependencies into a portable, immutable artifact.

### Why Containers Matter for SRE Work

**Environment Consistency** ensures that your application behaves identically whether running in development, staging, or production environments. This consistency eliminates environment-specific bugs that are difficult to reproduce and troubleshoot.

**Immutable Infrastructure** principles require that application deployments use identical, versioned artifacts rather than manual configuration changes. Containers provide this immutability by packaging the complete runtime environment.

**Observability Integration** becomes more important in containerized environments where traditional server monitoring approaches don't apply. Your application's built-in metrics and logging become the primary sources of operational insight.

### Container Architecture for Your Application

Your Flask application will be containerized using a multi-stage Docker build that separates build-time dependencies from runtime requirements. This approach creates smaller, more secure images while maintaining all necessary functionality.

The containerized version will preserve all SRE instrumentation from Exercise 1, including Prometheus metrics endpoints, structured logging output, and health check endpoints that Kubernetes requires for proper orchestration.

---

## Setting Up Exercise 2 Environment

### Step 1: Create Exercise 2 Directory Structure

In your Codespace, create the Exercise 2 directory and copy the necessary files from Exercise 1:

```bash
# Navigate to the exercises directory
cd exercises

# Create Exercise 2 directory structure
mkdir -p exercise2/app
mkdir -p exercise2/.github/workflows

# Copy application files from Exercise 1
cp exercise1/app/* exercise2/app/
cp exercise1/requirements.txt exercise2/

# Navigate to Exercise 2 directory
cd exercise2
```

This creates a clean separation between exercises while preserving the working application code. Exercise 2 will enhance the application with containerization capabilities without modifying Exercise 1.

### Step 2: Examine the Exercise 2 Structure

Look at the files that have been provided for Exercise 2:

```bash
# Check the current directory structure
ls -la

# Examine the application files
ls -la app/

# Verify the requirements file
cat requirements.txt
```

The Exercise 2 directory contains all necessary files for containerization, including the Flask application from Exercise 1, a production-ready Dockerfile, and GitHub Actions workflow configurations.

### Step 3: Review Application Enhancements

Examine the enhanced application configuration for container deployment:

```bash
# Check the main application file
head -20 app/main.py

# Review configuration management
head -15 app/config.py

# Understand the package structure
cat app/__init__.py
```

The application maintains all SRE instrumentation from Exercise 1 while adding container-specific configurations such as proper port binding, signal handling, and health check endpoints optimized for container orchestration platforms.

---

## Building Your First Container Image

### Step 4: Understand the Dockerfile

Examine the provided Dockerfile to understand the container build process:

```bash
# Review the Dockerfile structure
cat Dockerfile
```

The Dockerfile implements a multi-stage build process that separates build-time dependencies from the runtime environment. This approach reduces the final image size while maintaining security by using a non-root user and minimal base image.

The build process includes dependency installation, application copying, proper user configuration for security, and health check definitions that integrate with container orchestration platforms.

### Step 5: Build and Test Locally

Test your container build process in your Codespace to verify that the Dockerfile works correctly:

```bash
# Build the container image
docker build -t sre-demo-app:local .

# Run the container locally
docker run -p 8080:8080 --name sre-app-test sre-demo-app:local
```

The local build process helps validate your Dockerfile configuration before implementing automated builds. This testing approach follows SRE practices of validating changes in controlled environments before production deployment.

Open a new terminal to test the containerized application endpoints and verify that all functionality works correctly within the container environment.

### Step 6: Test Containerized Application

```bash
# Test the containerized application endpoints
curl http://localhost:8080/

# Test the stores endpoint
curl http://localhost:8080/stores

# Test health checks
curl http://localhost:8080/health

# Test metrics endpoint
curl http://localhost:8080/metrics
```

The containerized application should respond identically to the non-containerized version from Exercise 1, demonstrating that containerization preserves all application functionality and SRE instrumentation.

### Step 7: Inspect Container Behavior

```bash
# Inspect the running container
docker exec -it sre-app-test /bin/bash

# Check application processes and user
ps aux
whoami

# Verify application files and permissions
ls -la /app

# Exit container shell
exit

# Stop and remove test container
docker stop sre-app-test
docker rm sre-app-test
```

This inspection process helps you understand how your application operates within the container environment, which is essential for troubleshooting issues in production Kubernetes deployments.

### Understanding Container Responses

**Reference Documentation**:
- [Docker CLI Reference](https://docs.docker.com/engine/reference/commandline/cli/) - Understanding docker commands and output
- [Container Health Checks](https://docs.docker.com/engine/reference/builder/#healthcheck) - Implementing proper health monitoring
- [Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/) - Optimizing container images

---

## Implementing Cloud-Based CI/CD

### Step 8: Configure Google Cloud Integration

Your GitHub Actions workflow requires authentication to push images to Google Container Registry. Set up the necessary service accounts and permissions in Google Cloud Shell:

```bash
# Authenticate to Google Cloud (if not already authenticated)
gcloud auth login

# Set your project ID (replace with your actual project ID)
export PROJECT_ID="your-project-id-here"
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable containerregistry.googleapis.com
gcloud services enable cloudbuild.googleapis.com

# Create service account for GitHub Actions
gcloud iam service-accounts create github-actions-sre \
  --display-name="GitHub Actions for SRE Course" \
  --description="Service account for automated container builds"

# Grant necessary permissions for container registry
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions-sre@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

# Create and download service account key
gcloud iam service-accounts keys create ~/github-actions-sre-key.json \
  --iam-account=github-actions-sre@$PROJECT_ID.iam.gserviceaccount.com

# Display the key content for copying
cat ~/github-actions-sre-key.json
```

Copy the entire JSON output for use in the next step. This service account provides GitHub Actions with the minimum permissions needed to push container images to your Google Container Registry.

### Step 9: Configure Repository Secrets

Add the service account credentials to your GitHub repository as encrypted secrets:

1. Navigate to your forked repository on GitHub
2. Go to Settings → Secrets and variables → Actions
3. Add these repository secrets:

| Secret Name | Value |
|-------------|-------|
| `GCP_PROJECT_ID` | Your Google Cloud project ID |
| `GCP_SA_KEY` | Contents of the `github-actions-sre-key.json` file |

These secrets allow GitHub Actions to authenticate with Google Cloud services while keeping credentials secure and separated from your source code.

### Step 10: Examine the GitHub Actions Workflow

Review the provided GitHub Actions workflow configuration:

```bash
# Examine the workflow file
cat .github/workflows/build-and-push.yml
```

The workflow includes multiple stages for testing the application code, building the container image, scanning for security vulnerabilities, and pushing verified images to Google Container Registry. Each step includes proper error handling and logging for troubleshooting build failures.

---

## Container Registry Management

### Step 11: Understand Image Naming and Tagging

Container images in Google Container Registry follow specific naming conventions that include the registry hostname, project ID, image name, and tag. Understanding this structure is essential for proper image management and deployment.

Your images will be tagged with both the Git commit SHA for precise versioning and conventional tags like `latest` for development purposes. This dual tagging approach supports both reproducible deployments and convenient development workflows.

The workflow automatically generates appropriate tags based on the branch name and commit hash, ensuring that every build produces uniquely identifiable and traceable container images.

---

## Testing the Complete Pipeline

### Step 12: Trigger Your First Automated Build

Make a small change to trigger the automated build pipeline:

```bash
# Make a small change to trigger the pipeline
echo "Container build ready for deployment" >> README.md

# Commit and push the change
git add .
git commit -m "Add container build configuration for Exercise 2"
git push origin main
```

Monitor the GitHub Actions workflow execution by navigating to the Actions tab in your GitHub repository. The workflow should automatically trigger and execute all build steps including testing, image creation, security scanning, and registry upload.

### Step 13: Monitor the Build Process

Watch the GitHub Actions workflow progress:

1. Go to your GitHub repository
2. Click the "Actions" tab
3. Select the latest workflow run
4. Expand each step to see detailed logs

The build process includes application testing, Docker image creation, security vulnerability scanning, and final upload to Google Container Registry. Each step provides detailed logging for troubleshooting any issues.

### Step 14: Verify Container Registry Upload

Once the GitHub Actions workflow completes successfully, verify that your container image was uploaded to Google Container Registry:

```bash
# List images in your project's container registry
gcloud container images list --repository=gcr.io/$PROJECT_ID

# List tags for your specific image
gcloud container images list-tags gcr.io/$PROJECT_ID/sre-demo-app

# Get detailed information about the latest image
gcloud container images describe gcr.io/$PROJECT_ID/sre-demo-app:latest
```

The container registry listing should show your newly built image with appropriate tags based on your Git commit hash and any additional tags specified in the workflow configuration.

---

## Final Objective

By completing this exercise, you should be able to demonstrate:

Your application successfully builds into a secure, optimized container image using multi-stage Docker builds. The GitHub Actions workflow automatically triggers on code changes, performs comprehensive testing and security scanning, and uploads verified images to Google Container Registry. The containerized application maintains identical functionality to Exercise 1, including all Prometheus metrics, structured logging, and health check endpoints required for Kubernetes deployment.

### Verification Questions

Test your understanding by answering these questions:

1. **What advantages** does the multi-stage Docker build provide compared to a single-stage build for production applications?
2. **How would** you troubleshoot a GitHub Actions workflow that fails during the container security scan step?
3. **Why is** the application configured to run as a non-root user inside the container?
4. **What happens** to the container image tags when you push code to a feature branch versus the main branch?

---

## Troubleshooting

### Common Issues

**Docker build fails with "no space left on device"**: Clean up unused Docker images and containers in your Codespace with `docker system prune -a` to free space, or restart the Codespace if the issue persists.

**GitHub Actions authentication errors**: Verify that your `GCP_SA_KEY` secret contains the complete JSON service account key including opening and closing braces, and ensure the service account has the correct IAM permissions for Container Registry access.

**Container Registry API not enabled**: Enable the Container Registry API in your Google Cloud project using `gcloud services enable containerregistry.googleapis.com` and verify billing is enabled for your project.

**Application not responding in container**: Verify that your Flask application is configured to bind to `0.0.0.0:8080` instead of `localhost` to accept connections from outside the container environment.

**Permission denied pushing to registry**: Check that your service account has the `roles/storage.admin` role and that the Container Registry API is enabled in your Google Cloud project.

---

## Next Steps

You have successfully containerized your SRE application using production-ready Docker practices, implemented automated CI/CD pipelines using GitHub Actions, configured secure authentication with Google Cloud services, and stored versioned container images in Google Container Registry with proper tagging strategies.

**Proceed to [Exercise 3](../exercise3/)** where you will deploy your containerized application to Google Kubernetes Engine, configure Kubernetes health checks and resource management, implement horizontal pod autoscaling based on your Prometheus metrics, and establish the foundation for production-ready container orchestration.

**Key Concepts to Remember**: Multi-stage Docker builds optimize image size while maintaining security, automated CI/CD pipelines provide consistency and audit trails for deployments, container registries enable versioned artifact storage for reproducible deployments, and proper tagging strategies support both development workflows and production traceability.

**Before Moving On**: Ensure you can explain how the containerization process preserves all SRE instrumentation from Exercise 1 and why automated security scanning is essential for production container deployments. In the next exercise, you'll orchestrate these containers using Kubernetes.