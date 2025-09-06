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

Navigate to the **Exercise 3** directory. This folder contains all the manifests and scripts needed for a production-ready deployment:

```bash
cd exercises/exercise3
```

Inside you will find:

* **`README.md`** → documentation for this exercise.
* **`k8s/`** → Kubernetes manifests for Deployment, Service, ConfigMap, and HPA.
* **`scripts/`** → automation scripts for setup and deployment.

Let’s inspect these files to understand their role in reliability and scalability:

```bash
# Explore the Kubernetes manifests
ls -la k8s/
```

#### What to look for:

* `configmap.yaml`: separates configuration from code, enabling updates without rebuilding the image.
* `deployment.yaml`: defines replicas, resource requests/limits, health probes, and security context.
* `hpa.yaml`: sets up autoscaling rules based on CPU and memory utilization.
* `service.yaml`: exposes the app externally and sets up a headless service for monitoring.

```bash
# Explore the setup and deployment automation scripts
ls -la scripts/
```

#### What to look for:

* `setup.sh`: provisions the GKE Autopilot cluster, enables APIs, updates manifests with your project ID.
* `deploy.sh`: applies manifests in order, waits for pods and services to be ready, tests endpoints, and runs a basic load test.

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
gcloud artifacts docker images list us-central1-docker.pkg.dev/gcp-sre-lab/sre-demo-app
```

```bash
# Check for the sre-demo-app image specifically
gcloud artifacts docker tags list us-central1-docker.pkg.dev/$PROJECT_ID/sre-demo-app
```

Confirm that you have container images available from Exercise 2. If no images are found, you'll need to complete Exercise 2's CI/CD pipeline first to build and push your container images.

### Installing the GKE Authentication Plugin

The `kubectl` command requires a credential plugin to authenticate with your Google Kubernetes Engine (GKE) cluster. This plugin is not always installed by default with the `gcloud` CLI.

If you encounter an error like `exec: executable gke-gcloud-auth-plugin not found`, you need to install this component. Run the following command in your terminal to resolve the issue:

```bash
gcloud components install gke-gcloud-auth-plugin
```

After the installation completes, you can proceed with running the `setup.sh` and `deploy.sh` scripts. This plugin ensures `kubectl` can securely connect to and manage your cluster.

### Step 3: Run the Automated Setup Script and Monitor in the Console

Use the provided setup script to create your GKE cluster and configure the environment.

```bash
# Make the setup script executable
chmod +x scripts/setup.sh

