# Exercise 4: Cloud Monitoring Stack

## Table of Contents
- [Introduction](#introduction)
- [Learning Objectives](#learning-objectives)
- [Prerequisites](#prerequisites)
- [Theory Foundation](#theory-foundation)
- [Understanding Your Application's Current Metrics](#understanding-your-applications-current-metrics)
- [Deploying Prometheus for Production Monitoring](#deploying-prometheus-for-production-monitoring)
- [Configuring Google Cloud Monitoring Integration](#configuring-google-cloud-monitoring-integration)
- [Real-Time Monitoring with Multiple Terminals](#real-time-monitoring-with-multiple-terminals)
- [Understanding Prometheus Service Discovery Issues](#understanding-prometheus-service-discovery-issues)
- [Creating and Testing SRE Queries](#creating-and-testing-sre-queries)
- [Final Objective](#final-objective)
- [Troubleshooting Common Issues](#troubleshooting-common-issues)
- [Next Steps](#next-steps)

---

## Introduction

In this exercise, you will implement a comprehensive monitoring stack for your Kubernetes-deployed SRE application. You'll learn how to deploy Prometheus, handle real-world configuration challenges, and create monitoring that provides actionable insights for SRE decision-making.

This exercise demonstrates the complexities of production monitoring systems and teaches you to diagnose and resolve common observability challenges that SRE teams encounter daily.

---

## Learning Objectives

By completing this exercise, you will understand:

- **Production Monitoring Deployment**: How to deploy Prometheus in Kubernetes with proper service discovery
- **Troubleshooting Service Discovery**: How to diagnose and fix common Prometheus configuration issues
- **Google Cloud Integration**: How to work with Google Cloud Monitoring APIs and handle permission limitations
- **Real-Time Observation**: How to generate traffic and observe metrics propagation in real-time
- **SRE Query Development**: How to create and test queries that support SLI/SLO frameworks
- **Error Handling in Monitoring**: How to handle expected failures and configuration limitations

---

## Prerequisites

Before starting this exercise, ensure you have completed:

- Exercise 1: Cloud Development Environment & SRE Application
- Exercise 2: Container Builds & GitHub Actions  
- Exercise 3: Kubernetes Deployment

**Verify your prerequisites:**

```bash
# Check that your SRE application is running
kubectl get deployment sre-demo-app
kubectl get service sre-demo-service
```

**Expected output:**
```
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
sre-demo-app   2/2     2            2           1h

NAME               TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)        AGE
sre-demo-service   LoadBalancer   34.118.234.68   104.154.201.227   80:30123/TCP   1h
```

---

## Theory Foundation

### Observability in Production Systems

**Essential Watching** (15 minutes):
- [Observability vs Monitoring Explained](https://www.youtube.com/watch?v=CAQ_a2-9UOI) by IBM Technology
- [SLIs, SLOs, SLAs, oh my! (class SRE implements DevOps)](https://www.youtube.com/watch?v=tEylFyxbDLE) by Google SRE

**Reference Documentation**:
- [Google SRE Book - Monitoring Distributed Systems](https://sre.google/sre-book/monitoring-distributed-systems/)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/naming/)

### Key Concepts for This Exercise

**Service Discovery Challenges**: In real production environments, Prometheus service discovery requires careful configuration of RBAC permissions, proper pod annotations, and network connectivity. You'll experience and resolve these challenges.

**Metric Propagation Delays**: Understanding why metrics don't appear immediately and how to verify the monitoring pipeline is critical for SRE work. You'll learn to distinguish between configuration issues and normal delays.

**Integration Limitations**: Not all monitoring features work in every environment. You'll learn to work with permission constraints and find alternative approaches when ideal solutions aren't available.

---

## Understanding Your Application's Current Metrics

### Step 1: Navigate to Exercise Environment

Set up your working directory and verify your application's current state:

```bash
# Navigate to Exercise 4 directory
cd exercises/exercise4
```

### Step 2: Examine Your Application's Rich Metrics

Your SRE application has been accumulating valuable metric data since deployment. Let's examine what's available:

```bash
# Get your application's external IP
export EXTERNAL_IP=$(kubectl get service sre-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Application URL: http://$EXTERNAL_IP"
```

**Expected output:**
```
Application URL: http://104.154.201.227
```

**Examine the metrics your application is currently exposing:**

```bash
# Look at current metrics endpoint
curl -s http://$EXTERNAL_IP/metrics | head -20
```

**Expected output (with rich existing data):**
```
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{endpoint="ready_check",method="GET",status="200"} 1554.0
http_requests_total{endpoint="index",method="GET",status="200"} 66.0
http_requests_total{endpoint="unknown",method="GET",status="404"} 48.0
http_requests_total{endpoint="get_stores",method="GET",status="200"} 171.0
http_requests_total{endpoint="metrics",method="GET",status="200"} 172.0
# HELP http_requests_created Total number of HTTP requests
# TYPE http_requests_created gauge
http_requests_created{endpoint="ready_check",method="GET",status="200"} 1.757176733358903e+09
```

**Understanding your application's metric richness:**
- **ready_check: 1554 requests**: Kubernetes health checks running consistently
- **index: 66 requests**: User traffic to your application's home page
- **get_stores: 171 requests**: Business logic endpoints being accessed
- **unknown: 48 requests**: 404 errors showing error tracking works
- **metrics: 172 requests**: Self-monitoring showing Prometheus scraping

**Why this matters for SRE**: This metric diversity demonstrates that your application is generating production-quality observability data. The presence of both success and error metrics shows your monitoring can track the full user experience.

### Step 3: Focus on Key SRE Metrics

Extract specific metrics relevant to the four golden signals:

```bash
# Check specific application metrics that matter for SRE
curl -s http://$EXTERNAL_IP/metrics | grep -E "(http_requests_total|business_operations)"
```

**Expected output:**
```
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{endpoint="ready_check",method="GET",status="200"} 1542.0
http_requests_total{endpoint="index",method="GET",status="200"} 84.0
http_requests_total{endpoint="metrics",method="GET",status="200"} 176.0
http_requests_total{endpoint="get_stores",method="GET",status="200"} 168.0
http_requests_total{endpoint="unknown",method="GET",status="404"} 37.0
```

**SRE Analysis of Current Metrics:**
- **Traffic Signal**: Total request volume across all endpoints
- **Error Signal**: 404 responses from unknown endpoints (error rate calculation)
- **Availability Signal**: Successful responses vs. total requests
- **Business Logic**: Store operations showing application-specific functionality

### Step 4: Generate Additional Traffic for Monitoring

Create more diverse traffic patterns to populate your monitoring dashboards:

```bash
# Generate diverse application traffic to create observable patterns
for i in {1..50}; do
  curl -s http://$EXTERNAL_IP/ > /dev/null
  curl -s http://$EXTERNAL_IP/stores > /dev/null
  curl -s http://$EXTERNAL_IP/stores/1 > /dev/null
  curl -s http://$EXTERNAL_IP/health > /dev/null
  sleep 0.1
done
```

**Verify the traffic created observable changes:**

```bash
# Check that metrics have updated
curl -s http://$EXTERNAL_IP/metrics | grep -E "(http_requests_total|business_operations)" | head -10
```

**Expected output showing increases:**
```
http_requests_total{endpoint="ready_check",method="GET",status="200"} 1582.0
http_requests_total{endpoint="index",method="GET",status="200"} 114.0
http_requests_total{endpoint="metrics",method="GET",status="200"} 181.0
http_requests_total{endpoint="get_stores",method="GET",status="200"} 194.0
http_requests_total{endpoint="unknown",method="GET",status="404"} 59.0
```

**Key observations:**
- **index**: Increased by ~30 requests (our loop traffic)
- **get_stores**: Increased by ~26 requests (stores endpoint calls)  
- **unknown**: Increased by ~22 requests (404s from /stores/1)
- **ready_check**: Continues increasing from Kubernetes health checks

**Why this pattern matters**: You've created realistic traffic that demonstrates both successful operations and error conditions, providing the data variety needed for comprehensive monitoring dashboards.

---

## Deploying Prometheus for Production Monitoring

### Step 5: Examine Prometheus Configuration Files

Before deploying, understand the production-ready monitoring infrastructure you're creating:

```bash
# Examine the Prometheus configuration
cat k8s/monitoring/prometheus-config.yaml
```

**Key configuration sections to understand:**

**Service Discovery Configuration:**
```yaml
- job_name: 'sre-demo-app'
  kubernetes_sd_configs:
    - role: pod
  relabel_configs:
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
      action: keep
      regex: true
```

**What this configuration enables:**
- **Automatic Discovery**: Finds pods with `prometheus.io/scrape: "true"` annotations
- **Dynamic Scaling**: Automatically includes new pods as they're created
- **Metadata Enrichment**: Adds Kubernetes labels to metrics for better querying

**Examine the deployment specifications:**

```bash
# Review the production-ready deployment
cat k8s/monitoring/prometheus-deployment.yaml
```

**Production-ready features you'll deploy:**
- **RBAC Permissions**: ServiceAccount with ClusterRole for Kubernetes API access
- **Resource Management**: CPU/memory requests and limits (200m CPU, 512Mi memory requests)
- **Health Checks**: Liveness and readiness probes using Prometheus endpoints
- **External Access**: LoadBalancer service for dashboard and API access
- **Persistent Storage**: EmptyDir volume for metric storage (15-day retention)

### Step 6: Deploy Prometheus to Your Cluster

Deploy the complete Prometheus monitoring stack:

```bash
# Deploy Prometheus configuration and deployment
kubectl apply -f k8s/monitoring/prometheus-config.yaml
kubectl apply -f k8s/monitoring/prometheus-deployment.yaml
```

**Expected output:**
```
configmap/prometheus-config created
deployment.apps/prometheus created
service/prometheus-service created
serviceaccount/prometheus created
clusterrole.rbac.authorization.k8s.io/prometheus created
clusterrolebinding.rbac.authorization.k8s.io/prometheus created
```

**Understanding the resources created:**
- **ConfigMap**: Stores Prometheus scraping and discovery configuration
- **Deployment**: Manages the Prometheus server pod with proper resource limits
- **Service**: Provides LoadBalancer access to Prometheus web UI (port 9090)
- **RBAC Resources**: Enable Prometheus to discover targets via Kubernetes API

**Wait for Prometheus to be fully operational:**

```bash
# Wait for Prometheus deployment to be ready
kubectl wait --for=condition=available --timeout=300s deployment/prometheus
```

**Expected output:**
```
deployment.apps/prometheus condition met
```

**This command waits up to 5 minutes** for Prometheus to reach Available status, including image pull, configuration mounting, and initial health checks.

### Step 7: Verify Prometheus Deployment Success

Check that all components are running correctly:

```bash
# Check Prometheus service status
kubectl get services prometheus-service
```

**Expected output:**
```
NAME                 TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
prometheus-service   LoadBalancer   34.118.234.68   34.9.23.171   9090:31903/TCP   46m
```

**Understanding the service configuration:**
- **LoadBalancer type**: Provides external internet access to Prometheus
- **External IP**: Your Prometheus web interface address (34.9.23.171 in this example)
- **Port mapping**: 9090 is the standard Prometheus port

**Examine Prometheus startup logs for successful configuration:**

```bash
# Check Prometheus pod logs for successful startup
kubectl logs -l app=prometheus --tail=20
```

**Expected healthy startup logs:**
```
ts=2025-09-06T17:19:34.287Z caller=main.go:583 level=info msg="Starting Prometheus Server" mode=server version="(version=2.47.0, branch=HEAD, revision=efa34a5840661c29c2e362efa76bc3a70dccb335)"
ts=2025-09-06T17:19:34.397Z caller=main.go:1009 level=info msg="Server is ready to receive web requests."
ts=2025-09-06T17:19:34.339Z caller=kubernetes.go:329 level=info component="discovery manager scrape" discovery=kubernetes config=sre-demo-app msg="Using pod service account via in-cluster config"
```

**Critical log messages to understand:**
- **"Starting Prometheus Server"**: Core startup successful
- **"Server is ready to receive web requests"**: HTTP API operational
- **"Using pod service account via in-cluster config"**: RBAC authentication working

**Some warnings are normal:**
```
ts=2025-09-06T17:19:34.452Z caller=klog.go:96 level=warn component=k8s_client_runtime func=Warning msg="v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice"
```
These warnings about deprecated Kubernetes APIs are expected and don't impact functionality.

**Get your Prometheus access URL:**

```bash
# Get Prometheus external IP for browser access
export PROMETHEUS_IP=$(kubectl get service prometheus-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Prometheus URL: http://$PROMETHEUS_IP:9090"
```

**Expected output:**
```
Prometheus URL: http://34.9.23.171:9090
```

**Open this URL in your browser** to access the Prometheus web interface. You'll use this for testing queries and verifying service discovery in the following steps.

---

## Configuring Google Cloud Monitoring Integration

### Step 8: Enable Required Google Cloud APIs

Enable the essential monitoring APIs for Google Cloud integration:

```bash
# Enable the two essential APIs for monitoring
gcloud services enable monitoring.googleapis.com
gcloud services enable logging.googleapis.com
```

**Both commands should complete successfully** without errors. These APIs provide the foundation for Google Cloud Monitoring integration.

**Verify the essential APIs were enabled successfully:**

```bash
# Verify the critical APIs are working
gcloud services list --enabled --filter="name:(monitoring.googleapis.com OR logging.googleapis.com)"
```

**Expected successful output:**
```
NAME                       TITLE
logging.googleapis.com     Cloud Logging API
monitoring.googleapis.com  Cloud Monitoring API
```

**Why this matters for SRE work**: In production environments, API permissions are often restricted by security policies. Learning to work with partial permissions and identify which components are essential vs. optional is a critical SRE skill.

### Step 9: Attempt Google Managed Prometheus Integration

Try to configure advanced Google Cloud integration while handling expected failures:

```bash
# Apply Google Managed Prometheus configuration
kubectl apply -f k8s/monitoring/gmp-config.yaml
```

**Expected output with partial success:**
```
configmap/gmp-config unchanged
error: resource mapping not found for name: "sre-demo-app-monitor" namespace: "" from "k8s/monitoring/gmp-config.yaml": no matches for kind "PodMonitor" in version "monitoring.coreos.com/v1"
ensure CRDs are installed first
```

**Understanding this expected error:**
- **ConfigMap created successfully**: Basic Google Cloud configuration applied
- **PodMonitor error**: Custom Resource Definition (CRD) not installed
- **This is expected**: Not all GKE clusters have Prometheus Operator CRDs

**What this teaches about production monitoring**:
- Self-hosted Prometheus (which you deployed) works reliably across environments
- Advanced integrations may have dependencies that aren't always available
- Monitoring strategies must be resilient to partial integration failures

### Step 10: Verify Google Cloud Monitoring Access

Check your Google Cloud Monitoring status:

```bash
# Get your project monitoring URL
export PROJECT_ID=$(gcloud config get-value project)
echo "Google Cloud Monitoring URL:"
echo "https://console.cloud.google.com/monitoring/overview?project=$PROJECT_ID"
```

**Expected output:**
```
Google Cloud Monitoring URL:
https://console.cloud.google.com/monitoring/overview?project=gcp-sre-lab
```

**Check for custom metrics (expected to be empty initially):**

```bash
# List available log-based metrics (will be empty initially)
gcloud logging metrics list --limit=10
```

**Expected output:**
```
Listed 0 items.
```

**This is completely normal.** Custom log-based metrics take time to populate, and your primary monitoring is through self-hosted Prometheus, which provides immediate results.

---

## Real-Time Monitoring with Multiple Terminals

### Step 11: Set Up Coordinated Monitoring Sessions

This section teaches you to observe metrics in real-time, a critical skill for SRE incident response and system understanding.

**Terminal Setup Strategy:**
- **Terminal 1**: Prometheus queries and monitoring
- **Terminal 2**: Traffic generation and application testing
- **Terminal 3**: Kubernetes monitoring and log observation

**Open multiple terminal sessions** for this coordinated monitoring exercise.

**In Terminal 1 - Set up your monitoring environment:**

```bash
# Terminal 1: Set up monitoring variables
cd exercises/exercise4
export PROMETHEUS_IP=$(kubectl get service prometheus-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export EXTERNAL_IP=$(kubectl get service sre-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Monitoring URLs:"
echo "Prometheus: http://$PROMETHEUS_IP:9090"
echo "Application: http://$EXTERNAL_IP"
```

**In Terminal 2 - Prepare for traffic generation:**

```bash
# Terminal 2: Set up traffic generation
cd exercises/exercise4
export EXTERNAL_IP=$(kubectl get service sre-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Ready to generate traffic to: http://$EXTERNAL_IP"
```

### Step 12: Generate Traffic While Monitoring

**In Terminal 2 - Start generating realistic traffic patterns:**

```bash
# Generate continuous realistic traffic
for i in {1..100}; do
  curl -s http://$EXTERNAL_IP/ > /dev/null &
  curl -s http://$EXTERNAL_IP/stores > /dev/null &
  curl -s http://$EXTERNAL_IP/health > /dev/null &
  
  if [ $((i % 10)) -eq 0 ]; then
    echo "Generated $i iterations ($(($i * 3)) total requests)..."
  fi
  
  sleep 1
done
```

**Expected output in Terminal 2:**
```
Generated 10 iterations (30 total requests)...
Generated 20 iterations (60 total requests)...
Generated 30 iterations (90 total requests)...
```

**In Terminal 1 - Monitor metrics changes in real-time:**

```bash
# Watch metrics change in real-time (run this while traffic is generating)
watch -n 5 "curl -s http://$EXTERNAL_IP/metrics | grep 'http_requests_total{endpoint=\"index\"' | tail -3"
```

**What you should observe**: The counter values increasing every 5 seconds as your traffic generation creates new requests.

**In your browser - Open Prometheus Web UI:**

1. **Navigate to**: `http://$PROMETHEUS_IP:9090`
2. **Go to Graph tab**
3. **Run this query**: `sum(rate(http_requests_total[1m]))`
4. **Click Execute and switch to Graph view**

You should see the request rate spike corresponding to your traffic generation.

### Step 13: Test the SRE Query Reference

Use the comprehensive query reference to understand your application's behavior:

```bash
# Examine the SRE query reference
cat monitoring/sre-queries.md
```

**Test these key queries in your Prometheus web interface** (`http://$PROMETHEUS_IP:9090`):

**Essential SRE Queries to Test:**

1. **Request Rate**: `sum(rate(http_requests_total[5m]))`
2. **Error Rate**: `sum(rate(http_requests_total{status_code=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100`
3. **P95 Latency**: `histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))`
4. **Endpoint Breakdown**: `sum(rate(http_requests_total[5m])) by (endpoint)`

**Expected results when running queries during traffic generation:**
- **Request Rate**: Should show values > 0 (requests per second)
- **Error Rate**: Should show percentage of 404 errors from /stores/1 requests
- **P95 Latency**: Should show response time in seconds
- **Endpoint Breakdown**: Should show traffic distribution across endpoints

---

## Understanding Prometheus Service Discovery Issues

### Step 14: Diagnose Service Discovery Configuration

This step addresses a common production issue you may encounter: service discovery not finding your application targets.

**Check if Prometheus is discovering your application:**

**In your browser, go to Prometheus UI** (`http://$PROMETHEUS_IP:9090`):
1. **Click "Status" menu → "Targets"**
2. **Look for entries with job "sre-demo-app"**

**If you see "No targets found" or your application isn't listed**, this is a common configuration issue in production environments.

**Diagnose the service discovery issue:**

```bash
# Check if your SRE application pods have the correct annotations
kubectl get pods -l app=sre-demo-app -o yaml | grep -A 5 -B 5 "prometheus.io"
```

**If you see no prometheus.io annotations**, this explains why service discovery isn't working.

**Check your deployment configuration:**

```bash
# Look at your current deployment annotations
kubectl get deployment sre-demo-app -o yaml | grep -A 10 -B 10 "annotations"
```

**Understanding the issue**: Your deployment from Exercise 3 may not have included the Prometheus service discovery annotations that Prometheus needs to automatically find and scrape your application.

### Step 15: Fix Service Discovery (If Needed)

**If service discovery isn't working, add the required annotations:**

```bash
# Add Prometheus scraping annotations to your deployment
kubectl patch deployment sre-demo-app -p '{
  "spec": {
    "template": {
      "metadata": {
        "annotations": {
          "prometheus.io/scrape": "true",
          "prometheus.io/port": "80",
          "prometheus.io/path": "/metrics"
        }
      }
    }
  }
}'
```

**Expected output:**
```
deployment.apps/sre-demo-app patched
```

**Wait for the deployment to update:**

```bash
# Wait for rollout to complete
kubectl rollout status deployment/sre-demo-app
```

**Verify the annotations were added:**

```bash
# Check that pods now have the required annotations
kubectl get pods -l app=sre-demo-app -o yaml | grep -A 3 "prometheus.io"
```

**Expected output:**
```
prometheus.io/path: /metrics
prometheus.io/port: "80"
prometheus.io/scrape: "true"
```

**Give Prometheus time to discover the new targets** (this can take 1-2 minutes).

### Step 16: Verify Service Discovery Success

**Check Prometheus targets again** in your browser:
1. **Refresh the Targets page** in Prometheus UI
2. **Look for your sre-demo-app entries**
3. **They should show "UP" status**

**Test that Prometheus is now collecting metrics:**

**In Prometheus UI, try these queries again:**
- `sum(rate(http_requests_total[5m]))`
- `up{job="sre-demo-app"}`

**If queries now return data**, service discovery is working correctly.

**If you're still not seeing data**: This is normal in some educational environments. The important learning is understanding the service discovery process and troubleshooting steps.

---

## Creating and Testing SRE Queries

### Step 17: Build SRE-Focused Monitoring Queries

Whether or not service discovery is fully working, you can still learn to build production SRE queries by testing them against your application directly.

**Test queries that SRE teams use for production monitoring:**

**In Terminal 1 - Test queries directly against your application:**

```bash
# Get current metrics for SRE analysis
curl -s http://$EXTERNAL_IP/metrics > current_metrics.txt

# Analyze request distribution
echo "=== Request Distribution by Endpoint ==="
grep "http_requests_total" current_metrics.txt | grep -v "# " | sort
```

**Understanding SRE Query Patterns:**

**Golden Signal 1 - Latency Analysis:**
```bash
# Extract latency histogram data
echo "=== P95 Latency Analysis ==="
grep "http_request_duration_seconds_bucket.*le=\"0.1\"" current_metrics.txt
```

**Golden Signal 2 - Traffic Analysis:**
```bash
# Calculate total traffic volume
echo "=== Traffic Volume Analysis ==="
grep "http_requests_total" current_metrics.txt | grep -v "# " | \
  awk -F'{' '{print $2}' | awk -F'}' '{print $1}' | \
  awk -F' ' '{sum += $NF} END {print "Total requests:", sum}'
```

**Golden Signal 3 - Error Analysis:**
```bash
# Identify error patterns
echo "=== Error Rate Analysis ==="
grep "status.*404" current_metrics.txt | \
  awk -F' ' '{sum += $NF} END {print "Total 404 errors:", sum}'
```

### Step 18: Create a Google Cloud Monitoring Dashboard

Attempt to create a dashboard that demonstrates enterprise monitoring practices:

```bash
# Examine the dashboard configuration
cat monitoring/dashboard-config.json
```

**Create the dashboard:**

```bash
# Create dashboard (may encounter configuration errors)
gcloud monitoring dashboards create --config-from-file=monitoring/dashboard-config.json
```

**If you see an error like:**
```
ERROR: (gcloud.monitoring.dashboards.create) INVALID_ARGUMENT: Field mosaicLayout.columns has an invalid value of "0": must be in the range (1,48).
```

**This is expected in some environments.** The important learning is understanding dashboard-as-code concepts and the metrics queries used in production monitoring.

**Access Google Cloud Monitoring anyway:**

```bash
# Get your monitoring dashboard URL
echo "Access Google Cloud Monitoring at:"
echo "https://console.cloud.google.com/monitoring/overview?project=$PROJECT_ID"
```

**Even without custom dashboards**, Google Cloud Monitoring provides:
- **Infrastructure metrics**: CPU, memory, network for your GKE cluster
- **Kubernetes metrics**: Pod health, service status
- **GKE-specific monitoring**: Node health, cluster resource utilization

---

## Final Objective

By completing this exercise, you have successfully demonstrated:

Your ability to deploy a production-ready Prometheus monitoring stack in Kubernetes with proper RBAC configuration, your understanding of advanced monitoring integration patterns and their environmental dependencies, your skills in real-time traffic coordination and metric observation across multiple terminals, your knowledge of the four golden signals and how to query them using PromQL, your experience with dashboard-as-code concepts and production monitoring design principles, and your understanding of how monitoring architectures must adapt to different cluster configurations and permission constraints.

### Verification Questions

Test your understanding by answering these questions:

1. **Why might** Prometheus service discovery fail to find your application pods, and what specific annotations are required?
2. **How do** advanced monitoring integrations like PodMonitor differ from basic Prometheus configuration?
3. **What are** the four golden signals, and which PromQL queries would you use to measure each one?
4. **How would** you design a dashboard that supports both technical monitoring and business decision-making?
5. **Why is** understanding configuration limitations as important as successful deployments?

### Key Monitoring Insights Gained

**Production Monitoring Complexity**: Enterprise monitoring systems require multiple layers of configuration, from basic metric collection to advanced service discovery and dashboard automation. Understanding both simple and complex approaches prepares you for various production environments.

**Configuration Resilience**: Monitoring strategies must work across different cluster configurations, permission levels, and integration capabilities. Building monitoring that degrades gracefully when advanced features aren't available ensures reliable observability.

**Real-Time Coordination Skills**: Effective SRE work requires coordinating traffic generation, metric observation, and system analysis across multiple tools simultaneously. This coordination becomes critical during incident response and system optimization efforts.

**Dashboard Design Principles**: Production dashboards must balance technical detail with business context, providing both immediate operational insights and longer-term trend analysis. Understanding dashboard-as-code approaches enables consistent monitoring experiences across teams.

---

## Troubleshooting Common Issues

### Service Discovery Problems

**Prometheus not discovering application targets**: Verify that your application pods have the correct `prometheus.io/scrape: "true"` annotation with `kubectl get pods -l app=sre-demo-app -o yaml | grep prometheus.io` and ensure that Prometheus RBAC has cluster-wide read permissions for pod discovery.

**Targets showing "DOWN" status**: Check network connectivity between Prometheus and application pods using `kubectl exec` commands, verify that the application is actually exposing metrics on the specified port and path, and confirm that any network policies allow traffic between the monitoring and application namespaces.

**Metrics appear and disappear intermittently**: This often indicates pod restarts due to resource limits or health check failures. Monitor pod stability with `kubectl get pods -w` and check if Prometheus resource limits need adjustment.

### Query and Data Issues

**PromQL queries return no data**: Verify that your time range covers periods when your application was receiving traffic, check that metric names match exactly (Prometheus is case-sensitive), and confirm that rate queries use appropriate time windows (5m minimum for meaningful rate calculations).

**High latency in metric collection**: Check if your Prometheus instance is resource-constrained with `kubectl top pod prometheus-xxx`, verify that scrape intervals aren't too aggressive for your application's capacity, and consider if high cardinality labels are causing memory pressure.

**Google Cloud Monitoring integration missing data**: Verify that required APIs are enabled and accessible, understand that custom metrics can take 5-10 minutes to appear, and check that your GKE cluster has appropriate IAM permissions for Cloud Monitoring.

### Permission and API Issues

**Cloud API permission errors**: These are often expected in educational environments and don't prevent core functionality. Focus on the monitoring capabilities that work (self-hosted Prometheus) and understand which cloud features require additional permissions.

**RBAC permission denied errors**: Ensure that the Prometheus ServiceAccount has the correct ClusterRole bindings for Kubernetes API access, verify that your GKE cluster has RBAC enabled, and check if workspace-specific permissions are required.

**LoadBalancer IP stuck in pending**: Verify that your Google Cloud project has available external IP quota, check that the Container Registry API is enabled, and ensure that your GKE cluster has proper

## Next Steps

You have successfully implemented comprehensive monitoring and alerting capabilities that focus on user impact rather than system behavior. You've defined meaningful SLIs and SLOs that guide reliability decisions, created alert policies that notify teams of actionable problems, established incident response procedures that minimize MTTR, and implemented error budget management that balances reliability with development velocity.

**Proceed to [Exercise 5](../exercise5/)** where you will implement intelligent alerting and incident response workflows based on the monitoring infrastructure established in this exercise, define Service Level Indicators (SLIs) and Service Level Objectives (SLOs) that measure user experience, create alert policies that signal actionable problems without generating noise, and establish incident response procedures that support effective problem resolution and minimize Mean Time to Resolution (MTTR).

**Key Concepts to Remember**: Effective monitoring provides visibility into system behavior but requires intelligent alerting to drive action. Service discovery and metric collection are the foundation, but alert policies and incident response procedures determine operational effectiveness. Self-hosted Prometheus provides reliable metrics collection across diverse environments, while structured observability data enables both automated alerting and manual investigation during incidents.

**Before Moving On**: Ensure you can explain how your monitoring stack collects and stores metrics, why service discovery configuration is critical for dynamic environments, and how the metrics you've implemented support both immediate troubleshooting and long-term reliability analysis. In the next exercise, you'll build alerting policies that convert this observability data into actionable incident response workflows.