# Exercise 5: Alerting and Response

## Table of Contents
- [Introduction](#introduction)
- [Learning Objectives](#learning-objectives)
- [Prerequisites](#prerequisites)
- [Theory Foundation](#theory-foundation)
- [Understanding SRE Alerting Philosophy](#understanding-sre-alerting-philosophy)
- [Defining Service Level Indicators and Objectives](#defining-service-level-indicators-and-objectives)
- [Implementing Production-Ready Alert Policies](#implementing-production-ready-alert-policies)
- [Building Incident Response Workflows](#building-incident-response-workflows)
- [Testing Alert Reliability Through Controlled Chaos](#testing-alert-reliability-through-controlled-chaos)
- [Understanding Alert Quality and Troubleshooting](#understanding-alert-quality-and-troubleshooting)
- [Final Objective](#final-objective)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)

---

## Introduction

In this exercise, you will implement intelligent alerting and incident response workflows based on the monitoring infrastructure established in Exercise 4. You'll define Service Level Indicators (SLIs) and Service Level Objectives (SLOs), create alert policies that notify teams before users are impacted, and establish incident response procedures that support effective problem resolution.

This exercise demonstrates how modern SRE teams build alerting systems that reduce noise, focus on user impact, and enable proactive incident management rather than reactive firefighting. The journey from monitoring to alerting requires understanding the fundamental difference between these practices: monitoring provides visibility for investigation, while alerting triggers immediate human intervention for problems requiring action.

You'll experience realistic troubleshooting scenarios that mirror production environments where alerting configurations often require debugging and refinement. These challenges prepare you for production SRE work where alert system reliability directly affects both user experience and team effectiveness during incident response.

---

## Learning Objectives

By completing this exercise, you will understand:

- **SLI/SLO Framework**: How to define and measure service reliability using user-focused metrics
- **Alert Policy Design**: How to create alerts that signal actionable problems without generating noise
- **Incident Response Workflows**: How to establish procedures that minimize Mean Time to Resolution (MTTR)
- **Alert Fatigue Prevention**: How to design alerting strategies that maintain team effectiveness
- **Error Budget Management**: How to use error budgets for decision-making and prioritization
- **Chaos Engineering Validation**: How to test alert reliability through controlled service disruption

---

## Prerequisites

Before starting this exercise, ensure you have completed:

- Exercise 1: Cloud Development Environment & SRE Application
- Exercise 2: Container Builds & GitHub Actions
- Exercise 3: Kubernetes Deployment
- Exercise 4: Cloud Monitoring Stack

**Verify your prerequisites:**

```bash
# Check that monitoring infrastructure is functioning
kubectl get pods -l app=prometheus
kubectl get pods -l app=sre-demo-app
```

Expected output:
```
NAME                          READY   STATUS    RESTARTS   AGE
prometheus-7b8c4f9d4c-xyz12   1/1     Running   0          2h

NAME                            READY   STATUS    RESTARTS   AGE
sre-demo-app-7458c58c57-abc34   1/1     Running   0          2h
sre-demo-app-7458c58c57-def56   1/1     Running   0          2h
```

Note: This exercise builds directly on the monitoring data and infrastructure from Exercise 4.

---

## Theory Foundation

### SRE Alerting Principles

**Essential Watching** (20 minutes):
- [SRE Fundamentals: SLIs, SLAs and SLOs](https://www.youtube.com/watch?v=tEylFyxbDLE) by Google Cloud Tech - Official SRE concepts
- [Alerting best practices](https://www.youtube.com/watch?v=AmYWMLv4h-0) by Google Cloud Tech - Straightforward alerting insights

**Reference Documentation**:
- [Google SRE Book - Monitoring Distributed Systems](https://sre.google/sre-book/monitoring-distributed-systems/) - Alerting philosophy
- [Google SRE Book - Being On-Call](https://sre.google/sre-book/being-on-call/) - Incident response practices

### Key Concepts You'll Learn

**SLI/SLO Framework** provides objective measurement of service reliability from the user's perspective. SLIs measure what users care about (availability, latency, quality), while SLOs set targets that balance reliability with development velocity and provide clear criteria for operational decision-making.

**Alert Design Philosophy** focuses on alerting on symptoms (user impact) rather than causes (individual component failures). This approach reduces noise while ensuring that problems affecting users receive immediate attention. Effective alerts must be actionable, requiring human intervention rather than just providing status information.

**Error Budget Management** uses the difference between 100% reliability and your SLO target as a budget for taking risks. When error budgets are healthy, teams can deploy faster; when depleted, focus shifts to reliability improvements until service health recovers.

---

## Understanding SRE Alerting Philosophy

Your monitoring infrastructure from Exercise 4 collects comprehensive metrics, but raw data doesn't automatically translate to effective alerting. SRE alerting philosophy emphasizes user impact over system behavior, predictive alerts over reactive notifications, and actionable information over status updates.

### Current Monitoring vs. Alerting Needs

**Monitoring Infrastructure** provides visibility into system behavior through dashboards and metrics, enabling investigation and analysis during incidents or planned maintenance windows. This foundation supports root cause analysis and trend identification.

**Alerting Infrastructure** proactively identifies problems that require immediate human intervention, focusing on issues that degrade user experience or threaten service availability. The critical distinction lies in urgency and actionability.

**Alert Quality** determines team effectiveness. High-quality alerts indicate real problems requiring immediate action, while low-quality alerts create fatigue and reduce responsiveness to genuine incidents.

### Step 1: Navigate to Exercise Environment

Set up your working directory and verify your application's current state:

```bash
# Navigate to Exercise 5 directory
cd exercises/exercise5
```

```bash
# Verify monitoring infrastructure status and collect baseline data
export EXTERNAL_IP=$(kubectl get service sre-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export PROMETHEUS_IP=$(kubectl get service prometheus-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Application endpoints:"
echo "  Main application: http://$EXTERNAL_IP"
echo "  Prometheus UI: http://$PROMETHEUS_IP:9090"
```

Expected output:
```
Application endpoints:
  Main application: http://104.154.201.227
  Prometheus UI: http://34.9.23.171:9090
```

These service endpoints represent the foundation of your alerting system. The external IP provides the user-facing endpoint that alerts should monitor, while the Prometheus IP gives you access to the metrics and alerting interface that drives notification decisions.

### Step 2: Examine Alert-Worthy Metrics

Access your Prometheus interface and understand which metrics indicate user-facing problems:

**In your browser, navigate to:** `http://$PROMETHEUS_IP:9090`

**Test these fundamental SRE queries that form the basis of effective alerting:**

1. **Availability Rate**: `sum(rate(http_requests_total{status_code!~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100`
2. **Error Rate**: `sum(rate(http_requests_total{status_code=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100`
3. **Request Latency (P95)**: `histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))`
4. **Service Discovery Status**: `up{job="sre-demo-app"}`

**Understanding these metrics for alerting:**

- **Availability Rate** should be near 100%; drops indicate user-facing outages
- **Error Rate** should be near 0%; increases indicate service degradation  
- **Request Latency** should be consistent; spikes indicate performance problems
- **Service Discovery Status** should show "1" for healthy instances; "0" or absence indicates monitoring or service failures

**Why these metrics matter for alerting:** Each directly correlates with user experience. When availability drops, users can't access the service. When errors increase, users receive failure responses. When latency spikes, users experience slow performance that affects satisfaction and productivity.

---

## Defining Service Level Indicators and Objectives

Before creating alerts, you must establish clear targets for what constitutes acceptable service performance. This section guides you through defining Service Level Indicators (SLIs) that measure user experience and Service Level Objectives (SLOs) that set reliability targets.

### Building the Foundation for Intelligent Alerting

SLIs must measure service behavior from the user's perspective rather than internal system metrics. Effective SLIs provide clear good/bad event classification, correlate directly with user satisfaction, and can be reliably measured using available monitoring data.

### Step 3: Examine Your SLI Definitions

Review the comprehensive SLI framework provided for your application:

```bash
# Examine the SLI definitions
cat sli-definitions.yaml
```

**Key SLI categories defined for your application:**

**Availability SLI** measures the percentage of HTTP requests that return successful status codes (non-5xx responses). This SLI focuses on whether users can successfully access your service, distinguishing between service problems (5xx errors) and user mistakes (4xx errors).

**Latency SLI** measures the percentage of HTTP requests completed within 500ms. This SLI ensures users receive responsive service performance while allowing for some slower requests due to cold starts, garbage collection, or network variations.

**Quality SLI** measures the percentage of business operations that complete successfully. This SLI captures functional correctness beyond basic availability, focusing on whether core service features work properly for users.

**Understanding SLI design principles:** Each SLI measures service behavior from the user's perspective, uses metrics that can be queried from your existing monitoring data, provides clear good/bad event classification, and correlates directly with user satisfaction and business impact.

### Step 4: Review Your SLO Targets and Rationale

Examine the SLO targets that balance user expectations with operational complexity:

```bash
# Review SLO targets and business rationale
cat slo-config.yaml
```

**SLO targets defined for your service:**

**Availability SLO: 99.5%** allows for 3.6 hours of downtime per month, balancing user experience with operational complexity while providing error budget for deployments and maintenance. This target reflects realistic expectations for non-critical business services.

**Latency SLO: 95% under 500ms** ensures most users receive fast responses while allowing for some slow requests due to system variations. This percentile-based approach focuses on typical user experience rather than worst-case scenarios.

**Quality SLO: 99%** sets a high standard for business operations since these represent core functionality that users depend on for service value. This stricter target reflects the importance of functional correctness.

**Why these targets matter:** SLO selection involves understanding user expectations, operational capabilities, and business impact of service degradation. Targets must be achievable with current infrastructure while pushing teams toward reliability improvements.

### Step 5: Deploy SLI Monitoring Configuration

Install the SLI definitions as Kubernetes ConfigMaps for reference during alert development:

```bash
# Deploy SLI definitions to your cluster
kubectl apply -f sli-definitions.yaml
```

Expected output:
```
configmap/sli-definitions created
```

```bash
# Deploy SLO configuration
kubectl apply -f slo-config.yaml
```

Expected output:
```
configmap/slo-config created
```

**What you've established:** Your cluster now contains comprehensive SLI and SLO definitions that serve as the foundation for all alerting decisions. These configurations provide both the measurement framework and the reliability targets that will guide your alert policy design.

---

## Implementing Production-Ready Alert Policies

With SLIs and SLOs defined, you now implement the technical infrastructure that monitors these targets and triggers alerts when violations occur. This section addresses the real-world complexities of alert configuration and the troubleshooting required when alerting pipelines don't work as expected.

### Creating the Detection Layer

Alert implementation requires understanding the relationship between Prometheus alerting rules, Alertmanager routing configuration, and notification delivery systems. Each component serves a specific purpose in the alerting pipeline.

### Step 6: Deploy Prometheus Alerting Rules

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

**Why this hierarchy matters:** Each alert category serves different operational needs. Critical alerts justify interrupting on-call engineers because they represent active user impact. Warning alerts provide early detection of developing problems. SLO burn rate alerts bridge tactical response with strategic reliability management.

```bash
# Deploy the alerting rules ConfigMap
kubectl apply -f k8s/alerting/prometheus-rules.yaml
```

Expected output:
```
configmap/prometheus-alerts created
```

### Step 7: Configure Alertmanager for Alert Routing

Deploy Alertmanager to handle alert routing and notification:

```bash
# Review Alertmanager configuration
cat k8s/alerting/alertmanager-config.yaml
```

**Alertmanager configuration strategy:**

**Routing Configuration** groups related alerts together and routes them to appropriate receivers based on severity and service. Critical alerts receive immediate notification with minimal grouping delay to ensure rapid response.

**Inhibition Rules** prevent lower-priority alerts from firing when higher-priority alerts are already active, reducing notification spam during incidents while ensuring teams focus on the most critical issues first.

**Notification Templates** provide rich context in alert notifications, including summary information, service details, and links to runbook documentation that supports effective incident response.

```bash
# Deploy Alertmanager
kubectl apply -f k8s/alerting/alertmanager-deployment.yaml
kubectl apply -f k8s/alerting/alertmanager-config.yaml
```

Expected output:
```
deployment.apps/alertmanager created
service/alertmanager-service created
configmap/alertmanager-config created
secret/alertmanager-secrets created
```

```bash
# Wait for Alertmanager to be ready
kubectl wait --for=condition=available --timeout=300s deployment/alertmanager
```

Expected output:
```
deployment.apps/alertmanager condition met
```

### Step 8: Verify Alert Management Integration

Confirm that Prometheus and Alertmanager are properly integrated:

```bash
# Get Alertmanager access URL
export ALERTMANAGER_IP=$(kubectl get service alertmanager-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Alertmanager accessible at: http://$ALERTMANAGER_IP:9093"
```

Expected output:
```
Alertmanager accessible at: http://34.9.23.172:9093
```

**Access Alertmanager Web Interface:**

Navigate to the URL shown in your output. The interface should display:
- **Alerts tab**: Currently received alerts (should be empty initially)
- **Silences tab**: Configured alert silences
- **Status tab**: Alertmanager configuration and runtime information

**Understanding the alert flow:** When Prometheus evaluates an alerting rule and determines it should fire, it sends the alert to Alertmanager. Alertmanager then applies routing rules, groups related alerts, and sends notifications through configured channels.

---

## Building Incident Response Workflows

Effective alerting requires connecting alert notifications to structured human response procedures. This section establishes incident response workflows that provide clear guidance for on-call engineers receiving alert notifications.

### Connecting Alerts to Human Action

Notification strategies must account for different alert severities and team communication patterns. While actual delivery may not be configured in educational environments, understanding the design principles remains essential for production SRE work.

### Step 9: Establish Notification Channel Strategy

Configure notification channels for different alert severities:

```bash
# Examine notification channel configuration (may not exist in educational environment)
cat alerting/notification-channels.yaml || echo "Notification channel config not available in this environment"
```

Expected output:
```
cat: alerting/notification-channels.yaml: No such file or directory
Notification channel config not available in this environment
```

**Understanding why this limitation exists:** Educational environments typically cannot send actual emails or Slack messages due to external service integration requirements. This limitation helps distinguish between alert detection (which you are implementing) and alert delivery (which requires external configuration).

**Notification strategy principles:**
- **Critical alerts**: Immediate notification through multiple channels
- **Warning alerts**: Batched notifications to reduce volume while maintaining visibility
- **Informational alerts**: Daily digest or dashboard-only display

### Step 10: Review Incident Response Playbooks

Examine the incident response procedures that guide effective problem resolution:

```bash
# Review the availability incident response playbook
cat playbooks/availability-incident.md
```

**Key components of effective incident response:**

**Immediate Response Procedures** provide clear actions for the first 5 minutes, including acknowledgment steps, initial triage questions, and immediate assessment commands. These procedures ensure rapid response while gathering essential information.

**Detailed Investigation Guides** offer step-by-step troubleshooting procedures with specific commands for checking application health, infrastructure status, and metric patterns. This systematic approach reduces cognitive load during stressful situations.

**Escalation Procedures** define clear timelines and criteria for involving additional team members or management, ensuring complex problems receive appropriate expertise without unnecessary interruptions.

```bash
# Review other incident response procedures
cat playbooks/performance-incident.md
cat playbooks/error-budget-depletion.md
cat playbooks/escalation-matrix.md
```

**Understanding playbook design principles:** Each playbook focuses on user impact rather than system symptoms, provides specific commands with expected outputs, includes escalation criteria and contact information, and connects technical investigation to business impact assessment.

---

## Testing Alert Reliability Through Controlled Chaos

The final step is to test the reliability of your entire alerting system through controlled chaos testing and incident simulation. This validation ensures your alerting system can reliably detect service failures and guide appropriate response actions.

### Proving Your System Works

Alert testing requires careful coordination between service disruption and alert monitoring. This approach simulates real service failures while observing alert progression through the complete notification pipeline.

### Step 11: Chaos Testing for Alert Validation

Test availability alerting with a controlled service outage:

```bash
# Record current replica count for restoration
export ORIGINAL_REPLICAS=$(kubectl get deployment sre-demo-app -o jsonpath='{.spec.replicas}')
echo "Current replicas: $ORIGINAL_REPLICAS"

# Scale down to simulate complete outage
echo "Creating controlled outage by scaling to 0 replicas..."
kubectl scale deployment sre-demo-app --replicas=0
```

Expected output:
```
Current replicas: 2
Creating controlled outage by scaling to 0 replicas...
deployment.apps/sre-demo-app scaled
```

**Monitor alert progression:**

First, ensure you have the Prometheus IP address available:

```bash
# Get Prometheus service IP if not already exported
export PROMETHEUS_IP=$(kubectl get service prometheus-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Prometheus alerts URL: http://$PROMETHEUS_IP:9090/alerts"
```

Expected output:
```
Prometheus alerts URL: http://34.9.23.171:9090/alerts
```

**In your browser, navigate to:** `http://$PROMETHEUS_IP:9090/alerts`

**Alternative access method:** If the LoadBalancer IP is not accessible from your browser, use port-forwarding:

```bash
# In a separate terminal, start port-forwarding
kubectl port-forward service/prometheus-service 9090:9090
```

Then access: `http://localhost:9090/alerts`

After approximately 1-2 minutes, you should see the `ServiceUnavailable` alert transition from "Inactive" to "Firing" status. The alert details should show severity as "critical" and description explaining that no healthy application instances are running.

**Understanding alert timing:** The `ServiceUnavailable` alert is configured with `for: 1m`, meaning Prometheus waits 1 minute of failed metrics collection before firing the alert. This prevents false positives from brief network interruptions while ensuring rapid detection of sustained outages.

**Verify service is unreachable:**

```bash
# Confirm service is unavailable
curl -I http://$EXTERNAL_IP/ || echo "Service confirmed unavailable"
```

Expected output:
```
curl: (7) Failed to connect to 104.154.201.227 port 80: Connection refused
Service confirmed unavailable
```

This output confirms that the service disruption affects user-facing functionality, validating that the alert correctly identifies user-impacting problems.

**After 3-5 minutes of testing, restore service:**

```bash
# Restore service
echo "Restoring service to $ORIGINAL_REPLICAS replicas..."
kubectl scale deployment sre-demo-app --replicas=$ORIGINAL_REPLICAS

# Wait for service restoration
kubectl wait --for=condition=available --timeout=180s deployment/sre-demo-app
```

Expected output:
```
Restoring service to 2 replicas...
deployment.apps/sre-demo-app scaled
deployment.apps/sre-demo-app condition met
```

**What this testing demonstrates:** The chaos engineering approach validates that your alerting system can reliably detect service failures and guide appropriate response actions. This experience provides confidence in alert reliability while demonstrating the complete incident lifecycle from detection through resolution.

**Production alert testing:** In production environments, SRE teams apply similar controlled testing to error rate alerts, latency alerts, and SLO burn rate alerts. The fundamental principle remains the same: alerts should fire when users are impacted and resolve when problems are fixed.

**Additional validation approaches:** Production teams often implement synthetic monitoring, canary deployments, and gradual rollout procedures that provide additional layers of reliability validation beyond the foundational chaos testing you've completed.

---

### Understanding Alert Effectiveness

Your chaos testing in Step 11 demonstrated the fundamental principles of alert quality:
- **Signal-to-noise ratio**: Alerts fired when users were actually impacted
- **Time-to-detection**: Alerts triggered within acceptable timeframes
- **Actionable information**: Alerts provided clear indication of the problem

In production environments, SRE teams monitor these same metrics to ensure alerting systems remain effective over time.

---

## Final Objective

By completing this exercise, you should be able to demonstrate:

Your application has well-defined SLIs that measure user experience and SLOs that set appropriate reliability targets. Alert policies trigger on user-impacting problems with minimal false positives, using both threshold-based Prometheus rules and advanced SLO burn rate policies. Incident response playbooks provide clear procedures for common scenarios, and you understand how notification channels ensure appropriate team members receive alerts with sufficient context for rapid response.

### Verification Questions

Test your understanding by answering these questions:

1. **How do** multi-burn-rate alerts balance detection speed with false positive reduction?
   
   **Expected understanding:** Fast burn rates (14.4x) detect rapid budget consumption requiring immediate action, while slow burn rates (6x) catch sustained degradation. Multiple time windows prevent false alarms from brief issues while ensuring both immediate crises and developing problems receive attention.

2. **Why are** SLO-based alerts more effective than threshold-based alerts for user-facing services?
   
   **Expected understanding:** SLO-based alerts measure user impact directly and account for error budget consumption over time. Threshold alerts may fire during normal variations, while SLO alerts fire when service reliability genuinely threatens user experience.

3. **What metrics** would indicate that your alerting system is generating too much noise?
   
   **Expected understanding:** High alert volume with low action rates, frequent alert acknowledgments without resolution, team reports of alert fatigue, or correlation analysis showing many alerts for the same underlying problem.

4. **How should** error budget depletion influence development and operational priorities?
   
   **Expected understanding:** Healthy budgets allow faster deployment velocity and feature development. Depleted budgets shift focus to reliability improvements, deployment freezes, and operational stabilization until service health recovers.

---

## Troubleshooting

### Common Issues

**Alerts not triggering during test scenarios**: Verify that Prometheus is successfully scraping metrics with `kubectl logs deployment/prometheus` and check alerting rule syntax in the Prometheus web interface. Ensure that your application has proper `prometheus.io/scrape` annotations.

**ServiceUnavailable alert not firing when scaling to 0**: Check the alert rule expression syntax and verify that the `job` and `app` labels match your application's actual labels with `kubectl get pods -l app=sre-demo-app --show-labels`.

**Notification channels not receiving alerts**: In educational environments, actual delivery may not be configured. Focus on alert detection in Prometheus and Alertmanager interfaces rather than external notification delivery.

**SLO measurements showing incorrect values**: Verify that your SLI queries return expected results using the Prometheus web interface and ensure that time windows align with your service's behavior patterns.

**Error budget calculations appearing inconsistent**: Check that SLO definitions match your actual service behavior and verify that measurement windows provide sufficient data points for accurate calculations.

### Advanced Troubleshooting

**Debugging Prometheus alerting rules**: Use the Prometheus web interface Rules tab to check rule evaluation status and verify that expressions return expected results during both normal operation and failure scenarios.

**Investigating alert policy effectiveness**: Analyze alert history in Prometheus to identify patterns of false positives and adjust policies based on actual incident correlation and team feedback.

**Optimizing incident response procedures**: Track MTTR metrics for different incident types and refine playbooks based on actual response experiences and post-incident reviews.

---

## Next Steps

You have successfully implemented comprehensive alerting and incident response capabilities that focus on user impact rather than system behavior. You've defined meaningful SLIs and SLOs that guide reliability decisions, created alert policies that notify teams of actionable problems, established incident response procedures that minimize MTTR, and implemented error budget management that balances reliability with development velocity.

**Proceed to [Exercise 6](../exercise6/)** where you will implement production-ready CI/CD pipelines with GitOps principles, establish automated deployment workflows that maintain service reliability, implement rollback procedures and deployment safety measures, and integrate deployment processes with your monitoring and alerting infrastructure.

**Key Concepts to Remember**: Effective alerting focuses on user impact and provides actionable information for problem resolution, SLOs provide objective measures for balancing reliability and development velocity, error budgets enable data-driven decisions about risk tolerance and operational focus, and incident response procedures should minimize MTTR while ensuring thorough problem resolution.

**Before Moving On**: Ensure you can explain how your alerting strategy prevents both alert fatigue and missed incidents, why SLO-based alerting is more effective than traditional threshold-based approaches, and how error budget management guides operational decision-making. In the next exercise, you'll integrate these reliability practices with automated deployment workflows.