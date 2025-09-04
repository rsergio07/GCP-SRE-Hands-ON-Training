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

### Step 1: Verify Current Metric Exposure

First, confirm that your deployed application is properly exposing metrics in the Kubernetes environment:

```bash
# Navigate to Exercise 4 directory
cd exercises/exercise4
```

```bash
# Get your application's external IP
export EXTERNAL_IP=$(kubectl get service sre-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Application URL: http://$EXTERNAL_IP"
```

```bash
# Examine current metrics endpoint
curl -s http://$EXTERNAL_IP/metrics | head -20
```

```bash
# Check specific application metrics
curl -s http://$EXTERNAL_IP/metrics | grep -E "(http_requests_total|business_operations)"
```

Your application should be exposing Prometheus-formatted metrics including HTTP request counters, business operation metrics, and application information. These metrics form the foundation for your comprehensive monitoring stack.

### Step 2: Generate Baseline Metrics Data

Create representative metric data to ensure your monitoring system has meaningful information to display:

```bash
# Get the external IP of the app (re-run if you recreated the Service)
export EXTERNAL_IP=$(kubectl get service sre-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Application URL: http://$EXTERNAL_IP"
```

```bash
# Example output
Application URL: http://34.86.123.45
```

```bash
# Generate diverse application traffic (50 iterations)
for i in {1..50}; do
  curl -s http://$EXTERNAL_IP/ > /dev/null
  curl -s http://$EXTERNAL_IP/stores > /dev/null
  curl -s http://$EXTERNAL_IP/stores/1 > /dev/null
  curl -s http://$EXTERNAL_IP/health > /dev/null

  # Randomized sleep to vary request timing (requires 'bc')
  sleep $(echo "scale=1; $RANDOM/32767" | bc)
done
```

```bash
# (No output expected)
# The loop sends requests quietly; you'll verify impact via /metrics next.
```

```bash
# Verify metrics have updated (request and business counters)
curl -s http://$EXTERNAL_IP/metrics | grep -E "(http_requests_total|business_operations)" | head -10
```

```bash
# Example output (values will differ)
http_requests_total{endpoint="/",method="GET",status_code="200"} 52
http_requests_total{endpoint="/stores",method="GET",status_code="200"} 50
http_requests_total{endpoint="/stores/1",method="GET",status_code="200"} 50
http_requests_total{endpoint="/health",method="GET",status_code="200"} 50
business_operations_total{operation="list_stores",status="success"} 50
business_operations_total{operation="get_store",status="success"} 50
business_operations_total{operation="health_check",status="success"} 50
# Depending on your app’s labeling, you might also see labels like:
# {job="sre-demo-app",pod="sre-demo-app-7b9d4c5c8-ktz2f",namespace="default"}
```

```bash
# (Optional) Watch metrics change while sending traffic from another terminal
watch -n 2 'curl -s http://$EXTERNAL_IP/metrics | grep -E "(http_requests_total|business_operations)" | head -10'
```

```bash
# Example watch snapshot
Every 2.0s: curl -s http://34.86.123.45/metrics | grep -E "(http_requests_total|business_operations)" | head -10

http_requests_total{endpoint="/stores",method="GET",status_code="200"} 175
http_requests_total{endpoint="/",method="GET",status_code="200"} 180
business_operations_total{operation="list_stores",status="success"} 175
business_operations_total{operation="get_store",status="success"} 175
```

```bash
# (Optional) Quick load burst to make counters jump visibly
for i in {1..100}; do curl -s http://$EXTERNAL_IP/stores > /dev/null; done
```

```bash
# Example follow-up check
curl -s http://$EXTERNAL_IP/metrics | grep 'endpoint="/stores"' | head -3
```

```bash
# Example output (note the increased counter)
http_requests_total{endpoint="/stores",method="GET",status_code="200"} 275
```

```bash
# (Optional) If 'bc' is not available, use a simple fixed sleep instead
for i in {1..20}; do
  curl -s http://$EXTERNAL_IP/ > /dev/null
  sleep 0.5
done
```

```bash
# Example verification
curl -s http://$EXTERNAL_IP/metrics | grep 'endpoint="/"' | head -3
```

```bash
# Example output
http_requests_total{endpoint="/",method="GET",status_code="200"} 200
```

Notes:

* Counters are **monotonic**; they only increase until the pod restarts.
* Label sets vary by your app/instrumentation (you may see `job`, `pod`, `namespace`, `instance`, etc.).
* If grep returns nothing, ensure the service is reachable and your app exports those metric names

### Understanding Kubernetes Metric Discovery

**Reference Documentation**:
- [Kubernetes Service Discovery](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kubernetes_sd_config) - How Prometheus finds metrics endpoints
- [Prometheus Annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/) - Configuring automatic scraping

---

## Deploying Prometheus to GKE

### Setting Up Your Data Collector

You have confirmed that your application is emitting metrics, but those metrics are only useful if they can be collected and stored. This section introduces and deploys **Prometheus**, an industry-standard monitoring system, to your GKE cluster. Prometheus will be configured to automatically discover and "scrape" metrics from your application pods, creating the time-series database that will power your dashboards and alerts.

### Step 3: Deploy Prometheus Using Kubernetes Manifests

Examine the provided Prometheus configuration and deploy it to your cluster:

