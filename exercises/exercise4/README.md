# Exercise 4: Cloud Monitoring Stack

## Table of Contents
- [Introduction](#introduction)
- [Learning Objectives](#learning-objectives)
- [Prerequisites](#prerequisites)
- [Theory Foundation](#theory-foundation)
- [Understanding Observability in Kubernetes](#understanding-observability-in-kubernetes)
- [Configuring Application Metrics for Production](#configuring-application-metrics-for-production)
- [Deploying Prometheus to GKE](#deploying-prometheus-to-gke)
- [Integrating with Google Cloud Monitoring](#integrating-with-google-cloud-monitoring)
- [Creating Custom Dashboards and Visualizations](#creating-custom-dashboards-and-visualizations)
- [Implementing SRE Monitoring Best Practices](#implementing-sre-monitoring-best-practices)
- [Final Objective](#final-objective)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)

---

## Introduction

In this exercise, you will implement a comprehensive monitoring stack for your Kubernetes-deployed SRE application. You'll configure Prometheus to collect metrics from your application, integrate with Google Cloud Monitoring for unified observability, and create custom dashboards that provide actionable insights for SRE decision-making.

This exercise demonstrates how modern SRE teams build monitoring systems that provide visibility into both application performance and business metrics, enabling proactive incident response and data-driven optimization decisions.

---

## Learning Objectives

By completing this exercise, you will understand:

- **Application Metrics Configuration**: How to optimize Prometheus metrics for production monitoring
- **Prometheus Deployment**: How to deploy and configure Prometheus in Kubernetes environments
- **Google Cloud Monitoring Integration**: How to leverage managed monitoring services for comprehensive observability
- **Custom Dashboard Creation**: How to build dashboards that provide actionable SRE insights
- **Monitoring Strategy**: How to implement monitoring that supports SLI/SLO frameworks
- **Alert Foundation**: How to prepare monitoring data for intelligent alerting systems

---

## Prerequisites

Before starting this exercise, ensure you have completed:

- Exercise 1: Cloud Development Environment & SRE Application
- Exercise 2: Container Builds & GitHub Actions
- Exercise 3: Kubernetes Deployment
- Successfully deployed SRE application running on GKE
- Understanding of your application's existing Prometheus metrics endpoints

Note: This exercise builds directly on the observability features implemented in previous exercises.

---

## Theory Foundation

### Observability vs. Monitoring

**Essential Watching** (15 minutes):
- [Observability vs Monitoring Explained](https://www.youtube.com/watch?v=CAQ_a2-9UOI) by Honeycomb - Understanding the fundamental differences
- [The Three Pillars of Observability](https://www.youtube.com/watch?v=juP9VApKy_I) by Grafana - Metrics, logs, and traces

**Reference Documentation**:
- [Google SRE Book - Monitoring Distributed Systems](https://sre.google/sre-book/monitoring-distributed-systems/) - Foundational monitoring principles
- [Prometheus Best Practices](https://prometheus.io/docs/practices/naming/) - Metric naming and design patterns

### Prometheus and Cloud Monitoring

**Essential Watching** (20 minutes):
- [Prometheus in 100 Seconds](https://www.youtube.com/watch?v=h4Sl21AKiDg) by Fireship - Quick Prometheus overview
- [Google Cloud Monitoring Overview](https://www.youtube.com/watch?v=8UWChBiHRuY) by Google Cloud Tech - Managed monitoring capabilities

**Reference Documentation**:
- [Prometheus Operator Documentation](https://prometheus-operator.dev/docs/prologue/introduction/) - Kubernetes-native Prometheus deployment
- [Google Cloud Monitoring](https://cloud.google.com/monitoring/docs) - Complete managed monitoring platform

### Key Concepts You'll Learn

**Application Metrics Strategy** focuses on exposing business-relevant metrics that directly correlate with user experience and system reliability. Your Flask application already implements this through request counters, duration histograms, and business operation metrics.

**Prometheus Architecture** in Kubernetes environments uses service discovery to automatically find and scrape metrics from pods and services. This eliminates manual configuration while ensuring comprehensive metric collection across your entire application ecosystem.

**Cloud Monitoring Integration** provides unified visibility by combining Prometheus application metrics with Google Cloud infrastructure metrics, creating a single pane of glass for both application and platform observability.

---

## Understanding Observability in Kubernetes

Your SRE application has been exposing Prometheus metrics since Exercise 1, but running in Kubernetes provides additional opportunities for comprehensive observability that spans both application performance and infrastructure health.

### Current Monitoring Capabilities

Your deployed application already provides:
- **HTTP request metrics** (count, duration, status codes)
- **Business operation metrics** (store operations, success/failure rates)
- **Application health metrics** (connection counts, readiness status)
- **Infrastructure integration** through Kubernetes annotations for metric discovery

### Enhanced Monitoring Requirements

**Kubernetes-Native Observability** requires monitoring that understands pod lifecycles, service discovery, and resource utilization patterns. Your monitoring stack must automatically adapt as pods scale up and down.

**Multi-Layer Visibility** combines application metrics with Kubernetes infrastructure metrics (CPU, memory, network) and Google Cloud platform metrics (load balancer, persistent disk, network egress) for comprehensive system understanding.

**SRE-Focused Dashboards** translate raw metrics into business-relevant insights that support SLI measurement, SLO tracking, and informed incident response decisions.

---

## Configuring Application Metrics for Production

### Preparing the Data Layer

Before you can build a robust monitoring system, you must first ensure that the data you intend to monitor is correctly exposed and formatted. This section focuses on verifying that the SRE-instrumented application you deployed in the previous exercises is properly exposing its Prometheus metrics. This step is critical because it confirms the foundation of our observability stack is solid before we proceed with data collection.

## Step 1: Verify Current Metric Exposure

This step ensures that your SRE application is properly exposing Prometheus metrics in the Kubernetes environment. This verification is critical because it confirms the foundation of your observability stack is solid before you proceed with data collection infrastructure.

### Navigate to Exercise 4 Environment

Set up your working directory for the monitoring exercise:

```bash
# Navigate to Exercise 4 directory
cd exercises/exercise4
```

**Why this matters:** Exercise 4 contains all the monitoring configurations, dashboard definitions, and automation scripts needed to build your comprehensive observability stack.

### Verify Application Accessibility

Confirm your SRE application is accessible and ready for metrics collection:

```bash
# Get your application's external IP
export EXTERNAL_IP=$(kubectl get service sre-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Application URL: http://$EXTERNAL_IP"
```

**Expected output:**
```
Application URL: http://104.154.201.227
```

**What this tells you:** Your application has a stable external IP address from Exercise 3. This LoadBalancer service provides the consistent endpoint needed for both user traffic and monitoring system access.

### Examine Raw Metrics Output

Inspect the current metrics your application is exposing:

```bash
# Examine current metrics endpoint
curl -s http://$EXTERNAL_IP/metrics | head -20
```

**Expected output:**
```
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{endpoint="ready_check",method="GET",status="200"} 512.0
http_requests_total{endpoint="index",method="GET",status="200"} 2.0
# HELP http_requests_created Total number of HTTP requests
# TYPE http_requests_created gauge
http_requests_created{endpoint="ready_check",method="GET",status="200"} 1.7571767323129544e+09
http_requests_created{endpoint="index",method="GET",status="200"} 1.7571767542628462e+09
# HELP http_request_duration_seconds HTTP request duration in seconds
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{endpoint="ready_check",le="0.005",method="GET"} 512.0
http_request_duration_seconds_bucket{endpoint="ready_check",le="0.01",method="GET"} 512.0
http_request_duration_seconds_bucket{endpoint="ready_check",le="0.025",method="GET"} 512.0
http_request_duration_seconds_bucket{endpoint="ready_check",le="0.05",method="GET"} 512.0
http_request_duration_seconds_bucket{endpoint="ready_check",le="0.075",method="GET"} 512.0
http_request_duration_seconds_bucket{endpoint="ready_check",le="0.1",method="GET"} 512.0
http_request_duration_seconds_bucket{endpoint="ready_check",le="0.25",method="GET"} 512.0
http_request_duration_seconds_bucket{endpoint="ready_check",le="0.5",method="GET"} 512.0
http_request_duration_seconds_bucket{endpoint="ready_check",le="0.75",method="GET"} 512.0
http_request_duration_seconds_bucket{endpoint="ready_check",le="1.0",method="GET"} 512.0
```

**Understanding the output:**
- **HELP/TYPE comments**: Prometheus metadata describing each metric
- **Counter metrics**: `http_requests_total` shows monotonically increasing request counts
- **Histogram buckets**: `http_request_duration_seconds_bucket` provides latency distribution data
- **High ready_check count**: Shows Kubernetes health checks working (512 requests)
- **Low index count**: Shows minimal external traffic (2 requests)

**Why this format matters:** Prometheus metrics follow a specific text format that enables automatic parsing by monitoring systems. The label structure (`endpoint="ready_check"`) allows for powerful querying and aggregation.

### Focus on Key Application Metrics

Extract specific metrics relevant to SRE monitoring:

```bash
# Check specific application metrics
curl -s http://$EXTERNAL_IP/metrics | grep -E "(http_requests_total|business_operations)"
```

**Expected output:**
```
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{endpoint="ready_check",method="GET",status="200"} 514.0
http_requests_total{endpoint="index",method="GET",status="200"} 2.0
http_requests_total{endpoint="metrics",method="GET",status="200"} 1.0
```

**Key insights:**
- **ready_check**: Kubernetes liveness/readiness probes generating consistent traffic
- **index**: Root endpoint receiving minimal external requests
- **metrics**: Self-monitoring - the metrics endpoint being scraped
- **Missing business_operations**: No business metrics yet (will appear after Step 2)

**SRE significance:** These request counters form the foundation for calculating request rates, error rates, and availability metrics - three of the four golden signals of monitoring.

---

## Step 2: Generate Baseline Metrics Data

This step creates representative metric data to ensure your monitoring system has meaningful information to display. Without diverse traffic patterns, your dashboards and alerts would only show health check data, which doesn't reflect real user behavior.

### Confirm Application Endpoint

Ensure you have the correct application endpoint for traffic generation:

```bash
# Get the external IP of the app (re-run if you recreated the Service)
export EXTERNAL_IP=$(kubectl get service sre-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Application URL: http://$EXTERNAL_IP"
```

**Expected output:**
```
Application URL: http://104.154.201.227
```

**Why re-confirm:** Service recreation or cluster changes could affect IP addresses. Always verify connectivity before generating load.

### Generate Diverse Traffic Patterns

Create realistic user traffic to populate your metrics:

```bash
# Generate diverse application traffic (50 iterations)
for i in {1..50}; do
  curl -s http://$EXTERNAL_IP/ > /dev/null
  curl -s http://$EXTERNAL_IP/stores > /dev/null
  curl -s http://$EXTERNAL_IP/stores/1 > /dev/null
  curl -s http://$EXTERNAL_IP/health > /dev/null
  sleep 0.1
done
```

**What this does:** Sends 200 total requests (50 iterations × 4 endpoints) with consistent timing to generate observable metric data without overwhelming your application.

### Verify Metrics Population

Check that your traffic generation created observable metric changes:

```bash
# Verify metrics have updated (request and business counters)
curl -s http://$EXTERNAL_IP/metrics | grep -E "(http_requests_total|business_operations)" | head -10
```

**Expected output after traffic generation:**
```
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{endpoint="ready_check",method="GET",status="200"} 534.0
http_requests_total{endpoint="index",method="GET",status="200"} 11.0
http_requests_total{endpoint="metrics",method="GET",status="200"} 2.0
http_requests_total{endpoint="get_stores",method="GET",status="200"} 9.0
http_requests_total{endpoint="unknown",method="GET",status="404"} 3.0
```

**Analyzing the changes:**
- **ready_check**: Increased from 514 to 534 (ongoing health checks)
- **index**: Increased from 2 to 11 (9 new requests from our loop)
- **get_stores**: New metric appeared with 9 requests (stores endpoint traffic)
- **unknown**: 3 404s from `/stores/1` requests (invalid endpoint demonstrating error tracking)
- **metrics**: Increased from 1 to 2 (our verification request)

**SRE insights:**
- **Counter behavior**: Metrics only increase (monotonic) until pod restart
- **Label diversity**: Different endpoints create separate metric series
- **Error tracking**: 404 responses are captured separately for error rate calculation
- **Business logic**: Store operations generate trackable business metrics

### Alternative Traffic Generation (Optional)

If you want to create a more visible spike for testing:

```bash
# Quick load burst to make counters jump visibly
for i in {1..100}; do curl -s http://$EXTERNAL_IP/stores > /dev/null; done
```

**Expected impact:** Adds 100 requests to the `get_stores` metric in rapid succession, creating a noticeable spike that will be visible in your monitoring dashboards.

### Understanding Metric Persistence

**Counter characteristics:**
- **Monotonic increase**: Values only go up until pod restart
- **Rate calculation**: Monitoring systems calculate rates by measuring increase over time
- **Label significance**: Each unique label combination creates a separate time series
- **Reset behavior**: Pod restarts reset counters to zero (normal behavior)

**Business context:**
Your application now generates realistic metric data that reflects:
- **User traffic patterns**: Mix of successful and failed requests
- **System health**: Ongoing health check activity
- **Business operations**: Store lookups and data retrieval
- **Error conditions**: 404s from invalid endpoints

This diverse metric landscape provides the foundation for building comprehensive dashboards that show both technical performance and business impact - essential for effective SRE monitoring.

---

## Step 3: Deploy Prometheus Using Kubernetes Manifests

This step introduces Prometheus, the industry-standard monitoring system that will collect and store your application metrics. You'll examine production-ready configurations and deploy Prometheus to your GKE cluster with automatic service discovery capabilities.

### Examine Prometheus Configuration Files

Before deploying, understand the monitoring infrastructure you're creating:

```bash
# Examine the Prometheus configuration
cat k8s/monitoring/prometheus-config.yaml
```

**Key configuration sections to understand:**
```yaml
scrape_configs:
  - job_name: 'sre-demo-app'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
```

**What this configuration does:**
- **Service discovery**: Automatically finds pods with `prometheus.io/scrape: "true"` annotations
- **Relabeling**: Transforms Kubernetes metadata into Prometheus labels
- **Multiple jobs**: Collects from your app, Kubernetes API, and Prometheus itself

```bash
# Review the deployment configuration
cat k8s/monitoring/prometheus-deployment.yaml
```

**Production-ready features in the deployment:**
- **RBAC permissions**: ServiceAccount with ClusterRole for Kubernetes API access
- **Resource management**: CPU/memory requests and limits for reliable scheduling
- **Health checks**: Liveness and readiness probes using Prometheus endpoints
- **LoadBalancer service**: External access for dashboards and API queries

**Why these configurations matter:** The service discovery eliminates manual target configuration, while RBAC ensures Prometheus can discover pods across namespaces. Resource limits prevent Prometheus from consuming excessive cluster resources.

### Deploy Prometheus to Your Cluster

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
- **ConfigMap**: Stores Prometheus configuration file
- **Deployment**: Manages Prometheus server pod
- **Service**: Provides LoadBalancer access to Prometheus UI
- **ServiceAccount/RBAC**: Enables Kubernetes API access for service discovery

```bash
# Wait for Prometheus to be ready
kubectl wait --for=condition=available --timeout=300s deployment/prometheus
```

**Expected behavior:** This command waits up to 5 minutes for Prometheus to reach `Available` status. The deployment process includes image pull, configuration mounting, and health check completion.

### Verify Prometheus Deployment

Check that all components are running correctly:

```bash
# Check all pods to find Prometheus
kubectl get pods -A
```

**Expected output (partial):**
```
NAMESPACE         NAME                                                       READY   STATUS    RESTARTS      AGE
default           prometheus-6c65654fdf-f85d7                                1/1     Running   0             44s
default           sre-demo-app-7458c58c57-lt4jf                              1/1     Running   0             42m
default           sre-demo-app-7458c58c57-rqkhv                              1/1     Running   0             42m
```

**Key observations:**
- **prometheus-xxx pod**: Should show `1/1 Running` status
- **sre-demo-app pods**: Should remain running from Exercise 3
- **Various system pods**: GKE system components (normal)

```bash
# Get Prometheus service external IP
kubectl get services prometheus-service
```

**Expected output:**
```
NAME                 TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
prometheus-service   LoadBalancer   34.118.234.68   34.9.23.171   9090:31903/TCP   59s
```

**Understanding the service:**
- **TYPE: LoadBalancer**: Provides external access
- **EXTERNAL-IP**: Your Prometheus web interface address (may show `<pending>` initially)
- **PORT(S)**: 9090 is Prometheus port, 31903 is the NodePort fallback

### Check Prometheus Startup Logs

Verify Prometheus is starting correctly:

```bash
# Check Prometheus pod logs
kubectl logs -l app=prometheus --tail=50
```

**Expected healthy startup logs:**
```
ts=2025-09-06T17:19:34.287Z caller=main.go:583 level=info msg="Starting Prometheus Server" mode=server version="(version=2.47.0, branch=HEAD, revision=efa34a5840661c29c2e362efa76bc3a70dccb335)"
ts=2025-09-06T17:19:34.397Z caller=main.go:1009 level=info msg="Server is ready to receive web requests."
ts=2025-09-06T17:19:34.339Z caller=kubernetes.go:329 level=info component="discovery manager scrape" discovery=kubernetes config=sre-demo-app msg="Using pod service account via in-cluster config"
```

**Log analysis:**
- **"Starting Prometheus Server"**: Initial startup message
- **"Server is ready to receive web requests"**: HTTP server operational
- **"Using pod service account"**: RBAC authentication working for Kubernetes API
- **No error messages**: Configuration loaded successfully

**Get your Prometheus URL:**

```bash
# Get Prometheus external IP
export PROMETHEUS_IP=$(kubectl get service prometheus-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Prometheus URL: http://$PROMETHEUS_IP:9090"
```

**Expected output:**
```
Prometheus URL: http://34.9.23.171:9090
```

**Access your Prometheus web interface:** Open this URL in your browser to explore the Prometheus UI, run queries, and verify service discovery is working.

---

## Step 4: Enable Google Cloud APIs (With Error Handling)

Enable monitoring APIs while handling expected permission errors:

```bash
# Enable required Google Cloud APIs for monitoring
gcloud services enable monitoring.googleapis.com
gcloud services enable logging.googleapis.com
gcloud services enable clouddebugger.googleapis.com
```

**Expected outcome:** You'll likely see a permission error for clouddebugger:

```
ERROR: (gcloud.services.enable) PERMISSION_DENIED: Not found or permission denied for service(s): clouddebugger.googleapis.com.
Help Token: AVSZLmsqtIAq_i1MUZRrRxoujQvhKkFuR52vjMSEa7kXB2NDwSLmxYm_8F2a4rkcPSLZcHdR0x9x3zOddg3Vk-vwqM7RFU_c2l1TQiXlfjyR7R9s
...
reason: SERVICE_CONFIG_NOT_FOUND_OR_PERMISSION_DENIED
```

**This error is completely normal and expected.** The Cloud Debugger API requires special project permissions that aren't available in educational/trial environments.

**Verify the essential APIs are enabled:**

```bash
# Verify APIs are enabled
gcloud services list --enabled --filter="name:(monitoring.googleapis.com OR logging.googleapis.com)"
```

**Expected output:**
```
NAME                       TITLE
logging.googleapis.com     Cloud Logging API
monitoring.googleapis.com  Cloud Monitoring API
```

**What this means:** You have the two essential APIs for monitoring. The clouddebugger API is optional and not required for your monitoring stack to function properly.

---

## Step 5: Configure Google Cloud Monitoring Integration

Attempt to integrate with Google Managed Prometheus:

```bash
# Apply the configuration
kubectl apply -f k8s/monitoring/gmp-config.yaml
```

**Expected output:**
```
configmap/gmp-config created
error: resource mapping not found for name: "sre-demo-app-monitor" namespace: "" from "k8s/monitoring/gmp-config.yaml": no matches for kind "PodMonitor" in version "monitoring.coreos.com/v1"
ensure CRDs are installed first
```

**Understanding this error:**
- **ConfigMap created successfully**: Basic configuration applied
- **PodMonitor error**: Custom Resource Definition (CRD) not installed
- **This is expected**: Not all GKE clusters have Prometheus Operator installed

**What this means for you:**
- Your self-hosted Prometheus continues working perfectly
- Google Cloud Monitoring automatically collects infrastructure metrics
- The PodMonitor would provide additional integration, but isn't essential

---

## Step 6: Access Google Cloud Monitoring

Check your Google Cloud Monitoring dashboard:

```bash
# Check if Google Cloud Monitoring is collecting metrics
export PROJECT_ID=$(gcloud config get-value project)
echo "Check Google Cloud Monitoring at:"
echo "https://console.cloud.google.com/monitoring/overview?project=$PROJECT_ID"
```

**Expected output:**
```
Check Google Cloud Monitoring at:
https://console.cloud.google.com/monitoring/overview?project=gcp-sre-lab
```

**Important:** If you get a "URL not found" error when accessing this URL, this is normal. Your project may not have Google Cloud Monitoring fully initialized yet, or you may need to access it through a different path.

**Alternative access methods:**
1. **Go to Google Cloud Console**: https://console.cloud.google.com
2. **Select your project** (gcp-sre-lab) from the project dropdown
3. **Navigate to "Monitoring"** from the left sidebar or main menu
4. **Or try the direct monitoring URL**: https://console.cloud.google.com/monitoring

**What you'll find in Google Cloud Monitoring (once accessible):**
- **Infrastructure metrics**: CPU, memory, network for your GKE cluster
- **Kubernetes metrics**: Pod health, service status, resource utilization
- **GKE metrics**: Automatically collected from your cluster

```bash
# List available metric types (this may take a few minutes to populate)
gcloud logging metrics list --limit=10
```

**Expected initial output:**
```
Listed 0 items.
```

**This is normal.** Custom log-based metrics take time to populate. The important thing is that your Prometheus is collecting metrics directly from your application, which you've already verified.

Your monitoring stack is now successfully deployed and operational. You have self-hosted Prometheus collecting detailed application metrics and Google Cloud Monitoring providing infrastructure visibility, creating a comprehensive observability foundation for dashboard creation and metric exploration.


```bash
# Examine the SRE query reference
cat monitoring/sre-queries.md

# Test these key queries in your Prometheus web interface (http://$PROMETHEUS_IP:9090):
# - Request rate: sum(rate(http_requests_total[5m]))  
# - Error rate: sum(rate(http_requests_total{status_code=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100
# - P95 latency: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
# - Business success rate: rate(business_operations_total{status="success"}[5m]) / rate(business_operations_total[5m]) * 100
```

These queries form the foundation of your SRE dashboard, focusing on the four golden signals: latency, traffic, errors, and saturation.

### Step 7: Create Google Cloud Monitoring Dashboard

Create a comprehensive dashboard using the provided configuration:

```bash
# Examine the dashboard configuration
cat monitoring/dashboard-config.json
```

```bash
# Create the dashboard using gcloud CLI
gcloud monitoring dashboards create --config-from-file=monitoring/dashboard-config.json

echo "Dashboard created! View it at:"
echo "https://console.cloud.google.com/monitoring/dashboards?project=$PROJECT_ID"
```

### Step 8: Access and Customize Your Dashboard

```bash
# Get direct link to your monitoring dashboard
echo "Access your monitoring dashboard at:"
echo "https://console.cloud.google.com/monitoring/overview?project=$PROJECT_ID"
echo ""
echo "Navigate to 'Dashboards' in the left sidebar to find 'SRE Demo Application Dashboard'"
```

Access the Google Cloud Console and navigate to your custom dashboard to visualize your application metrics.

---

## Implementing SRE Monitoring Best Practices

### Step 9: Test Your Monitoring Stack End-to-End

Use the provided verification script to test your complete monitoring infrastructure:

```bash
# Make the verification script executable
chmod +x scripts/verify-monitoring.sh
```

```bash
# Run comprehensive monitoring verification
./scripts/verify-monitoring.sh

# Alternative: Run specific verification operations
# ./scripts/verify-monitoring.sh infrastructure  # Check deployment health only
# ./scripts/verify-monitoring.sh load 300        # Generate load for 5 minutes
# ./scripts/verify-monitoring.sh queries         # Test Prometheus queries only
```

The verification script generates realistic load patterns, tests Prometheus queries, checks service discovery, and validates Google Cloud Monitoring integration.

### Step 10: Monitor Real-Time Metrics

Generate load and observe how your monitoring stack captures the activity:

```bash
# Generate continuous load in background (optional manual approach)
export EXTERNAL_IP=$(kubectl get service sre-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

```bash
# Simple load generation loop
for i in {1..100}; do
  curl -s http://$EXTERNAL_IP/ > /dev/null &
  curl -s http://$EXTERNAL_IP/stores > /dev/null &
  curl -s http://$EXTERNAL_IP/health > /dev/null &
  
  if [ $((i % 10)) -eq 0 ]; then
    echo "Generated $i requests..."
  fi
  
  sleep 1
done

echo "Check your dashboards to see metrics changes:"
echo "Prometheus: http://$PROMETHEUS_IP:9090"
echo "Google Cloud: https://console.cloud.google.com/monitoring/overview?project=$PROJECT_ID"
```

---

## Final Objective

By completing this exercise, you should be able to demonstrate:

Your SRE application is successfully integrated with a comprehensive monitoring stack that includes Prometheus collecting and storing application metrics with proper service discovery, Google Cloud Monitoring providing unified visibility into both application and infrastructure metrics, custom dashboards displaying the four golden signals of monitoring (latency, traffic, errors, saturation), and SRE-focused queries that support SLI measurement and proactive system management.

### Verification Questions

Test your understanding by answering these questions:

1. **How do** the Prometheus relabeling configurations enable automatic discovery of your application pods?
2. **What advantages** does Google Cloud Monitoring provide over self-managed Prometheus for production environments?
3. **Which metrics** from your dashboard would be most useful for defining SLOs for your application?
4. **How would** you modify the monitoring configuration to track custom business metrics specific to your domain?

---

## Troubleshooting

### Common Issues

**Prometheus not discovering application targets**: Verify that your application pods have the correct `prometheus.io/scrape: "true"` annotation with `kubectl get pods -l app=sre-demo-app -o yaml` and check that Prometheus service discovery configuration matches your pod labels.

**No data appearing in Google Cloud Monitoring**: Ensure that the required APIs are enabled with `gcloud services list --enabled` and verify that it may take 5-10 minutes for custom metrics to appear in Google Cloud Monitoring after initial configuration.

**Prometheus LoadBalancer IP stuck in pending**: Check your Google Cloud project quotas for external IP addresses with `gcloud compute project-info describe --project=$PROJECT_ID` and verify that the Container Registry API is enabled.

**High cardinality metric errors**: If you see warnings about high cardinality metrics, review your label usage in Prometheus queries and consider using recording rules to pre-aggregate frequently used calculations.

**Dashboard queries returning no data**: Verify that your time range covers periods when your application was receiving traffic, and check that metric names match exactly between Prometheus and Google Cloud Monitoring (some characters may be transformed).

**Resource limits causing Prometheus restarts**: Monitor Prometheus pod resource usage with `kubectl top pod prometheus-xxx` and adjust memory/CPU limits in the deployment if necessary for your workload.

### Advanced Troubleshooting

**Debugging metric collection**: Use `kubectl exec -it prometheus-xxx -- promtool query instant 'up'` to verify Prometheus can query its own metrics and check service discovery with `kubectl exec -it prometheus-xxx -- wget -qO- localhost:9090/api/v1/targets`.

**Investigating missing metrics**: Check Prometheus logs for scraping errors with `kubectl logs prometheus-xxx` and verify network connectivity between Prometheus and application pods using `kubectl exec` commands.

**Google Cloud Monitoring integration issues**: Verify that your GKE cluster has the appropriate IAM permissions for Cloud Monitoring by checking the node service account permissions in the Google Cloud Console.

---

## Next Steps

You have successfully implemented a comprehensive monitoring stack that provides full visibility into your Kubernetes-deployed SRE application. You've configured Prometheus to automatically discover and scrape application metrics using Kubernetes service discovery, integrated with Google Cloud Monitoring for unified infrastructure and application observability, created custom dashboards that focus on the four golden signals of monitoring, and established the foundation for SLI/SLO-based reliability management.

**Proceed to [Exercise 5](../exercise5/)** where you will implement intelligent alerting based on the monitoring data you've collected, define SLIs and SLOs for your application using the metrics from your dashboards, create alert policies that notify you before users are impacted, and establish incident response workflows that integrate with your monitoring and alerting infrastructure.

**Key Concepts to Remember**: Effective monitoring focuses on the four golden signals (latency, traffic, errors, saturation) rather than vanity metrics, Prometheus service discovery eliminates manual configuration while ensuring comprehensive coverage, Google Cloud Monitoring provides enterprise-grade reliability and integration with other Google Cloud services, and custom dashboards should tell a story about system health rather than simply displaying raw metrics.

**Before Moving On**: Ensure you can explain how your monitoring configuration supports proactive incident detection and response, and why the combination of Prometheus and Google Cloud Monitoring provides better observability than either system alone. In the next exercise, you'll transform this monitoring data into actionable alerts that support your SRE practice.

