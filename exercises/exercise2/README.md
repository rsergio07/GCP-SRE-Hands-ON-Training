# Exercise 2: Container Builds and GitHub Actions

## Table of Contents
- [Introduction](#introduction)
- [Learning Objectives](#learning-objectives)
- [Prerequisites](#prerequisites)
- [Theory Foundation](#theory-foundation)
- [Understanding the Application Structure](#understanding-the-application-structure)
- [Building Your First Container Image](#building-your-first-container-image)
- [Implementing Cloud-Based CI/CD](#implementing-cloud-based-cicd)
- [Container Registry Management](#container-registry-management)
- [Testing the Complete Pipeline](#testing-the-complete-pipeline)
- [Final Objective](#final-objective)
- [Verification Questions](#verification-questions)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)

---

## Introduction

In this exercise, you will learn to containerize your SRE application and implement automated builds using GitHub Actions. You'll work with a pre-configured Exercise 2 directory that contains enhanced application files designed for containerization, then create a complete cloud-based CI/CD pipeline that builds, tests, and stores container images.

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

Navigate to the Exercise 2 directory:

```bash
cd exercises/exercise2
```

Note: This exercise uses a pre-configured directory structure with all necessary files included.

---

## Theory Foundation

### Container Technology and SRE

**Essential Watching** (20 minutes):
- [Docker in 100 Seconds](https://www.youtube.com/watch?v=Gjnup-PuquQ) by Fireship - Quick container overview
- [Containers vs Virtual Machines](https://www.youtube.com/watch?v=cjXI-yxqGTI) by IBM Technology - Understanding the differences

**Reference Documentation**:
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/) - Official Docker development guidelines
- [Implement compute and container security](https://cloud.google.com/architecture/framework/security/compute-container-security) - Google Cloud security recommendations

### CI/CD and GitOps Principles

**Essential Watching** (15 minutes):
- [GitHub Actions Tutorial - Basic Concepts and CI/CD Pipeline with Docker](https://www.youtube.com/watch?v=R8_veQiYBjI) by TechWorld with Nana - Quick CI/CD introduction
- [What is GitOps, How GitOps works and Why it's so useful](https://www.youtube.com/watch?v=f5EpcWp0THw) by TechWorld with Nana - Modern deployment patterns

**Alternative Learning Resources**:
- [GitHub Actions Documentation - Quickstart](https://docs.github.com/en/actions/quickstart) - Official getting started guide
- [GitOps Guide by Weaveworks](https://www.weave.works/technologies/gitops/) - Comprehensive GitOps concepts

**Reference Documentation**:
- [GitHub Actions Documentation](https://docs.github.com/en/actions) - Complete workflow automation guide
- [Google Cloud Build Documentation](https://cloud.google.com/build/docs) - Cloud-native CI/CD platform

### Key Concepts You'll Learn

**Container Benefits for SRE** include consistent runtime environments that eliminate "works on my machine" problems, improved resource utilization through lightweight virtualization, and simplified deployment processes that reduce human error in production releases.

**Multi-Stage Builds** optimize container images by separating build dependencies from runtime requirements. This approach reduces image size, minimizes attack surface, and improves deployment speed while maintaining all necessary runtime components.

**Automated CI/CD Pipelines** ensure that every code change undergoes consistent testing, building, and security scanning before deployment. This automation reduces manual intervention, catches issues early, and provides audit trails for compliance requirements.

---

## Understanding the Application Structure

Your Exercise 2 directory contains a complete containerization setup that enhances the SRE application from Exercise 1 with production-ready containerization capabilities and automated CI/CD workflows.

### Directory Structure Overview

Examine the pre-configured directory structure to understand the containerization components:

```bash
# Check the current directory structure
ls -la
```

```bash
# Display the complete directory tree
tree -a
```

The Exercise 2 directory contains the following key components: application files enhanced for containerization, multi-stage Dockerfile for optimized production images, GitHub Actions workflow for automated CI/CD, and supporting configuration files for container security and optimization.

### Application Files Examination

Review the enhanced application files that maintain all SRE instrumentation while adding container-specific configurations:

```bash
# Examine the application directory structure
ls -la app/
```

```bash
# Review the main application file
head -20 app/main.py
```

```bash
# Check the configuration management
cat app/config.py
```

The application maintains all observability features from Exercise 1, including Prometheus metrics, structured logging, and health check endpoints, while adding container-optimized configuration for port binding, signal handling, and environment-based settings.

### Container Configuration Analysis

Examine the containerization configuration files that implement production-ready container security and optimization:

```bash
# Review the Dockerfile structure
cat Dockerfile
```

```bash
# Check the Docker ignore file
cat .dockerignore
```

```bash
# Verify application requirements
cat requirements.txt
```

The Dockerfile implements multi-stage builds to optimize image size and security, while the .dockerignore file excludes unnecessary files to minimize build context and potential security risks.

### GitHub Actions Workflow Overview

Review the automated CI/CD pipeline configuration that handles testing, building, security scanning, and registry management:

```bash
# Examine the GitHub Actions workflow
cat ../../.github/workflows/build-and-push.yml
```

The workflow implements comprehensive automation including application testing with flake8 and bandit, container image building with Docker Buildx, security scanning with Trivy, and automated pushing to Google Container Registry with proper authentication and tagging strategies.

---

## Building Your First Container Image

### Step 1: Understand the Multi-Stage Dockerfile

The provided Dockerfile implements production-grade containerization using a two-stage build process that separates build dependencies from runtime environment.

Examine the builder stage configuration:

```bash
# Review the builder stage section
head -15 Dockerfile
```

The builder stage installs system dependencies required for compiling Python packages and creates an isolated environment for dependency installation without including build tools in the final image.

Review the production stage configuration:

```bash
# Review the production stage section
tail -20 Dockerfile
```

The production stage implements security best practices including non-root user execution, minimal base image usage, and proper health check configurations for Kubernetes integration.

### Step 2: Build the Container Image Locally

Test your container build process in your Codespace to verify that the Dockerfile works correctly before implementing automated builds.

Build the container image locally:

```bash
# Build the container image with local tag
docker build -t sre-demo-app:local .
```

Expected output:
```
[+] Building 45.2s (17/17) FINISHED
 => [internal] load build definition from Dockerfile
 => [internal] load .dockerignore
 => [builder  1/4] FROM docker.io/library/python:3.11-slim
 => [builder  4/4] RUN pip install --user --no-warn-script-location -r requirements.txt
 => [stage-1  8/8] CMD ["python", "-m", "app.main"]
 => => naming to docker.io/library/sre-demo-app:local
```

This command creates a container image using the multi-stage Dockerfile, demonstrating the complete build process that will later be automated through GitHub Actions.

### Step 3: Test the Container Locally

Run the containerized application to verify that all functionality works correctly within the container environment:

```bash
# Run the container locally
docker run -d -p 8080:8080 --name sre-app-test sre-demo-app:local
```

Expected output:
```
cdc0efee1cdcbb50263daa5449a3c934486f7af8d3838081197c821c231b57b2
```

The container runs in detached mode with port forwarding configured to allow testing of the containerized application endpoints.

### Step 4: Verify Containerized Application Functionality

Test all application endpoints to ensure containerization preserves SRE instrumentation and application functionality:

```bash
# Test the main endpoint
curl http://localhost:8080/
```

Expected output:
```json
{
  "environment": "production",
  "message": "Welcome to sre-demo-app!",
  "status": "healthy",
  "timestamp": 1756767367.1722598,
  "version": "1.0.0"
}
```

```bash
# Test the stores endpoint
curl http://localhost:8080/stores
```

Expected output:
```json
{
  "processing_time": 0.296,
  "stores": [
    {
      "id": 1,
      "items": [
        {
          "id": 1,
          "name": "Kubernetes Cluster",
          "price": 299.99,
          "stock": 5
        }
      ],
      "location": "us-central1",
      "name": "Cloud SRE Store"
    }
  ],
  "total_stores": 2
}
```

```bash
# Test health checks
curl http://localhost:8080/health
```

Expected output:
```json
{
  "checks": {
    "application": "ok",
    "disk": "ok",
    "memory": "ok"
  },
  "status": "healthy",
  "timestamp": 1756767389.5029552,
  "version": "1.0.0"
}
```

```bash
# Test Prometheus metrics endpoint
curl http://localhost:8080/metrics | head -20
```

Expected output:
```
# HELP python_gc_objects_collected_total Objects collected during gc
# TYPE python_gc_objects_collected_total counter
python_gc_objects_collected_total{generation="0"} 566.0
python_gc_objects_collected_total{generation="1"} 53.0
python_gc_objects_collected_total{generation="2"} 0.0
# HELP python_info Python platform information
# TYPE python_info gauge
python_info{implementation="CPython",major="3",minor="11",patchlevel="13",version="3.11.13"} 1.0
# HELP process_virtual_memory_bytes Virtual memory size in bytes.
```

The containerized application should respond identically to the non-containerized version from Exercise 1, demonstrating that containerization preserves all SRE instrumentation and business functionality.

### Step 5: Inspect Container Runtime Behavior

Examine how your application operates within the container environment to understand container security and operational characteristics:

```bash
# Inspect the running container
docker exec -it sre-app-test /bin/bash
```

Inside the container, verify application processes and user configuration:

```bash
# Verify current user (should be non-root)
whoami
```

Expected output:
```
appuser
```

```bash
# Verify application files and permissions
ls -la /app
```

Expected output:
```
total 24
drwxr-xr-x 1 appuser appuser 4096 Sep  1 22:55 .
drwxr-xr-x 1 root    root    4096 Sep  1 22:55 ..
drwxr-xr-x 1 appuser appuser 4096 Aug 31 23:09 app
-rw-rw-rw- 1 appuser appuser   89 Aug 31 23:09 requirements.txt
```

```bash
# Exit container shell
exit
```

This inspection process helps you understand container security implementation and application runtime behavior within the isolated container environment.

### Step 6: Clean Up Local Test Container

Remove the test container to prepare for automated build testing:

```bash
# Stop the test container
docker stop sre-app-test
```

```bash
# Remove the test container
docker rm sre-app-test
```

```bash
# Verify container removal
docker ps -a | grep sre-app-test
```

Expected output (should be empty):
```
(no output - container successfully removed)
```

Local testing validates your Dockerfile configuration and ensures that the automated build process will work correctly when implemented through GitHub Actions.

---

## Implementing Cloud-Based CI/CD

### Step 7: Configure Google Cloud Authentication

Your GitHub Actions workflow requires authentication to push images to Google Container Registry. Set up the necessary service accounts and permissions using Google Cloud Shell.

First, authenticate and configure your Google Cloud project:

```bash
# Authenticate to Google Cloud (if not already authenticated)
gcloud auth login
```

Expected output:
```
Go to the following link in your browser, and complete the sign-in prompts:
    https://accounts.google.com/o/oauth2/auth?response_type=code&client_id=...
Once finished, enter the verification code provided in your browser: 4/0AVMBs...
You are now logged in as [your-email@gmail.com].
Your current project is [None].  You can change this setting by running:
  $ gcloud config set project PROJECT_ID
```

```bash
# Set your project ID using the Project ID (not the project name)
# Find your Project ID in the Google Cloud Console
export PROJECT_ID="your-project-id-here"
gcloud config set project "$PROJECT_ID"
```

**Important**: Use the **Project ID**, not the project name. Project IDs cannot contain spaces and are usually lowercase with hyphens (e.g., `my-trial-project-123456`). You can find your Project ID in the Google Cloud Console dashboard.

Expected output:
```
Updated property [core/project].
```

Enable the required APIs for container registry and build services:

```bash
# Enable Container Registry API
gcloud services enable containerregistry.googleapis.com
```

Expected output:
```
Operation "operations/acat.p2-123456789012-abcd-1234" finished successfully.
```

```bash
# Enable Cloud Build API
gcloud services enable cloudbuild.googleapis.com
```

Expected output:
```
Operation "operations/acat.p2-123456789012-efgh-5678" finished successfully.
```

These APIs provide the infrastructure services required for storing and managing container images in Google Cloud Platform.

### Step 8: Create Service Account for GitHub Actions

Create a dedicated service account with minimal permissions required for container registry operations:

```bash
# Create service account for GitHub Actions
gcloud iam service-accounts create github-actions-sre \
  --display-name="GitHub Actions for SRE Course" \
  --description="Service account for automated container builds"
```

Expected output:
```
Created service account [github-actions-sre].
```

```bash
# Grant storage admin permissions for container registry
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions-sre@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.admin"
```

The service account receives only the minimum permissions necessary to push container images to Google Container Registry, following the principle of least privilege for security.

### Step 9: Generate and Download Service Account Key

Create a service account key that GitHub Actions will use for authentication:

```bash
# Create and download service account key
gcloud iam service-accounts keys create ~/github-actions-sre-key.json \
  --iam-account=github-actions-sre@$PROJECT_ID.iam.gserviceaccount.com
```

```bash
# Display the key content for copying
cat ~/github-actions-sre-key.json
```

Expected output:
```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "1234567890abcdef",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n",
  "client_email": "github-actions-sre@your-project-id.iam.gserviceaccount.com",
  "client_id": "123456789012345678901",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token"
}
```

Copy the entire JSON output from this command for use in configuring GitHub repository secrets. This key provides secure authentication for automated builds without exposing your personal credentials.

### Step 10: Configure Repository Secrets

Add the service account credentials to your GitHub repository as encrypted secrets that GitHub Actions can access during workflow execution.

Navigate to your forked repository on GitHub and follow these steps:

1. Go to Settings → Secrets and variables → Actions
2. Add these repository secrets:

| Secret Name | Value |
|-------------|-------|
| `GCP_PROJECT_ID` | Your Google Cloud project ID |
| `GCP_SA_KEY` | Complete contents of the `github-actions-sre-key.json` file |

These encrypted secrets allow GitHub Actions to authenticate with Google Cloud services while keeping credentials secure and separated from your source code repository.

### Step 11: Understand the GitHub Actions Workflow

The GitHub Actions workflow defines a CI/CD pipeline that validates code quality, performs security checks, builds the container image, and pushes it to a registry.

Workflow files must be located in `.github/workflows/` at the repository root. For this exercise, the relevant workflow is named `build-and-push.yml`.

To examine the workflow structure and job dependencies:

```bash
# Review the workflow file structure (from exercise directory)
head -30 ../../.github/workflows/build-and-push.yml
```

The workflow defines two jobs. The first, `test-application`, handles code linting with flake8, security analysis with bandit, and a basic startup check to catch issues before container creation. The second job, `build-and-push`, depends on the first and handles container image creation and registry upload.

To inspect the testing phase configuration:

```bash
# Examine the application testing job
sed -n '12,40p' ../../.github/workflows/build-and-push.yml
```

This phase ensures the application meets baseline quality and security standards before proceeding.

To inspect the build and push phase configuration:

```bash
# Examine the build and push job
sed -n '42,80p' ../../.github/workflows/build-and-push.yml
```

This phase authenticates with Google Cloud, builds the image using Docker Buildx with caching optimizations, scans it with Trivy for vulnerabilities, and pushes it to Google Container Registry using structured tagging.

---

## Container Registry Management

### Understanding Image Naming and Tagging Strategy

Container images in Google Container Registry follow specific naming conventions that support both development workflows and production traceability.

The workflow automatically generates multiple tags for each successful build: Git commit SHA for precise version tracking, branch name for development identification, and `latest` tag for convenient development access.

This multi-tag approach ensures that every build produces uniquely identifiable container images while supporting flexible deployment strategies for different environments.

### Registry Security and Access Control

Google Container Registry integrates with Google Cloud IAM to provide fine-grained access control for container images. The service account created in previous steps has minimal permissions required only for image storage operations.

Container images stored in the registry are automatically scanned for security vulnerabilities, providing additional protection against known security issues in base images and dependencies.

---

## Testing the Complete Pipeline

### Step 12: Create Feature Branch for Pipeline Testing

Use a feature branch approach to test the automated build pipeline without affecting the main repository state or other exercises.

Create a dedicated feature branch for pipeline testing:

```bash
# Create and switch to a feature branch for testing
git checkout -b exercise2-pipeline-test
```

Expected output:
```
Switched to a new branch 'exercise2-pipeline-test'
```

```bash
# Verify you're on the feature branch
git branch
```

Expected output:
```
* exercise2-pipeline-test
  main
```

This approach follows Git best practices by isolating pipeline testing from the main development branch and avoiding potential conflicts with other exercises.

### Step 13: Trigger the Automated Build Pipeline

Make a small change to trigger the GitHub Actions workflow without modifying critical application files:

```bash
# Create a pipeline test file with timestamp
echo "Pipeline test for Exercise 2 - $(date)" > .pipeline-test
```

```bash
# Add the test file to git staging
git add .pipeline-test
```

```bash
# Commit the change with descriptive message
git commit -m "Test Exercise 2 container build pipeline"
```

Expected output:
```
[exercise2-pipeline-test f1970f5] Test Exercise 2 container build pipeline
 1 file changed, 1 insertion(+)
 create mode 100644 exercises/exercise2/.pipeline-test
```

```bash
# Push the feature branch to trigger the workflow
git push origin exercise2-pipeline-test
```

Expected output:
```
Enumerating objects: 220, done.
Counting objects: 100% (220/220), done.
Delta compression using up to 2 threads
Compressing objects: 100% (185/185), done.
Writing objects: 100% (220/220), 162.39 KiB | 10.83 MiB/s, done.
Total 220 (delta 56), reused 114 (delta 16), pack-reused 0 (from 0)
remote: Resolving deltas: 100% (56/56), done.
remote: 
remote: Create a pull request for 'exercise2-pipeline-test' on GitHub by visiting:
remote:      https://github.com/your-username/kubernetes-sre-cloud-native/pull/new/exercise2-pipeline-test
remote: 
To https://github.com/your-username/kubernetes-sre-cloud-native
 * [new branch]      exercise2-pipeline-test -> exercise2-pipeline-test
```

The GitHub Actions workflow will automatically trigger when the feature branch is pushed, executing all testing, building, and registry upload steps.

### Step 14: Monitor the Build Process

Watch the GitHub Actions workflow progress through the web interface to understand the complete automation process.

Navigate to your GitHub repository and monitor the workflow execution:

1. Click the "Actions" tab in your GitHub repository
2. Select the latest workflow run triggered by your push
3. Expand each job and step to see detailed logs
4. Monitor the progress through testing, building, and registry upload phases

The build process includes comprehensive logging for troubleshooting any issues that may occur during automated execution.

### Step 15: Verify Container Registry Upload

Once the GitHub Actions workflow completes successfully, verify that your container image was uploaded to Google Container Registry with proper tags.

List images in your project's container registry:

```bash
# List all images in your project's registry
gcloud container images list --repository=gcr.io/$PROJECT_ID
```

Expected output:
```
NAME
gcr.io/your-project-id/sre-demo-app
```

```bash
# List specific tags for your application image
gcloud container images list-tags gcr.io/$PROJECT_ID/sre-demo-app
```

Expected output:
```
DIGEST        TAGS                              TIMESTAMP
sha256:1a2b3c  exercise2-pipeline-test-a1b2c3d  2024-09-01T14:30:45
sha256:1a2b3c  latest                           2024-09-01T14:30:45
```

```bash
# Get detailed information about the latest image
gcloud container images describe gcr.io/$PROJECT_ID/sre-demo-app:latest
```

Expected output:
```
image_summary:
  digest: sha256:1a2b3c4d5e6f7890abcdef1234567890abcdef1234567890abcdef1234567890
  fully_qualified_digest: gcr.io/your-project-id/sre-demo-app@sha256:1a2b3c...
  registry: gcr.io
  repository: your-project-id/sre-demo-app
package_vulnerability_summary:
  vulnerabilities_by_severity:
    MEDIUM: 2
    LOW: 5
provenance_summary: {}
```

The container registry should show your newly built image with multiple tags including the Git commit hash, branch name, and latest tag for development convenience.

### Step 16: Clean Up Feature Branch

After successful pipeline testing, clean up the feature branch to maintain repository organization:

```bash
# Switch back to main branch
git checkout main
```

```bash
# Delete the local feature branch
git branch -d exercise2-pipeline-test
```

```bash
# Delete the remote feature branch
git push origin --delete exercise2-pipeline-test
```

This cleanup maintains a clean repository structure while preserving the container image artifacts created during the pipeline test.

---

## Final Objective

By completing this exercise, you should be able to demonstrate comprehensive understanding of containerization and automated CI/CD implementation for SRE applications.

Your accomplishments include successfully containerizing the SRE application using production-grade multi-stage Docker builds that optimize image size and implement security best practices. The GitHub Actions workflow automatically triggers on code changes, performs comprehensive testing including code linting and security scanning, and uploads verified container images to Google Container Registry with proper authentication and tagging strategies.

The containerized application maintains identical functionality to Exercise 1, preserving all Prometheus metrics, structured logging, and health check endpoints while adding container-specific optimizations for Kubernetes deployment readiness.

The implemented CI/CD pipeline demonstrates modern DevOps practices including automated quality gates, security validation, and reproducible build processes that eliminate manual deployment errors and provide audit trails for compliance requirements.

---

## Verification Questions

Test your understanding of containerization and CI/CD concepts by answering these questions:

1. **What specific advantages** does the multi-stage Docker build provide compared to a single-stage build for production applications, and how does this impact both security and operational efficiency?

2. **How would you troubleshoot** a GitHub Actions workflow that fails during the Trivy security scan step, and what steps would you take to identify and resolve container vulnerabilities?

3. **Why is the application configured** to run as a non-root user inside the container, and what additional security measures are implemented in the Dockerfile to minimize attack surface?

4. **What happens to container image tags** when you push code to a feature branch versus the main branch, and how does this tagging strategy support different deployment environments?

5. **How does the automated pipeline** ensure that only validated, secure container images reach the production registry, and what would happen if any of the quality gates fail?

---

## Troubleshooting

### Container Build Issues

**Docker build fails with "no space left on device"**: Clean up unused Docker images and containers with `docker system prune -a`, or restart the Codespace if disk space issues persist in the development environment.

**Multi-stage build fails at dependency installation**: Verify that the `requirements.txt` file contains valid Python package specifications and that network connectivity allows package downloads from PyPI during the build process.

**Container fails to start with permission errors**: Check that the Dockerfile properly configures the non-root user with correct file ownership and that application files have appropriate permissions for the container runtime.

### GitHub Actions Authentication Issues

**Authentication errors with Google Cloud**: Verify that the `GCP_SA_KEY` secret contains the complete JSON service account key including opening and closing braces, and ensure the service account has the correct IAM permissions.

**Container Registry API not enabled**: Enable the Container Registry API using `gcloud services enable containerregistry.googleapis.com` and verify that billing is enabled for your Google Cloud project.

**Permission denied pushing to registry**: Confirm that the service account has the `roles/storage.admin` role and that the Container Registry API is properly enabled with billing configured.

### Application Runtime Issues

**Application not responding in container**: Verify that Flask is configured to bind to `0.0.0.0:8080` instead of `localhost` to accept connections from outside the container environment, and check that health check endpoints are properly configured.

**Metrics endpoint returns empty response**: Ensure that Prometheus metrics are properly initialized before the first request and that the metrics endpoint is accessible within the container networking configuration.

**Health checks failing in container**: Verify that health check endpoints respond correctly and that the curl command in the Dockerfile HEALTHCHECK instruction can access the application on the expected port.

### Pipeline Execution Issues

**Workflow not triggering on push**: Check that the workflow file is in the correct `.github/workflows/` directory and that the branch and path filters in the workflow configuration match your repository structure.

**Build process hangs during testing**: Verify that test commands complete within reasonable timeouts and that the application can start successfully in the GitHub Actions environment without interactive prompts.

**Security scan fails with high-severity vulnerabilities**: Update base images and dependencies to resolve security issues, or configure the Trivy scanner to use appropriate severity thresholds for your security requirements.

---

## Next Steps

You have successfully implemented comprehensive containerization and automated CI/CD for your SRE application using production-ready practices that demonstrate modern software delivery excellence.

Your achievements include creating optimized, secure container images using multi-stage Docker builds, implementing automated CI/CD pipelines with comprehensive testing and security validation, configuring secure authentication and access control for cloud container registries, and establishing proper image tagging strategies that support both development workflows and production traceability.

**Proceed to [Exercise 3](../exercise3/)** where you will deploy your containerized application to Google Kubernetes Engine, implementing Kubernetes health checks and resource management, configuring horizontal pod autoscaling based on Prometheus metrics, and establishing production-ready container orchestration with proper service discovery and load balancing.

**Key Concepts to Remember**: Multi-stage Docker builds optimize image size while maintaining security through separation of build and runtime environments. Automated CI/CD pipelines provide consistency, quality gates, and audit trails that eliminate manual deployment errors. Container registries enable versioned artifact storage with proper authentication and access control for production deployments. Security scanning and vulnerability management are essential components of production-ready container workflows.

**Before Moving On**: Ensure you can explain how containerization preserves all SRE instrumentation while adding cloud-native deployment capabilities, why automated security scanning is critical for production container deployments, and how the implemented CI/CD pipeline supports both development agility and operational reliability. In Exercise 3, you'll orchestrate these containers using Kubernetes to complete the cloud-native deployment architecture.