```bash
# Create monitoring directory structure  
mkdir -p k8s/monitoring
```

```bash
# Examine the Prometheus configuration
cat k8s/monitoring/prometheus-config.yaml
```

```bash
# Review the deployment configuration
cat k8s/monitoring/prometheus-deployment.yaml
```

The Prometheus configuration implements service discovery to automatically find your SRE application pods using Kubernetes annotations. The deployment includes proper RBAC permissions, resource limits, and health checks following production best practices.

### Step 4: Deploy Prometheus to Your Cluster

```bash
# Deploy Prometheus configuration and deployment
kubectl apply -f k8s/monitoring/prometheus-config.yaml
kubectl apply -f k8s/monitoring/prometheus-deployment.yaml
```

```bash
# Wait for Prometheus to be ready
kubectl wait --for=condition=available --timeout=300s deployment/prometheus
```

```bash
# Get Prometheus service external IP
kubectl get services prometheus-service
```

```bash
# Check Prometheus pod logs
kubectl logs -l app=prometheus --tail=50
```

Prometheus will take 2-3 minutes to fully initialize and begin scraping metrics from your application. The service discovery configuration will automatically find your SRE demo application pods.

### Step 5: Access Prometheus Web Interface

```bash
# Get Prometheus external IP
export PROMETHEUS_IP=$(kubectl get service prometheus-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Prometheus URL: http://$PROMETHEUS_IP:9090"
```

```bash
# Wait for LoadBalancer IP assignment (may take a few minutes)
while [ -z "$PROMETHEUS_IP" ] || [ "$PROMETHEUS_IP" = "null" ]; do
  echo "Waiting for LoadBalancer IP..."
  sleep 30
  export PROMETHEUS_IP=$(kubectl get service prometheus-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
done

echo "Prometheus is ready at: http://$PROMETHEUS_IP:9090"
```

Access the Prometheus web interface to verify that it's successfully scraping metrics from your application.

### Alternative: Use Automated Setup Script

For streamlined deployment, use the provided setup script:

```bash
# Make the setup script executable and run it
chmod +x scripts/setup-monitoring.sh
./scripts/setup-monitoring.sh
```

The setup script automates API enablement, Prometheus deployment, Google Cloud integration, and dashboard creation while providing detailed progress feedback.

---

## Integrating with Google Cloud Monitoring

### Step 6: Enable Google Cloud Monitoring APIs

```bash
# Enable required Google Cloud APIs for monitoring
gcloud services enable monitoring.googleapis.com
gcloud services enable logging.googleapis.com
gcloud services enable clouddebugger.googleapis.com
```

```bash
# Verify APIs are enabled
gcloud services list --enabled --filter="name:(monitoring.googleapis.com OR logging.googleapis.com)"
```

Google Cloud Monitoring will automatically collect GKE infrastructure metrics, but we'll also configure it to ingest our custom application metrics.

### Unifying Observability with the Cloud

While a self-managed Prometheus instance is powerful, a production-grade SRE stack benefits from a managed solution. This section shows you how to integrate your self-hosted Prometheus with **Google Cloud Monitoring**. This integration provides unified visibility by combining your custom application metrics with the infrastructure metrics automatically collected by Google Cloud, giving you a single pane of glass for all your observability data.

### Step 7: Configure Managed Service for Prometheus

Google Cloud provides a managed Prometheus service that can ingest metrics directly from your Kubernetes cluster:

```bash
# Examine the Google Managed Prometheus configuration
cat k8s/monitoring/gmp-config.yaml
```

```bash
# Apply the configuration
kubectl apply -f k8s/monitoring/gmp-config.yaml
```

The Google Managed Prometheus configuration creates PodMonitor resources that automatically discover your application pods and send metrics to Google Cloud Monitoring for unified observability.

### Step 8: Verify Google Cloud Monitoring Integration

```bash
# Check if Google Cloud Monitoring is collecting metrics
echo "Check Google Cloud Monitoring at:"
echo "https://console.cloud.google.com/monitoring/overview?project=$PROJECT_ID"
```

```bash
# List available metric types (this may take a few minutes to populate)
gcloud logging metrics list --limit=10
```

```bash
# Test custom metrics query (replace PROJECT_ID with your actual project)
gcloud monitoring metrics list --filter="metric.type:\"custom.googleapis.com/opencensus/http_requests_total\"" --limit=5
```

It may take 5-10 minutes for custom metrics to appear in Google Cloud Monitoring after initial configuration.

---

## Creating Custom Dashboards and Visualizations

### Translating Data into Insights

Raw metrics are just numbers. For an SRE team, the real value lies in translating that data into actionable insights. This section focuses on the final step of the monitoring pipeline: building a dashboard. You will create and test queries based on the **four golden signals of monitoring** (latency, traffic, errors, and saturation) and use them to build a custom dashboard in Google Cloud Monitoring that tells a clear story about your application's health.

### Step 9: Create SRE-Focused Prometheus Queries

Review the comprehensive query library provided for production monitoring:

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

### Step 10: Create Google Cloud Monitoring Dashboard

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

### Step 11: Access and Customize Your Dashboard

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

### Step 12: Test Your Monitoring Stack End-to-End

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

### Step 13: Monitor Real-Time Metrics

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