# Run the setup script (this will take 5-10 minutes)
./scripts/setup.sh
```

**While the script is running, open the Google Cloud Console in your browser.**

Instead of waiting for the terminal to finish, you can actively watch the cluster being provisioned and explore the console. This is a common practice for SREs to monitor large operations.

1.  Navigate to the **Kubernetes Engine** section in the GCP Console.
2.  Click on **Clusters** in the left-hand navigation menu.
3.  You will see a cluster named `sre-demo-cluster` in a **"Provisioning"** status.
4.  Click on the cluster name to view its details, including the creation events and the progress of the underlying infrastructure components.

This process gives you a direct look at the self-healing and automation capabilities of GKE, even before the deployment starts.

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

## Step 6: Monitor the Deployment Process

This step demonstrates real-time visibility into Kubernetes orchestration. Understanding how to monitor deployments is crucial for SRE teams to identify issues immediately and understand system behavior during critical operations.

### Watch Pods in Real-Time

Monitor your application pods as they start and become ready:

```bash
# Watch pods as they start (use Ctrl+C to stop)
kubectl get pods -l app=sre-demo-app -w
```

**What you'll see:** Pods transition through lifecycle states. Initially, you might see pods in `Pending` or `ContainerCreating` states, then progressing to `Running` with `READY 1/1`.

**Why this matters:** Real-time pod monitoring allows you to immediately detect deployment issues like image pull failures, resource constraints, or startup problems. The `-w` flag provides continuous updates, essential for incident response.

### Check Deployment Status

In another terminal, examine the overall deployment health:

```bash
# Check deployment status
kubectl get deployments
```

**Expected output:**
```
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
sre-demo-app   2/2     2            2           123m
```

**Understanding the columns:**
- **READY**: `2/2` means 2 pods are ready out of 2 desired replicas
- **UP-TO-DATE**: `2` pods are running the latest deployment configuration
- **AVAILABLE**: `2` pods are available to serve traffic
- **AGE**: How long the deployment has been running

**What this tells you:** A healthy deployment shows matching numbers across READY, UP-TO-DATE, and AVAILABLE. Mismatched numbers indicate ongoing deployments, failed pods, or scaling operations.

### Monitor Service and External Access

Check your service status and LoadBalancer provisioning:

```bash
# Check service status and external IP
kubectl get services
```

**Expected output:**
```
NAME                TYPE           CLUSTER-IP       EXTERNAL-IP       PORT(S)        AGE
kubernetes          ClusterIP      34.118.224.1     <none>            443/TCP        150m
sre-demo-headless   ClusterIP      None             <none>            8080/TCP       123m
sre-demo-service    LoadBalancer   34.118.239.219   104.154.201.227   80:31777/TCP   123m
```

**Key insights:**
- **sre-demo-service**: Your main LoadBalancer with external IP `104.154.201.227`
- **sre-demo-headless**: ClusterIP `None` indicates a headless service for direct pod access (used for monitoring)
- **kubernetes**: Default cluster service for API server access

**What to watch for:** External IP should show an actual IP address, not `<pending>`. If still pending, LoadBalancer provisioning is in progress (typically 2-5 minutes).

### Analyze Events for Troubleshooting

Examine Kubernetes events to understand deployment decisions and any issues:

```bash
# View events for troubleshooting
kubectl get events --sort-by=.metadata.creationTimestamp
```

**What you'll see in the events (key patterns):**
```
LAST SEEN   TYPE      REASON                    OBJECT                           MESSAGE
10m         Normal    ScalingReplicaSet         deployment/sre-demo-app          Scaled up replica set sre-demo-app-7458c58c57 from 0 to 1
10m         Normal    Scheduled                 pod/sre-demo-app-7458c58c57-6cn9z Successfully assigned default/sre-demo-app-7458c58c57-6cn9z to gk3-sre-demo-cluster-nap-p0xsavji-01109c4e-cb9j
10m         Normal    Pulling                   pod/sre-demo-app-7458c58c57-6cn9z Pulling image "us-central1-docker.pkg.dev/..."
10m         Normal    Pulled                    pod/sre-demo-app-7458c58c57-6cn9z Successfully pulled image ... in 242ms
10m         Normal    Created                   pod/sre-demo-app-7458c58c57-6cn9z Created container: sre-demo-app
10m         Normal    Started                   pod/sre-demo-app-7458c58c57-6cn9z Started container sre-demo-app
```

**Understanding events:**
- **ScalingReplicaSet**: Kubernetes creating/removing pods to match desired state
- **Scheduled**: Pod assigned to a specific node
- **Pulling/Pulled**: Container image download (note the speed: 242ms indicates cached images)
- **Created/Started**: Container lifecycle completion

**SRE insight:** Fast image pulls (< 1 second) indicate effective image caching. Multiple replica set events suggest the deployment went through several iterations to reach the current stable state.

---

## Step 7: Understanding Resource Management in Production

This step validates that your production resource configuration properly balances performance, reliability, and cost—core concerns for SRE teams managing infrastructure at scale.

### Examine Deployment Resource Configuration

Review how your application's resource requests and limits are configured:

```bash
# Check resource requests and limits
kubectl describe deployment sre-demo-app
```

**Key sections to examine:**

**Resource Configuration:**
```
Limits:
  cpu:                500m
  ephemeral-storage:  1Gi
  memory:             256Mi
Requests:
  cpu:                100m
  ephemeral-storage:  1Gi
  memory:             128Mi
