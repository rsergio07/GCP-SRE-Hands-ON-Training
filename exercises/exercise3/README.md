# Exercise 3: Kubernetes Deployment on Google Kubernetes Engine

## Table of Contents
- [Introduction](#introduction)
- [Learning Objectives](#learning-objectives)
- [Prerequisites](#prerequisites)
- [Theory Foundation](#theory-foundation)
- [Understanding Kubernetes for SRE](#understanding-kubernetes-for-sre)
- [Setting Up Google Kubernetes Engine](#setting-up-google-kubernetes-engine)
- [Deploying Your Application to Kubernetes](#deploying-your-application-to-kubernetes)
- [Implementing Production-Ready Configurations](#implementing-production-ready-configurations)
- [Monitoring and Observability Integration](#monitoring-and-observability-integration)
- [Testing Autoscaling and Load Management](#testing-autoscaling-and-load-management)
- [Final Objective](#final-objective)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)

---

## Introduction

In this exercise, you will deploy your containerized SRE application to Google Kubernetes Engine (GKE) using production-ready configurations. You'll implement proper health checks, resource management, horizontal pod autoscaling, and load balancing while maintaining all the observability features built in previous exercises.

This exercise demonstrates how modern SRE teams deploy applications to Kubernetes clusters with proper orchestration, scaling, and monitoring integration that enables reliable production operations.

---

## Learning Objectives

By completing this exercise, you will understand:

- **Kubernetes Architecture**: How container orchestration solves scalability and reliability challenges
- **GKE Autopilot Benefits**: Why managed Kubernetes reduces operational overhead for SRE teams
- **Production Deployment Patterns**: How to configure applications for reliability and scalability
- **Resource Management**: How to set appropriate CPU/memory requests and limits
- **Horizontal Pod Autoscaling**: How to automatically scale applications based on metrics
- **Health Check Integration**: How Kubernetes uses your application's health endpoints
- **Service Discovery and Load Balancing**: How traffic reaches your applications reliably

---

## Prerequisites

Before starting this exercise, ensure you have completed:

- Exercise 1: Cloud Development Environment Setup
- Exercise 2: Container Builds and GitHub Actions
- Successfully built container images available in Google Container Registry
- Google Cloud Platform account with billing enabled
- Understanding of your containerized application's behavior and endpoints

Note: This exercise builds directly on the container images created in Exercise 2.

---

## Theory Foundation

### Kubernetes and Container Orchestration

**Essential Watching** (20 minutes):
- [Kubernetes Explained in 100 Seconds](https://www.youtube.com/watch?v=PziYflu8cB8) by Fireship - Quick Kubernetes overview
- [Kubernetes vs Docker: It's Not an Either/Or Question](https://www.youtube.com/watch?v=2vMEQ5zs1ko) by IBM Technology - Understanding the relationship

**Reference Documentation**:
- [Kubernetes Concepts](https://kubernetes.io/docs/concepts/) - Official Kubernetes architecture guide
- [GKE Autopilot Overview](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview) - Managed Kubernetes benefits

### SRE and Kubernetes Operations

**Essential Watching** (15 minutes):
- [SRE vs DevOps vs Platform Engineering](https://www.youtube.com/watch?v=0UyrVqBoCAU) by TechWorld with Nana - Role clarification
- [Kubernetes Health Checks](https://www.youtube.com/watch?v=mxEvAPQRwhw) by That DevOps Guy - Liveness and readiness probes

**Reference Documentation**:
- [Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) - Health check implementation
- [Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) - Automatic scaling configuration

### Key Concepts You'll Learn

**Container Orchestration** solves the challenge of running containerized applications reliably at scale. Kubernetes provides automatic placement, scaling, networking, and health management that individual containers cannot achieve alone.

**Managed Kubernetes Benefits** through GKE Autopilot eliminate the operational overhead of managing master nodes, worker node patching, and cluster upgrades. This allows SRE teams to focus on application reliability rather than infrastructure management.

**Declarative Configuration** means you describe the desired state of your application (number of replicas, resource requirements, health checks) and Kubernetes continuously works to maintain that state, automatically handling failures and scaling events.

---

## Understanding Kubernetes for SRE

Your containerized application from Exercise 2 included all necessary SRE instrumentation (metrics, logging, health checks), but running a single container doesn't provide the reliability, scalability, or observability that production applications require.

### Why Kubernetes Matters for SRE Work

**Automated Recovery** ensures that failed containers are automatically restarted and replaced without manual intervention. Kubernetes continuously monitors application health and takes corrective action based on the health check endpoints you implemented.

**Horizontal Scaling** allows your application to handle varying load by automatically increasing or decreasing the number of running instances based on CPU, memory, or custom metrics like your Prometheus metrics.

**Service Discovery and Load Balancing** provide consistent network access to your application instances, automatically distributing traffic across healthy pods and removing unhealthy instances from rotation.

**Rolling Deployments** enable zero-downtime updates by gradually replacing old application versions with new ones, ensuring continuous service availability during deployments.

### Kubernetes Architecture for Your Application

Your Flask application will be deployed using multiple Kubernetes resources that work together: a **Deployment** manages the desired number of application replicas, a **Service** provides stable network access and load balancing, a **ConfigMap** manages configuration data separately from application code, and a **HorizontalPodAutoscaler** automatically scales based on resource usage.

---

## Setting Up Google Kubernetes Engine

### Preparing the Cloud Foundation

Before you can deploy your application to Kubernetes, you need to provision the underlying infrastructure. This section guides you through setting up your Google Cloud project and creating a **Google Kubernetes Engine (GKE)** cluster. We will use **GKE Autopilot**, a managed service that automates infrastructure management, allowing you to focus on application reliability and scaling—a core SRE principle.

### Step 1: Prepare Your Development Environment

Navigate to Exercise 3 and examine the provided Kubernetes configurations:

```bash
# Navigate to Exercise 3 directory
cd exercises/exercise3
```

```bash
# Examine the directory structure
ls -la
```

```bash
# Look at the Kubernetes manifests
ls -la k8s/
```

```bash
# Check the setup scripts
ls -la scripts/
```

Exercise 3 includes production-ready Kubernetes manifests for deployment, service configuration, horizontal pod autoscaling, and configuration management, plus automated scripts for cluster creation and application deployment.

### Step 2: Configure Your Project Environment

Set up your Google Cloud project configuration for Exercise 3:

```bash
# Set your project ID (replace with your actual project ID)
export PROJECT_ID="your-project-id-here"
```

```bash
# Verify your project is set correctly
gcloud config set project $PROJECT_ID
gcloud config get-value project
```

```bash
# Verify your container images exist from Exercise 2
gcloud container images list --repository=gcr.io/$PROJECT_ID
```

```bash
# Check for the sre-demo-app image specifically
gcloud container images list-tags gcr.io/$PROJECT_ID/sre-demo-app --limit=5
```

Confirm that you have container images available from Exercise 2. If no images are found, you'll need to complete Exercise 2's CI/CD pipeline first to build and push your container images.

### Step 3: Run the Automated Setup Script

Use the provided setup script to create your GKE cluster and configure the environment:

```bash
# Make the setup script executable
chmod +x scripts/setup.sh
```

```bash
# Run the setup script (this will take 5-10 minutes)
./scripts/setup.sh
```

The setup script automates Google Cloud API activation, GKE Autopilot cluster creation, kubectl configuration, and Kubernetes manifest updates with your project ID. This process typically takes 5-10 minutes for cluster provisioning.

Monitor the script output for any errors. The script will wait for cluster creation to complete before configuring kubectl access.

### Understanding GKE Autopilot Benefits

**Reference Documentation**:
- [GKE Autopilot vs Standard](https://cloud.google.com/kubernetes-engine/docs/resources/autopilot-standard-feature-comparison) - Feature comparison guide
- [Autopilot Pricing](https://cloud.google.com/kubernetes-engine/pricing#autopilot_mode) - Understanding cost optimization
- [Pod Resource Requests](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-resource-requests) - Right-sizing applications

---

## Deploying Your Application to Kubernetes

### Bringing Your Application to Life

You have now built a container image and set up your Kubernetes cluster. This is the moment where those two components meet. This section focuses on the **declarative** nature of Kubernetes deployments. Instead of manually running a container, you will define the desired state of your application using YAML files, and Kubernetes will work to continuously maintain that state. This is the essence of modern, reliable, and automated deployments.

### Step 4: Examine the Kubernetes Manifests

Before deploying, understand each Kubernetes resource and its SRE significance:

```bash
# Examine the deployment configuration
cat k8s/deployment.yaml
```

```bash
# Look at the service configuration
cat k8s/service.yaml
```

```bash
# Check the configuration management
cat k8s/configmap.yaml
```

```bash
# Review the autoscaling configuration
cat k8s/hpa.yaml
```

The **deployment.yaml** defines your application's desired state including replica count, container specifications, health checks, and security settings. The **service.yaml** creates load balancing and network access. The **configmap.yaml** manages configuration data separately from application code. The **hpa.yaml** enables automatic scaling based on resource metrics.

### Step 5: Deploy Using the Automated Script

Deploy your application using the provided deployment script:

```bash
# Make the deploy script executable
chmod +x scripts/deploy.sh
```

```bash
# Deploy the application with full verification
./scripts/deploy.sh

# Alternative: just run tests on existing deployment
# ./scripts/deploy.sh test

# Alternative: check deployment status
# ./scripts/deploy.sh status
```

The deployment script applies all Kubernetes manifests in the correct order, waits for pods to become ready, waits for the LoadBalancer to receive an external IP address, and runs comprehensive endpoint testing to verify the deployment succeeded.

### Step 6: Monitor the Deployment Process

Watch your application deployment in real-time:

```bash
# Watch pods as they start
kubectl get pods -l app=sre-demo-app -w
```

```bash
# In another terminal, check deployment status
kubectl get deployments
```

```bash
# Check service status and external IP
kubectl get services
```

```bash
# View events for troubleshooting
kubectl get events --sort-by=.metadata.creationTimestamp
```

Healthy pods should show `Running` status with `READY 1/1`. The service should show an external IP address (this may take a few minutes to provision). Events provide detailed information about the deployment process and any issues.

---

## Implementing Production-Ready Configurations

### Step 7: Understand Resource Management

Examine how your application is configured for production resource usage:

```bash
# Check resource requests and limits
kubectl describe deployment sre-demo-app
```

```bash
# View current resource usage
kubectl top pods -l app=sre-demo-app
```

```bash
# Check node resource availability
kubectl top nodes
```

Your deployment specifies resource **requests** (guaranteed resources) and **limits** (maximum resources). GKE Autopilot uses these specifications to right-size nodes and ensure efficient resource utilization.

The resource configuration balances performance with cost efficiency. Requests ensure your application has sufficient resources to handle baseline load, while limits prevent resource contention that could affect other workloads.

### Step 8: Verify Health Check Integration

Test how Kubernetes uses your application's health endpoints:

```bash
# Get detailed pod information including health checks
kubectl describe pods -l app=sre-demo-app
```

```bash
# Check health check configuration
kubectl get deployment sre-demo-app -o jsonpath='{.spec.template.spec.containers[0].livenessProbe}'
```

```bash
# Check readiness probe configuration
kubectl get deployment sre-demo-app -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}'
```

Kubernetes uses your `/health` endpoint for liveness probes (determining if containers need to be restarted) and your `/ready` endpoint for readiness probes (determining if containers should receive traffic).

The health check timing parameters balance quick failure detection with avoiding false positives during normal application startup and operation.

### Step 9: Test Application Functionality

Verify that all your SRE instrumentation works correctly in the Kubernetes environment:

```bash
# Get the external IP address
export EXTERNAL_IP=$(kubectl get service sre-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Application URL: http://$EXTERNAL_IP"
```

```bash
# Test the root endpoint
curl http://$EXTERNAL_IP/
```

```bash
# Test the stores endpoint
curl http://$EXTERNAL_IP/stores
```

```bash
# Test the health endpoint
curl http://$EXTERNAL_IP/health
```

```bash
# Test the metrics endpoint
curl http://$EXTERNAL_IP/metrics
```

```bash
# Test error handling
for i in {1..10}; do
  curl -s http://$EXTERNAL_IP/stores | grep -E "(error|stores)"
done
```

All endpoints should work identically to Exercise 1 and 2, demonstrating that Kubernetes deployment preserves application functionality while adding orchestration capabilities.

---

## Monitoring and Observability Integration

### Validating Observability in a Distributed Environment

In Exercise 1, you built an application with robust observability. Now that your application is running in a dynamic, distributed Kubernetes environment, it's crucial to confirm that all of that instrumentation is still working correctly. This section verifies that your application's metrics, logs, and health checks are accessible from outside the container, enabling seamless integration with monitoring systems.

### Step 10: Verify Prometheus Metrics Integration

Confirm that your Prometheus metrics are accessible for monitoring system integration:

```bash
# Check metrics endpoint
curl -s http://$EXTERNAL_IP/metrics | grep -E "(http_requests_total|business_operations)"
```

```bash
# Verify pod-level metrics annotations
kubectl get pods -l app=sre-demo-app -o jsonpath='{.items[0].metadata.annotations}'
```

```bash
# Check service monitoring annotations
kubectl get service sre-demo-headless -o jsonpath='{.metadata.annotations}'
```

The Kubernetes deployment preserves all Prometheus metrics from your application while adding annotations that enable automatic metrics discovery by monitoring systems.

Your application exposes both business metrics (store operations, request counts) and infrastructure metrics that SRE teams use for alerting and capacity planning.

### Step 11: Examine Application Logs

Test structured logging integration with Kubernetes logging infrastructure:

```bash
# View application logs
kubectl logs -l app=sre-demo-app --tail=50
```

```bash
# Follow logs in real-time
kubectl logs -l app=sre-demo-app -f
```

```bash
# Generate some traffic and observe logs
for i in {1..5}; do
  curl -s http://$EXTERNAL_IP/ > /dev/null
  curl -s http://$EXTERNAL_IP/stores > /dev/null
  sleep 1
done
```

Application logs maintain structured JSON format in production, enabling log aggregation systems to parse and analyze log data for troubleshooting and monitoring purposes.

The log correlation with Kubernetes metadata (pod names, namespaces) provides the context needed for effective troubleshooting in distributed environments.

---

## Testing Autoscaling and Load Management

### The Self-Healing, Self-Scaling System

One of the most powerful features of a container orchestration platform is its ability to automatically manage reliability and performance without human intervention. This section demonstrates how Kubernetes reacts to changing conditions. You will test the application’s **horizontal autoscaling** and its ability to **self-heal** from failures, reinforcing why Kubernetes is an essential platform for building resilient, production-grade systems.

### Step 12: Verify Horizontal Pod Autoscaler Configuration

Check that your application is configured for automatic scaling:

```bash
# Check HPA status
kubectl get hpa
```

```bash
# Get detailed HPA information
kubectl describe hpa sre-demo-hpa
```

```bash
# View current metrics used for scaling decisions
kubectl get hpa sre-demo-hpa -o yaml
```

The HorizontalPodAutoscaler monitors CPU and memory utilization, automatically adding or removing pods based on actual resource usage. The scaling policies prevent rapid scaling events that could destabilize the application.

### Step 13: Test Load Handling and Scaling

Generate load to test your application's scaling behavior:

```bash
# Run a more intensive load test
./scripts/deploy.sh test
```

```bash
# Monitor scaling during load test (in another terminal)
watch kubectl get pods -l app=sre-demo-app
```

```bash
# Check resource usage during load
kubectl top pods -l app=sre-demo-app
```

```bash
# View HPA events
kubectl describe hpa sre-demo-hpa
```

Under sustained load, you should observe CPU utilization increasing and potentially new pods being created if the load exceeds the scaling thresholds.

The autoscaling behavior demonstrates how Kubernetes automatically maintains application performance under varying load conditions without manual intervention.

### Step 14: Test Failure Recovery

Simulate application failures to verify Kubernetes recovery mechanisms:

```bash
# Delete a pod to test automatic recovery
kubectl delete pod $(kubectl get pods -l app=sre-demo-app -o jsonpath='{.items[0].metadata.name}')
```

```bash
# Watch recovery process
kubectl get pods -l app=sre-demo-app -w
```

```bash
# Test service continuity during recovery
for i in {1..10}; do
  curl -s http://$EXTERNAL_IP/health | grep status
  sleep 2
done
```

Kubernetes should immediately create a new pod to replace the deleted one, maintaining the desired replica count. Service traffic should continue flowing to healthy pods during the recovery process.

This demonstrates the self-healing capabilities that make Kubernetes deployments more reliable than individual container deployments.

---

## Final Objective

By completing this exercise, you should be able to demonstrate:

Your containerized application successfully deploys to GKE Autopilot with proper resource management and security configuration. The deployment includes working health checks that integrate with Kubernetes orchestration, horizontal pod autoscaling that responds to load changes, and LoadBalancer service that provides reliable external access. All SRE instrumentation (metrics, logging, health endpoints) functions correctly in the Kubernetes environment, and the application automatically recovers from pod failures while maintaining service availability.

### Verification Questions

Test your understanding by answering these questions:

1. **What happens** when you delete a pod from your deployment, and why is this different from running containers manually?
2. **How does** the HorizontalPodAutoscaler use your application's resource requests to make scaling decisions?
3. **Why are** both liveness and readiness probes necessary, and what different actions do they trigger?
4. **What would** happen if you removed the resource limits from your deployment configuration?

---

## Troubleshooting

### Common Issues

**Pods stuck in Pending state**: Check resource requests against node capacity with `kubectl describe nodes` and `kubectl describe pod <pod-name>`. GKE Autopilot will provision new nodes automatically, but this can take several minutes.

**External IP remains <pending> for LoadBalancer service**: GKE LoadBalancer provisioning typically takes 2-5 minutes. Check service status with `kubectl describe service sre-demo-service` and verify that your Google Cloud project has sufficient quota for external IP addresses.

**Health check failures causing pod restarts**: Review health check timing in deployment.yaml and verify that your application starts within the `initialDelaySeconds` period. Check pod logs with `kubectl logs <pod-name>` for application startup errors.

**HPA not scaling properly**: Ensure metrics-server is running with `kubectl top nodes` and verify that your pods have resource requests defined. HPA requires resource requests to calculate utilization percentages.

**Container image pull failures**: Verify that your image exists in Google Container Registry with `gcloud container images list-tags gcr.io/$PROJECT_ID/sre-demo-app` and ensure the deployment.yaml references the correct image path.

### Advanced Troubleshooting

**Debugging networking issues**: Use `kubectl exec -it <pod-name> -- /bin/bash` to access a pod and test internal connectivity with `curl` commands to other pods or services.

**Investigating resource constraints**: Check node resource usage with `kubectl describe nodes` and pod resource usage with `kubectl top pods --containers` to identify resource bottlenecks.

**Analyzing autoscaling decisions**: Review HPA events with `kubectl describe hpa sre-demo-hpa` and check metrics history to understand scaling trigger points.

---

## Next Steps

You have successfully deployed a production-ready SRE application to Google Kubernetes Engine with proper orchestration, scaling, and monitoring integration. You've implemented health checks that enable Kubernetes self-healing, configured resource management for efficient cluster utilization, established horizontal pod autoscaling based on resource metrics, and verified that all observability features work correctly in a distributed environment.

**Proceed to [Exercise 4](../exercise4/)** where you will implement comprehensive monitoring and alerting using Google Cloud Operations, create custom dashboards for your Kubernetes application, configure intelligent alerting based on SLIs and SLOs, and establish incident response workflows that integrate with your deployed application.

**Key Concepts to Remember**: Kubernetes orchestration provides reliability and scalability beyond individual containers, proper resource configuration is essential for both performance and cost optimization, health checks are the foundation of self-healing systems, and horizontal pod autoscaling enables applications to handle variable load automatically.

**Before Moving On**: Ensure you can explain how your deployment configuration balances reliability, performance, and cost, and why the combination of health checks, resource management, and autoscaling creates a production-ready system. In the next exercise, you'll build comprehensive monitoring and alerting on top of this Kubernetes foundation.