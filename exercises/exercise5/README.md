# Exercise 5: Alerting and Response

## Table of Contents
- [Introduction](#introduction)
- [Learning Objectives](#learning-objectives)
- [Prerequisites](#prerequisites)
- [Theory Foundation](#theory-foundation)
- [Understanding SRE Alerting Philosophy](#understanding-sre-alerting-philosophy)
- [Defining SLIs and SLOs](#defining-slis-and-slos)
- [Implementing Alert Policies](#implementing-alert-policies)
- [Building Incident Response Workflows](#building-incident-response-workflows)
- [Testing Alert Reliability](#testing-alert-reliability)
- [Advanced Alerting Strategies](#advanced-alerting-strategies)
- [Final Objective](#final-objective)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)

---

## Introduction

In this exercise, you will implement intelligent alerting and incident response workflows based on the monitoring infrastructure established in Exercise 4. You'll define Service Level Indicators (SLIs) and Service Level Objectives (SLOs), create alert policies that notify teams before users are impacted, and establish incident response procedures that support effective problem resolution.

This exercise demonstrates how modern SRE teams build alerting systems that reduce noise, focus on user impact, and enable proactive incident management rather than reactive firefighting.

---

## Learning Objectives

By completing this exercise, you will understand:

- **SLI/SLO Framework**: How to define and measure service reliability using SRE principles
- **Alert Policy Design**: How to create alerts that signal actionable problems without generating noise
- **Incident Response Workflows**: How to establish procedures that minimize Mean Time to Resolution (MTTR)
- **Alert Fatigue Prevention**: How to design alerting strategies that maintain team effectiveness
- **Error Budget Management**: How to use error budgets for decision-making and prioritization
- **Escalation Procedures**: How to ensure critical issues receive appropriate attention

---

## Prerequisites

Before starting this exercise, ensure you have completed:

- Exercise 1: Cloud Development Environment & SRE Application
- Exercise 2: Container Builds & GitHub Actions
- Exercise 3: Kubernetes Deployment
- Exercise 4: Cloud Monitoring Stack
- Successfully deployed monitoring infrastructure with Prometheus and Google Cloud Monitoring
- Understanding of your application's key metrics and behavior patterns

Note: This exercise builds directly on the monitoring data and dashboards from Exercise 4.

---

## Theory Foundation

### SRE Alerting Principles

**Essential Watching** (20 minutes):
- [SRE Fundamentals: SLIs, SLAs and SLOs](https://www.youtube.com/watch?v=tEylFyxbDLE) by Google Cloud Tech - Official SRE concepts
- [Alerting best practices](https://www.youtube.com/watch?v=K658JEZUGF4) by Google Cloud Tech – Straightforward alerting insights

**Reference Documentation**:
- [Google SRE Book - Monitoring Distributed Systems](https://sre.google/sre-book/monitoring-distributed-systems/) - Alerting philosophy
- [Google SRE Book - Being On-Call](https://sre.google/sre-book/being-on-call/) - Incident response practices

### Key Concepts You'll Learn

**SLI/SLO Framework** provides objective measurement of service reliability from the user's perspective. SLIs measure what users care about (availability, latency, quality), while SLOs set targets that balance reliability with development velocity.

**Alert Design Philosophy** focuses on alerting on symptoms (user impact) rather than causes (individual component failures). This approach reduces noise while ensuring that problems affecting users receive immediate attention.

**Error Budget Management** uses the difference between 100% reliability and your SLO target as a budget for taking risks. When error budgets are healthy, teams can deploy faster; when depleted, focus shifts to reliability improvements.

---

## Understanding SRE Alerting Philosophy

Your monitoring infrastructure from Exercise 4 collects comprehensive metrics, but raw data doesn't automatically translate to effective alerting. SRE alerting philosophy emphasizes user impact over system behavior, predictive alerts over reactive notifications, and actionable information over status updates.

### Current Monitoring vs. Alerting Needs

**Monitoring Infrastructure** provides visibility into system behavior through dashboards and metrics, enabling investigation and analysis during incidents or planned maintenance windows.

**Alerting Infrastructure** proactively identifies problems that require immediate human intervention, focusing on issues that degrade user experience or threaten service availability.

**Alert Quality** determines team effectiveness. High-quality alerts indicate real problems requiring immediate action, while low-quality alerts create fatigue and reduce responsiveness to genuine incidents.

### Navigate to Exercise Environment

Set up your working directory and verify your application's current state:

```bash
# Navigate to Exercise 5 directory
cd exercises/exercise5
```

```bash
# Verify your application endpoints and collect baseline data
export EXTERNAL_IP=$(kubectl get service sre-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export PROMETHEUS_IP=$(kubectl get service prometheus-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Application endpoints:"
echo "  Main application: http://$EXTERNAL_IP"
echo "  Prometheus UI: http://$PROMETHEUS_IP:9090"
```

**Expected output:**
```
Application endpoints:
  Main application: http://104.154.201.227
  Prometheus UI: http://34.9.23.171:9090
```

### Examine Your Application's Alert-Worthy Metrics

Access your Prometheus interface and understand which metrics indicate user-facing problems:

**In your browser, navigate to:** `http://$PROMETHEUS_IP:9090`

**Test these fundamental SRE queries:**

1. **Availability Rate**: `sum(rate(http_requests_total{status_code!~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100`
2. **Error Rate**: `sum(rate(http_requests_total{status_code=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100`
3. **Request Latency (P95)**: `histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))`
4. **Traffic Volume**: `sum(rate(http_requests_total[5m]))`

**Understanding these metrics for alerting:**

- **Availability Rate** should be near 100%; drops indicate user-facing outages
- **Error Rate** should be near 0%; increases indicate service degradation
- **Request Latency** should be consistent; spikes indicate performance problems
- **Traffic Volume** establishes baseline; significant drops may indicate problems

**Why these metrics matter for alerting:** Each directly correlates with user experience. When availability drops, users can't access the service. When errors increase, users receive failure responses. When latency spikes, users experience slow performance.

---

## Defining SLIs and SLOs

### Building the Foundation for Intelligent Alerting

Before creating alerts, you must establish clear targets for what constitutes acceptable service performance. This section guides you through defining Service Level Indicators (SLIs) that measure user experience and Service Level Objectives (SLOs) that set reliability targets.

### Examine Your SLI Definitions

Review the comprehensive SLI framework provided for your application:

```bash
# Examine the SLI definitions
cat sli-definitions.yaml
```

**Key SLI categories defined for your application:**

**Availability SLI** measures the percentage of HTTP requests that return successful status codes (non-5xx responses). This SLI focuses on whether users can successfully access your service.

**Latency SLI** measures the percentage of HTTP requests completed within 500ms. This SLI ensures users receive responsive service performance.

**Quality SLI** measures the percentage of business operations that complete successfully. This SLI captures functional correctness beyond basic availability.

**Understanding SLI design principles:** Each SLI measures service behavior from the user's perspective, uses metrics that can be queried from your existing monitoring data, provides clear good/bad event classification, and correlates directly with user satisfaction and business impact.

### Review Your SLO Targets and Rationale

Examine the SLO targets that balance user expectations with operational complexity:

```bash
# Review SLO targets and business rationale
cat slo-config.yaml
```

**SLO targets defined for your service:**

**Availability SLO: 99.5%** allows for 3.6 hours of downtime per month, balancing user experience with operational complexity while providing error budget for deployments and maintenance.

**Latency SLO: 95% under 500ms** ensures most users receive fast responses while allowing for some slow requests due to cold starts, garbage collection, or network variations.

**Quality SLO: 99%** sets a high standard for business operations since these represent core functionality that users depend on for service value.

### Deploy SLI Monitoring Configuration

Install the SLI definitions as Kubernetes ConfigMaps for reference during alert development:

```bash
# Deploy SLI definitions to your cluster
kubectl apply -f sli-definitions.yaml
```

**Expected output:**
```
configmap/sli-definitions created
```

```bash
# Deploy SLO configuration
kubectl apply -f slo-config.yaml
```

**Expected output:**
```
configmap/slo-config created
```

**What you've established:** Your cluster now contains comprehensive SLI and SLO definitions that serve as the foundation for all alerting decisions. These configurations provide both the measurement framework and the reliability targets that will guide your alert policy design.

---

## Implementing Alert Policies

### Creating the Detection Layer

With SLIs and SLOs defined, you now implement the technical infrastructure that monitors these targets and triggers alerts when violations occur.

### Deploy Prometheus Alerting Rules

Configure Prometheus alerting rules for immediate problem detection:

```bash
# Examine the alerting rules structure
cat k8s/alerting/prometheus-rules.yaml
```

**Understanding the alert rule hierarchy:**

**Critical Alerts** require immediate response and indicate user-facing problems:
- `ServiceUnavailable`: No metrics received from application (complete outage)
- `HighErrorRate`: Error rate above 5% for more than 2 minutes  
- `ExtremeLatency`: P95 latency above 2 seconds for more than 5 minutes

**Warning Alerts** require investigation and indicate potential developing problems:
- `ElevatedErrorRate`: Error rate above 1% for more than 5 minutes
- `HighLatency`: P95 latency above 800ms for more than 5 minutes
- `BusinessOperationFailures`: Business success rate below 95%

**SLO Burn Rate Alerts** use advanced multi-window detection:
- `AvailabilitySLOFastBurn`: Rapid error budget consumption (14.4x burn rate)
- `AvailabilitySLOSlowBurn`: Sustained error budget consumption (6x burn rate)

```bash
# Deploy the alerting rules ConfigMap
kubectl apply -f k8s/alerting/prometheus-rules.yaml
```

**Expected output:**
```
configmap/prometheus-alerts created
```

### Configure Alertmanager for Alert Routing

Deploy Alertmanager to handle alert routing and notification:

```bash
# Review Alertmanager configuration
cat k8s/alerting/alertmanager-config.yaml
```

**Alertmanager configuration strategy:**

**Routing Configuration** groups related alerts together and routes them to appropriate receivers based on severity and service. Critical alerts receive immediate notification with minimal grouping delay.

**Inhibition Rules** prevent lower-priority alerts from firing when higher-priority alerts are already active, reducing notification spam during incidents.

**Notification Templates** provide rich context in alert notifications, including summary information, service details, and links to runbook documentation.

```bash
# Deploy Alertmanager
kubectl apply -f k8s/alerting/alertmanager-deployment.yaml
kubectl apply -f k8s/alerting/alertmanager-config.yaml
```

**Expected output:**
```
deployment.apps/alertmanager created
service/alertmanager-service created
configmap/alertmanager-config created
secret/alertmanager-secrets created
configmap/alertmanager-templates created
```

```bash
# Wait for Alertmanager to be ready
kubectl wait --for=condition=available --timeout=300s deployment/alertmanager
```

**Expected output:**
```
deployment.apps/alertmanager condition met
```

### Verify Alert Management Integration

Confirm that Prometheus and Alertmanager are properly integrated:

```bash
# Get Alertmanager access URL
export ALERTMANAGER_IP=$(kubectl get service alertmanager-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Alertmanager accessible at: http://$ALERTMANAGER_IP:9093"
```

**Expected output:**
```
Alertmanager accessible at: http://34.9.23.172:9093
```

**Access Alertmanager Web Interface:**

**Navigate to:** `http://$ALERTMANAGER_IP:9093`

**What you should see:** The Alertmanager web interface showing:
- **Alerts tab**: Currently received alerts (should be empty initially)
- **Silences tab**: Configured alert silences
- **Status tab**: Alertmanager configuration and runtime information

**Understanding the alert flow:** When Prometheus evaluates an alerting rule and determines it should fire, it sends the alert to Alertmanager. Alertmanager then applies routing rules, groups related alerts, and sends notifications through configured channels.

---

## Building Incident Response Workflows

### Connecting Alerts to Human Action

Effective alerting is only half the solution; the other half is ensuring that when alerts fire, the right people receive them with sufficient context to take appropriate action quickly.

### Establish Notification Channels

Configure notification channels for different alert severities. In educational environments, actual email/Slack delivery may not be configured, but understanding the configuration is essential:

```bash
# Examine notification channel configuration
cat alerting/notification-channels.yaml || echo "Notification channel config not available in this environment"
```

**Notification strategy principles:**
- **Critical alerts**: Immediate notification through multiple channels
- **Warning alerts**: Batched notifications to reduce volume
- **Informational alerts**: Daily digest or dashboard-only display

### Review Incident Response Playbooks

Examine the incident response procedures:

```bash
# Review incident response playbooks
cat playbooks/availability-incident.md
```

**Key components of effective incident response:**

**Immediate Response Procedures** provide clear actions for the first 5 minutes, including acknowledgment steps, initial triage questions, and immediate assessment commands.

**Detailed Investigation Guides** offer step-by-step troubleshooting procedures with specific commands for checking application health, infrastructure status, and metric patterns.

**Escalation Procedures** define clear timelines and criteria for involving additional team members or management.

```bash
# Review other incident response procedures
cat playbooks/performance-incident.md
cat playbooks/error-budget-depletion.md
cat playbooks/escalation-matrix.md
```

**Understanding playbook design principles:** Each playbook focuses on user impact rather than system symptoms, provides specific commands with expected outputs, includes escalation criteria and contact information, and connects technical investigation to business impact assessment.

---

## Testing Alert Reliability

### Proving Your System Works

The final step is to test the reliability of your entire alerting system through controlled chaos testing and incident simulation.

### Chaos Testing for Alert Validation

Test availability alerting with a controlled service outage:

```bash
# Record current replica count for restoration
export ORIGINAL_REPLICAS=$(kubectl get deployment sre-demo-app -o jsonpath='{.spec.replicas}')
echo "Current replicas: $ORIGINAL_REPLICAS"

# Scale down to simulate complete outage
echo "Creating controlled outage by scaling to 0 replicas..."
kubectl scale deployment sre-demo-app --replicas=0
```

**Monitor alert progression:**

**In your browser, navigate to:** `http://$PROMETHEUS_IP:9090/alerts`

After approximately 1-2 minutes, you should see the `ServiceUnavailable` alert transition from "Inactive" to "Firing".

**Understanding alert timing:** The `ServiceUnavailable` alert is configured with `for: 1m`, meaning Prometheus waits 1 minute of failed metrics collection before firing the alert. This prevents false positives from brief network interruptions.

**Verify service is unreachable:**

```bash
# Confirm service is unavailable
curl -I http://$EXTERNAL_IP/ || echo "Service confirmed unavailable"
```

**Expected output:**
```
curl: (7) Failed to connect to 104.154.201.227 port 80: Connection refused
Service confirmed unavailable
```

**After 3-5 minutes of testing, restore service:**

```bash
# Restore service
echo "Restoring service to $ORIGINAL_REPLICAS replicas..."
kubectl scale deployment sre-demo-app --replicas=$ORIGINAL_REPLICAS

# Wait for service restoration
kubectl wait --for=condition=available --timeout=180s deployment/sre-demo-app
```

**Expected output:**
```
deployment.apps/sre-demo-app condition met
```

### Test Error Rate Alerting

Generate elevated error rates to validate error rate alerting:

```bash
# Generate traffic with elevated error rate
echo "Generating traffic with elevated error rate..."

for i in {1..60}; do
    # Generate normal requests
    curl -s http://$EXTERNAL_IP/ > /dev/null &
    curl -s http://$EXTERNAL_IP/stores > /dev/null &
    
    # Generate error requests (404s)
    curl -s http://$EXTERNAL_IP/nonexistent-endpoint > /dev/null &
    curl -s http://$EXTERNAL_IP/fake-page > /dev/null &
    
    if [ $((i % 20)) -eq 0 ]; then
        echo "Generated $i rounds of mixed traffic..."
    fi
    
    sleep 0.5
done

echo "Error traffic generation completed"
```

**Monitor error rate in Prometheus:**

**Query:** `sum(rate(http_requests_total{status_code=~"4.."}[5m])) / sum(rate(http_requests_total[5m])) * 100`

**Expected progression:** Error rate should climb from near 0% to 25-40%, potentially triggering the `ElevatedErrorRate` alert if sustained above the 1% threshold for 5+ minutes.

### Incident Simulation

Practice using incident response procedures during a controlled scenario:

```bash
# Create a realistic production issue: reduced capacity with performance impact
echo "Simulating production capacity issue..."

# Scale down to cause availability pressure
kubectl scale deployment sre-demo-app --replicas=1

# Generate sustained load
echo "Generating sustained load to create performance impact..."
for i in {1..30}; do
    for j in {1..10}; do
        curl -s http://$EXTERNAL_IP/stores > /dev/null &
    done
    sleep 1
done

echo "Load generation completed"
```

**Follow incident response procedures:**

```bash
# 1. Check service status (following playbook)
kubectl get pods -l app=sre-demo-app
kubectl get services sre-demo-service

# 2. Check recent changes
kubectl rollout history deployment/sre-demo-app

# 3. Implement mitigation (scale up for capacity)
kubectl scale deployment sre-demo-app --replicas=4
echo "Scaled to 4 replicas for increased capacity"

# 4. Monitor recovery
kubectl wait --for=condition=available --timeout=180s deployment/sre-demo-app
curl -I http://$EXTERNAL_IP/ && echo "Service accessibility restored"
```

**Clean up simulation:**

```bash
# Restore normal configuration
kubectl scale deployment sre-demo-app --replicas=2
echo "Normal configuration restored"
```

**What this exercise demonstrates:** Incident response playbooks provide structured procedures that reduce decision-making overhead during stressful situations and ensure consistent response quality.

---

## Advanced Alerting Strategies

### Implement Multi-Window, Multi-Burn-Rate Alerts

The alerting rules you deployed include advanced SLO alerting that balances sensitivity with noise reduction:

**Multi-burn-rate alerting** uses different time windows to detect both fast-developing and slow-developing problems:

- **Fast burn rate** (14.4x normal): Detects severe problems that will exhaust error budget in <2 hours
- **Slow burn rate** (6x normal): Identifies sustained issues that will exhaust error budget in 6+ hours

**Check advanced alerting rules:**

```bash
# Examine SLO burn rate alert configuration
grep -A 10 "AvailabilitySLO" k8s/alerting/prometheus-rules.yaml
```

### Error Budget Policy Implementation

Implement error budget policies that guide development and operational decisions:

```bash
# Calculate current error budget status
echo "=== Error Budget Analysis ==="

# Query current availability (using available data as proxy)
availability=$(curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=sum(rate(http_requests_total{status_code!~\"5..\"}[24h]))/sum(rate(http_requests_total[24h]))*100" | jq -r '.data.result[0].value[1] // "99.8"')

echo "Current availability: $availability%"

# Calculate error budget consumption for 99.5% SLO
error_budget_used=$(python3 -c "print(max(0, 100 - float('$availability')))")
error_budget_remaining=$(python3 -c "print(max(0, 0.5 - float('$error_budget_used')))")

echo "Error budget used: $error_budget_used%"
echo "Error budget remaining: $error_budget_remaining%"

# Determine operational posture
if (( $(python3 -c "print(1 if float('$error_budget_remaining') > 0.25 else 0)") )); then
    echo "Operational posture: NORMAL - Sufficient error budget"
else
    echo "Operational posture: CAUTIOUS - Review deployment practices"
fi
```

**Error budget policies provide objective criteria for:**
- **Development velocity decisions**: When to proceed with risky deployments
- **Operational focus**: When to prioritize reliability over new features
- **Resource allocation**: When to invest in reliability improvements

### Alert Quality Metrics

Monitor alert effectiveness over time:

```bash
# Check current alert status
curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=ALERTS" | jq -r '.data.result[] | "\(.metric.alertname): \(.metric.alertstate) (\(.metric.severity))"'

# Count alerts by severity
echo "Alert summary:"
curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=ALERTS" | jq -r '.data.result[].metric.severity' | sort | uniq -c
```

**Alert quality indicators:**
- **Signal-to-noise ratio**: Percentage of alerts that require action
- **Time-to-detection**: How quickly alerts fire when problems occur
- **False positive rate**: Alerts that fire without genuine problems
- **Coverage**: Whether all user-impacting problems trigger alerts

---

## Final Objective

By completing this exercise, you should be able to demonstrate:

Your application has well-defined SLIs that measure user experience and SLOs that set appropriate reliability targets. Alert policies trigger on user-impacting problems with minimal false positives, using both fast Prometheus rules and SLO-based policies. Incident response playbooks provide clear procedures for common scenarios, and you understand how notification channels ensure appropriate team members receive alerts. The alerting system focuses on actionable problems and provides sufficient context for effective response.

### Verification Questions

Test your understanding by answering these questions:

1. **How do** multi-burn-rate alerts balance detection speed with false positive reduction?
2. **Why are** SLO-based alerts more effective than threshold-based alerts for user-facing services?
3. **What metrics** would indicate that your alerting system is generating too much noise?
4. **How should** error budget depletion influence development and operational priorities?

---

## Troubleshooting

### Common Issues

**Alerts not triggering during test scenarios**: Verify that Prometheus is successfully scraping metrics with `kubectl exec deployment/prometheus -- promtool query instant 'up{job="sre-demo-app"}'` and check alerting rule syntax with the Prometheus web interface.

**Notification channels not receiving alerts**: Confirm notification channel configuration with `gcloud alpha monitoring channels list` and test channel connectivity using Google Cloud Console notification testing features. Note that in educational environments, actual delivery may not be configured.

**SLO measurements showing incorrect values**: Verify that your SLI queries return expected results using Prometheus web interface and ensure that time windows align with your service's behavior patterns.

**Error budget calculations appearing inconsistent**: Check that SLO definitions match your actual service behavior and verify that measurement windows provide sufficient data points for accurate calculations.

**Alert fatigue from excessive notifications**: Review alert policies for overly sensitive thresholds, implement proper alert grouping and deduplication, and consider using multi-burn-rate alerting to reduce noise.

### Advanced Troubleshooting

**Debugging Prometheus alerting rules**: Use `kubectl exec deployment/prometheus -- promtool check rules /etc/prometheus/rules/*.yml` to validate rule syntax and test alert conditions with historical data.

**Investigating alert policy effectiveness**: Analyze alert history in Prometheus to identify patterns of false positives and adjust policies based on actual incident correlation.

**Optimizing incident response procedures**: Track MTTR metrics for different incident types and refine playbooks based on actual response experiences and post-incident reviews.

---

## Next Steps

You have successfully implemented comprehensive alerting and incident response capabilities that focus on user impact rather than system behavior. You've defined meaningful SLIs and SLOs that guide reliability decisions, created alert policies that notify teams of actionable problems, established incident response procedures that minimize MTTR, and implemented error budget management that balances reliability with development velocity.

**Proceed to [Exercise 6](../exercise6/)** where you will implement production-ready CI/CD pipelines with GitOps principles, establish automated deployment workflows that maintain service reliability, implement rollback procedures and deployment safety measures, and integrate deployment processes with your monitoring and alerting infrastructure.

**Key Concepts to Remember**: Effective alerting focuses on user impact and provides actionable information for problem resolution, SLOs provide objective measures for balancing reliability and development velocity, error budgets enable data-driven decisions about risk tolerance and operational focus, and incident response procedures should minimize MTTR while ensuring thorough problem resolution.

**Before Moving On**: Ensure you can explain how your alerting strategy prevents both alert fatigue and missed incidents, and why SLO-based alerting is more effective than traditional threshold-based approaches. In the next exercise, you'll integrate these reliability practices with automated deployment workflows.