```

**Health Check Configuration:**
```
Liveness:   http-get http://:8080/health delay=30s timeout=5s period=10s #success=1 #failure=3
Readiness:  http-get http://:8080/ready delay=5s timeout=3s period=5s #success=1 #failure=3
```

**Understanding resource settings:**
- **Requests**: Guaranteed resources (100m CPU = 0.1 CPU cores, 128Mi = 128 megabytes)
- **Limits**: Maximum allowed resources (500m CPU = 0.5 cores, 256Mi = 256 megabytes)
- **GKE Autopilot additions**: Note the `ephemeral-storage: 1Gi` automatically added by Autopilot

**Why this matters:** Requests ensure your application has sufficient resources for baseline performance. Limits prevent resource contention with other workloads. The 5:1 CPU ratio (500m limit vs 100m request) allows burst capacity while guaranteeing minimum performance.

### Monitor Actual Resource Usage

Check how much of your allocated resources your application actually uses:

```bash
# View current resource usage
kubectl top pods -l app=sre-demo-app
```

**Expected output:**
```
NAME                            CPU(cores)   MEMORY(bytes)   
sre-demo-app-7458c58c57-6cn9z   2m           26Mi            
sre-demo-app-7458c58c57-bmx6h   2m           25Mi            
```

**Resource analysis:**
- **CPU usage**: `2m` (0.002 cores) is well below the `100m` request and `500m` limit
- **Memory usage**: `25-26Mi` is below the `128Mi` request and `256Mi` limit
- **Efficiency**: Application is well-sized for current load

**SRE implications:** Low resource utilization indicates room for optimization. You could potentially reduce requests to improve cluster efficiency or increase limits if you expect higher load.

### Check Node Resource Capacity

Understand the broader cluster resource context:

```bash
# Check node resource availability
kubectl top nodes
```

**Expected output:**
```
NAME                                              CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
gk3-sre-demo-cluster-nap-p0xsavji-01109c4e-cb9j   228m         1%       2369Mi          4%          
```

**Node capacity insights:**
- **CPU**: `228m` used out of approximately 22.8 cores (1% utilization)
- **Memory**: `2369Mi` used out of approximately 59GB (4% utilization)
- **Efficiency**: Very low utilization typical of development/learning environments

**GKE Autopilot benefit:** The cluster automatically provisions appropriately-sized nodes based on your workload requirements, ensuring efficient resource utilization without manual node management.

---

## Step 8: Verify Health Check Integration

This step confirms that your application's health endpoints integrate correctly with Kubernetes orchestration, enabling self-healing and automated traffic management.

### Examine Pod Health Check Details

Get detailed information about how Kubernetes implements your health checks:

```bash
# Get detailed pod information including health checks
kubectl describe pods -l app=sre-demo-app
```

**Health check configuration in pod description:**
```
Liveness:   http-get http://:8080/health delay=30s timeout=5s period=10s #success=1 #failure=3
Readiness:  http-get http://:8080/ready delay=5s timeout=3s period=5s #success=1 #failure=3
```

**Understanding the timing parameters:**
- **Liveness probe**: `delay=30s` allows application startup, `period=10s` checks every 10 seconds, `failure=3` requires 3 consecutive failures before restart
- **Readiness probe**: `delay=5s` enables quick traffic routing, `period=5s` frequent traffic management decisions, `failure=3` removes from service after 3 failures

**Current status indicators:**
```
Ready:          True
Restart Count:  0
```

**Why this matters:** `Ready: True` confirms your `/ready` endpoint is responding correctly. `Restart Count: 0` indicates your `/health` endpoint hasn't triggered any container restarts, showing application stability.

### Inspect Health Check Configuration Details

Examine the exact probe configurations:

```bash
# Check liveness probe configuration
kubectl get deployment sre-demo-app -o jsonpath='{.spec.template.spec.containers[0].livenessProbe}'
```

**Expected output:**
```json
{"failureThreshold":3,"httpGet":{"path":"/health","port":8080,"scheme":"HTTP"},"initialDelaySeconds":30,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":5}
```

```bash
# Check readiness probe configuration
kubectl get deployment sre-demo-app -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}'
```

**Expected output:**
```json
{"failureThreshold":3,"httpGet":{"path":"/ready","port":8080,"scheme":"HTTP"},"initialDelaySeconds":5,"periodSeconds":5,"successThreshold":1,"timeoutSeconds":3}
```

**Configuration analysis:**
- **Different endpoints**: `/health` for container lifecycle, `/ready` for traffic routing
- **Different timing**: Liveness has longer delays to avoid restart loops, readiness has faster response for traffic management
- **Failure thresholds**: Both require 3 consecutive failures, preventing false positives from temporary issues

---

## Step 9: Test Application Functionality in Kubernetes

This step verifies that containerization and Kubernetes deployment preserve all application functionality while adding orchestration capabilities.

### Extract and Test External Access

Get your application's external IP address and verify basic connectivity:

```bash
# Get the external IP address
export EXTERNAL_IP=$(kubectl get service sre-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Application URL: http://$EXTERNAL_IP"
```

**Expected output:**
```
Application URL: http://104.154.201.227
```

### Verify Core Application Endpoints

Test each of your application's endpoints to ensure functionality is preserved:

```bash
# Test the root endpoint
curl http://$EXTERNAL_IP/
```

**Expected response:**
```json
{"environment":"production","message":"Welcome to sre-demo-app!","status":"healthy","timestamp":1757129349.4376614,"version":"1.0.0"}
```

```bash
# Test the stores endpoint
curl http://$EXTERNAL_IP/stores
```

**Expected response:**
```json
{"processing_time":0.58,"stores":[{"id":1,"items":[{"id":1,"name":"Kubernetes Cluster","price":299.99,"stock":5},{"id":2,"name":"Prometheus Monitoring","price":149.99,"stock":12}],"location":"us-central1","name":"Cloud SRE Store"},{"id":2,"items":[{"id":3,"name":"CI/CD Pipeline","price":199.99,"stock":8},{"id":4,"name":"Container Registry","price":99.99,"stock":15}],"location":"us-east1","name":"DevOps Marketplace"}],"total_stores":2}
```

```bash
# Test the health endpoint
curl http://$EXTERNAL_IP/health
```

**Expected response:**
```json
{"status":"ready","timestamp":1757129361.0311575}
```

**What this proves:** All endpoints function identically to Exercise 1 and 2, demonstrating that Kubernetes deployment adds orchestration without breaking application functionality.

### Test Load Distribution

Verify that traffic is distributed across your pod replicas:

```bash
# Test error handling and load distribution
for i in {1..10}; do
  curl -s http://$EXTERNAL_IP/stores | grep -E "(processing_time)"
done
```

**Expected output pattern:**
```json
{"processing_time":0.286,"stores":[...]
{"processing_time":0.382,"stores":[...]
{"processing_time":0.234,"stores":[...]
```

**Load balancing analysis:** Different `processing_time` values and potentially different response patterns indicate requests are being distributed across multiple pod replicas. This demonstrates that the LoadBalancer service is effectively distributing traffic.

---

## Step 10: Verify Prometheus Metrics Integration

This step ensures your observability data remains accessible for monitoring system integration in the distributed Kubernetes environment.

### Check Metrics Endpoint Functionality

Verify that your Prometheus metrics are accessible and properly formatted:

```bash
# Check metrics endpoint
curl -s http://$EXTERNAL_IP/metrics | grep -E "(http_requests_total|business_operations)"
```

**Expected output:**
```
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{endpoint="ready_check",method="GET",status="200"} 217.0
http_requests_total{endpoint="index",method="GET",status="200"} 1.0
http_requests_total{endpoint="get_stores",method="GET",status="200"} 7.0
```

**Metrics analysis:**
- **ready_check**: High count (217) shows Kubernetes health checks working
- **index**: Low count (1) shows minimal external access to root endpoint
- **get_stores**: Moderate count (7) reflects your testing activity

**Business vs Infrastructure metrics:** Your application exposes both user-facing business metrics (store operations) and infrastructure metrics (request counts, durations) needed for comprehensive SRE monitoring.

### Verify Automatic Discovery Annotations

Check that your pods have the correct annotations for monitoring system discovery:

```bash
# Verify pod-level metrics annotations
kubectl get pods -l app=sre-demo-app -o jsonpath='{.items[0].metadata.annotations}'
```

**Expected output:**
```json
{"kubectl.kubernetes.io/restartedAt":"2025-09-06T02:37:08Z","prometheus.io/path":"/metrics","prometheus.io/port":"8080","prometheus.io/scrape":"true"}
```

```bash
# Check service monitoring annotations
kubectl get service sre-demo-headless -o jsonpath='{.metadata.annotations}'
```

**Expected output includes:**
```json
{"prometheus.io/path":"/metrics","prometheus.io/port":"8080","prometheus.io/scrape":"true"...}
```

**Annotation purposes:**
- **prometheus.io/scrape: "true"**: Tells monitoring systems to collect metrics from this resource
- **prometheus.io/port: "8080"**: Specifies which port to scrape metrics from
- **prometheus.io/path: "/metrics"**: Defines the metrics endpoint path

**Why two services:** The headless service provides direct pod access for monitoring, while the LoadBalancer service handles user traffic. This separation ensures monitoring can collect metrics even during service disruptions.

---

## Step 11: Examine Application Logs in Kubernetes

This step validates that structured logging integrates properly with Kubernetes logging infrastructure, enabling effective troubleshooting and operational analysis.

### View Aggregated Application Logs

Check your application's structured logs across all pod replicas:

```bash
# View application logs
kubectl logs -l app=sre-demo-app --tail=50
```

**Expected log pattern:**
```json
2025-09-06 03:29:21,975 - __main__ - INFO - Response: {"timestamp": "2025-09-06T03:29:21.975386", "method": "GET", "path": "/ready", "status_code": 200, "duration_ms": 0.21}
2025-09-06 03:29:26,881 - __main__ - INFO - Request: {"timestamp": "2025-09-06T03:29:26.881003", "method": "GET", "path": "/metrics", "remote_addr": "74.249.85.192", "user_agent": "curl/8.5.0"}
2025-09-06 03:29:29,150 - __main__ - INFO - Request: {"timestamp": "2025-09-06T03:29:29.150893", "method": "GET", "path": "/health", "remote_addr": "10.116.128.1", "user_agent": "kube-probe/1.33"}
```

**Log analysis insights:**
- **Health check traffic**: `remote_addr: "10.116.128.1"` with `user_agent: "kube-probe/1.33"` shows Kubernetes health checks
- **External traffic**: `remote_addr: "74.249.85.192"` with `user_agent: "curl/8.5.0"` shows your testing requests
- **Structured format**: JSON-structured logs enable easy parsing by log aggregation systems

### Monitor Logs in Real-Time

Watch logs as they're generated to understand traffic patterns:

```bash
# Follow logs in real-time
kubectl logs -l app=sre-demo-app -f
```

**What you'll observe:**
```json
2025-09-06 03:30:01,975 - __main__ - INFO - Request: {"timestamp": "2025-09-06T03:30:01.974932", "method": "GET", "path": "/ready", "remote_addr": "10.116.128.1", "user_agent": "kube-probe/1.33"}
2025-09-06 03:30:09,150 - __main__ - INFO - Request: {"timestamp": "2025-09-06T03:30:09.150373", "method": "GET", "path": "/health", "remote_addr": "10.116.128.1", "user_agent": "kube-probe/1.33"}
```

**Traffic patterns:**
- **Readiness probes**: Every 5 seconds (`/ready` endpoint)
- **Liveness probes**: Every 10 seconds (`/health` endpoint)
- **Dual pod logging**: Logs from both pod replicas are aggregated into a single stream

### Generate Traffic and Observe Correlation

Create application activity and watch the corresponding log entries:

```bash
# Generate some traffic and observe logs
for i in {1..5}; do
  curl -s http://$EXTERNAL_IP/ > /dev/null
  curl -s http://$EXTERNAL_IP/stores > /dev/null
  sleep 1
done
```

**Expected log correlation:** After running this command, you should see new log entries in your real-time log stream showing the request/response pairs for both the root endpoint and stores endpoint, with external IP addresses and curl user agents.

**SRE value:** This correlation between actions and logs demonstrates how structured logging in Kubernetes enables effective troubleshooting during incidents. The combination of timestamps, request IDs, and pod identification provides the context needed for root cause analysis in distributed systems.

### Understanding Log Aggregation

**Multi-pod aggregation:** The `kubectl logs -l app=sre-demo-app` command automatically aggregates logs from all pods matching the label selector. This provides a unified view of your application's behavior across replicas.

**Kubernetes metadata:** Each log entry includes implicit context about which pod generated it, enabling you to correlate logs with specific infrastructure events or pod failures.

**Production considerations:** In production environments, these logs would typically be forwarded to centralized logging systems (like Google Cloud Logging, ELK stack, or Splunk) where they can be indexed, searched, and correlated with metrics for comprehensive observability.

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

### Step 15: Clean Up Your Container Images

To avoid incurring storage costs, it's a best practice to delete the container images you no longer need. The images you pushed to Artifact Registry in this exercise are no longer required for the course.

Run the following command to delete all images in your repository. This process can take a few minutes.

```bash
# Get the digest of the parent manifest list and delete it first
PARENT_DIGEST=$(gcloud artifacts docker images list us-central1-docker.pkg.dev/gcp-sre-lab/sre-demo-app \
  --format="value(DIGEST)" | grep -v 'None' | tail -n 1)

gcloud artifacts docker images delete us-central1-docker.pkg.dev/gcp-sre-lab/sre-demo-app/sre-demo-app@${PARENT_DIGEST} --delete-tags --quiet

# Then, run a loop to delete all remaining child images
gcloud artifacts docker images list us-central1-docker.pkg.dev/gcp-sre-lab/sre-demo-app \
  --format="value(IMAGE,DIGEST)" | while read -r image digest; do
    gcloud artifacts docker images delete "${image}@${digest}" --delete-tags --quiet
done
```

Once the command completes, you can verify that the registry is empty:

```bash
gcloud artifacts docker images list us-central1-docker.pkg.dev/gcp-sre-lab/sre-demo-app
```

**Expected Output:**

```
Listing items under project gcp-sre-lab, location us-central1, repository sre-demo-app.

Listed 0 items.
```

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