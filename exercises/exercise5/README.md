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
- [Alert Design That Doesn't Suck](https://www.youtube.com/watch?v=NoY2ns_VgpE) by Sensu - Practical alerting strategies

**Reference Documentation**:
- [Google SRE Book - Monitoring Distributed Systems](https://sre.google/sre-book/monitoring-distributed-systems/) - Alerting philosophy
- [Google SRE Book - Being On-Call](https://sre.google/sre-book/being-on-call/) - Incident response practices

### Incident Management and Response

**Essential Watching** (15 minutes):
- [Incident Management Best Practices](https://www.youtube.com/watch?v=zoz0ZjfrQ9s) by PagerDuty - Modern incident response
- [Error Budgets and SLOs](https://www.youtube.com/watch?v=y2ILKr8kCJU) by Google Cloud Tech - Using error budgets

**Reference Documentation**:
- [Google Cloud Operations Suite - Alerting](https://cloud.google.com/monitoring/alerts) - Alert policy configuration
- [Site Reliability Workbook - Alerting on SLOs](https://sre.google/workbook/alerting-on-slos/) - Practical SLO alerting

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

### SRE Alert Categories

**Immediate Response Alerts** indicate user-facing problems requiring immediate intervention, such as service unavailability, high error rates, or severe performance degradation.

**Warning Alerts** indicate potential problems that may become user-facing if not addressed, such as resource exhaustion trends, increasing error rates, or capacity approaching limits.

**Informational Notifications** provide context during incidents but don't require immediate action, such as deployment notifications, scaling events, or maintenance status updates.

---

## Defining SLIs and SLOs

### The Foundation of Actionable Alerting

An alert is only as good as the problem it signals. Before we create any alert policies, we must first define what our service's reliability means from a user's perspective. This section guides you through defining **Service Level Indicators (SLIs)** that measure user experience and **Service Level Objectives (SLOs)** that set a clear target for reliability. This approach ensures that every alert we create is tied directly to a potential or actual user-facing issue, preventing alert fatigue and focusing our efforts where they matter most.

### Step 1: Analyze Your Application's User Experience

Examine your application from the user's perspective to identify key reliability indicators:

```bash
# Navigate to Exercise 5 directory
cd exercises/exercise5
```

```bash
# Review your application's user-facing functionality
export EXTERNAL_IP=$(kubectl get service sre-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

```bash
# Test root endpoint (status code + latency)
curl -w "%{http_code} %{time_total}s\n" http://$EXTERNAL_IP/
```

```bash
# Test stores endpoint
curl -w "%{http_code} %{time_total}s\n" http://$EXTERNAL_IP/stores
```

```bash
# Test individual store endpoint
curl -w "%{http_code} %{time_total}s\n" http://$EXTERNAL_IP/stores/1
```

```bash
# Examine current metrics to understand baseline performance
export PROMETHEUS_IP=$(kubectl get service prometheus-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Review metrics at: http://$PROMETHEUS_IP:9090"
```

Understanding your application's user experience helps identify which metrics directly correlate with user satisfaction and business impact.

### Step 2: Define Service Level Indicators (SLIs)

Review the SLI definitions provided for your application:

```bash
# Examine the SLI configuration
cat sli-definitions.yaml
```

```bash
# Review SLO targets and rationale
cat slo-config.yaml
```

The SLI definitions focus on availability (successful requests), latency (response time), and quality (business operation success), measured from the user's perspective rather than internal system metrics.

### Step 3: Implement SLO Monitoring

Deploy the SLO monitoring configuration to Google Cloud:

```bash
# Create SLOs in Google Cloud Monitoring
gcloud monitoring slos create --config-from-file=slo-config.yaml
```

```bash
# Verify SLO creation
gcloud monitoring slos list
```

```bash
# Check SLO status
gcloud monitoring slos describe projects/$PROJECT_ID/services/sre-demo-service/serviceLevelObjectives/availability-slo
```

SLO monitoring provides baseline measurement and error budget tracking that informs both alerting decisions and development prioritization.

---

## Implementing Alert Policies

### Creating the Signals for Response

You have now defined your service's reliability targets. This section is where you implement the "tripwire" that tells you when those targets are at risk. You will deploy and configure alert policies in both **Prometheus** for fast, metrics-based alerting and **Google Cloud Monitoring** for advanced, SLO-based alerting. This dual approach gives you both the speed needed for immediate response and the intelligence required to alert on the depletion of your error budget.

### Step 4: Deploy Prometheus Alerting Rules

Configure Prometheus alerting rules for immediate problem detection:

```bash
# Examine the alerting rules
cat k8s/alerting/prometheus-rules.yaml
```

```bash
# Deploy alerting rules to your cluster
kubectl apply -f k8s/alerting/prometheus-rules.yaml
```

```bash
# Verify rules are loaded
kubectl logs -l app=prometheus | grep "Loading configuration file"
```

Prometheus alerting rules provide fast, metrics-based detection of problems with customizable thresholds and evaluation windows.

### Step 5: Configure Alertmanager for Alert Routing

Deploy Alertmanager to handle alert routing and notification:

```bash
# Review Alertmanager configuration
cat k8s/alerting/alertmanager-config.yaml
```

```bash
# Deploy Alertmanager
kubectl apply -f k8s/alerting/alertmanager-deployment.yaml
kubectl apply -f k8s/alerting/alertmanager-config.yaml
```

```bash
# Wait for Alertmanager to be ready
kubectl wait --for=condition=available --timeout=300s deployment/alertmanager
```

```bash
# Check Alertmanager status
kubectl get service alertmanager-service
```

Alertmanager handles alert deduplication, grouping, and routing to appropriate notification channels based on severity and team responsibility.

### Step 6: Create Google Cloud Alert Policies

Implement Google Cloud Monitoring alert policies for SLO-based alerting:

```bash
# Create alert policies using gcloud CLI
gcloud alpha monitoring policies create --policy-from-file=alerting/availability-alert-policy.yaml
gcloud alpha monitoring policies create --policy-from-file=alerting/latency-alert-policy.yaml
gcloud alpha monitoring policies create --policy-from-file=alerting/error-budget-alert-policy.yaml
```

```bash
# List created policies
gcloud alpha monitoring policies list
```

```bash
# Test policy configuration
gcloud alpha monitoring policies describe projects/$PROJECT_ID/alertPolicies/ALERT_POLICY_ID
```

Google Cloud alert policies provide integration with Google Cloud notification channels and error budget alerting based on SLO burn rates.

---

## Building Incident Response Workflows

### Connecting the Alert to the Human

An alert that isn't seen or acted upon is useless. The most robust alerting system is only part of the solution; the other part is the human process for handling incidents. This section focuses on building the workflows that connect your automated alerts to your on-call team. You will configure notification channels and review incident response playbooks to ensure that when an alert triggers, the right person is notified with the right context, enabling a fast and effective resolution.

### Step 7: Establish Notification Channels

Configure notification channels for different alert severities:

```bash
# Create notification channels
cat alerting/notification-channels.yaml
```

```bash
# Deploy notification channels
gcloud alpha monitoring channels create --channel-from-file=alerting/email-notification.yaml
gcloud alpha monitoring channels create --channel-from-file=alerting/slack-notification.yaml
```

```bash
# Verify channels are created
gcloud alpha monitoring channels list
```

Multiple notification channels ensure that alerts reach appropriate team members based on severity, time of day, and escalation procedures.

### Step 8: Test Alert Generation

Use the provided testing script to verify your alerting infrastructure:

```bash
# Make the alert testing script executable
chmod +x scripts/test-alerts.sh
```

```bash
# Run comprehensive alert testing
./scripts/test-alerts.sh

# Alternative: Test specific alert types
# ./scripts/test-alerts.sh availability    # Test availability alerts
# ./scripts/test-alerts.sh latency        # Test latency alerts  
# ./scripts/test-alerts.sh error-budget   # Test error budget alerts
```

Alert testing ensures that your policies trigger correctly and notifications reach intended recipients within acceptable timeframes.

### Step 9: Create Incident Response Playbooks

Review the incident response procedures:

```bash
# Examine incident response playbooks
cat playbooks/availability-incident.md
cat playbooks/performance-incident.md
cat playbooks/error-budget-depletion.md
```

```bash
# Review escalation procedures
cat playbooks/escalation-matrix.md
```

Incident response playbooks provide structured procedures that reduce Mean Time to Resolution (MTTR) and ensure consistent response quality across team members.

---

## Testing Alert Reliability

### Proving Your System Works

You have defined your SLIs, built your alerts, and established your response workflows. But how do you know if it all works as intended? The final and most critical step is to test the reliability of your entire alerting system. This section guides you through controlled chaos testing and incident simulation to validate that your alerts trigger correctly, your notifications are delivered, and your response procedures are effective. This proactive validation builds confidence and prepares your team for real-world incidents.

### Step 10: Chaos Testing for Alert Validation

Use controlled failure injection to validate alert effectiveness:

```bash
# Review chaos testing approach
cat scripts/chaos-testing.sh

# Run controlled failure scenarios (choose one at a time)
# chmod +x scripts/chaos-testing.sh

# Test availability alerting
# ./scripts/chaos-testing.sh unavailable 300  # Make service unavailable for 5 minutes

# Test latency alerting  
# ./scripts/chaos-testing.sh slow 300         # Inject latency for 5 minutes

# Test error rate alerting
# ./scripts/chaos-testing.sh errors 300       # Increase error rate for 5 minutes
```

Chaos testing validates that your alerts trigger appropriately during real failure scenarios and that recovery procedures work effectively.

### Step 11: Alert Runbook Validation

Test incident response procedures during controlled scenarios:

```bash
# Use the incident simulation script
chmod +x scripts/incident-simulation.sh
```

```bash
# Run incident simulation
./scripts/incident-simulation.sh
```

```bash
# Monitor alert generation and response
echo "Check these locations during simulation:"
echo "Prometheus alerts: http://$PROMETHEUS_IP:9090/alerts"
echo "Alertmanager: http://$(kubectl get service alertmanager-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):9093"
echo "Google Cloud Alerting: https://console.cloud.google.com/monitoring/alerting?project=$PROJECT_ID"
```

Incident simulation ensures that team members can follow playbooks effectively and that alert escalation procedures function correctly.

---

## Advanced Alerting Strategies

### Step 12: Implement Multi-Window, Multi-Burn-Rate Alerts

Configure advanced SLO alerting that balances sensitivity with noise reduction:

```bash
# Review multi-burn-rate alert configuration
cat alerting/advanced-slo-alerts.yaml
```

```bash
# Deploy advanced alerting rules
kubectl apply -f alerting/advanced-slo-alerts.yaml
```

```bash
# Verify advanced rules are active
kubectl exec deployment/prometheus -- promtool query instant 'ALERTS{alertname=~".*SLO.*"}'
```

Multi-burn-rate alerting provides fast notification of severe problems while avoiding false positives during normal operational variations.

### Step 13: Error Budget Policy Implementation

Implement error budget policies that guide development and operational decisions:

```bash
# Review error budget policies
cat policies/error-budget-policy.yaml
```

```bash
# Create error budget dashboards
gcloud monitoring dashboards create --config-from-file=dashboards/error-budget-dashboard.json
```

```bash
# Check error budget status
echo "Monitor error budgets at:"
echo "https://console.cloud.google.com/monitoring/overview?project=$PROJECT_ID"
```

Error budget policies provide objective criteria for making trade-offs between reliability and feature velocity based on actual user impact.

### Step 14: Alert Quality Metrics

Implement metrics to track and improve alert quality:

```bash
# Deploy alert quality monitoring
cat monitoring/alert-quality-metrics.yaml
```

```bash
# Create alert quality dashboard
gcloud monitoring dashboards create --config-from-file=dashboards/alert-quality-dashboard.json
```

```bash
# Review alert effectiveness queries
cat monitoring/alert-quality-queries.md
```

Alert quality metrics help teams identify and eliminate noisy alerts while ensuring that genuine problems receive appropriate attention.

---

## Final Objective

By completing this exercise, you should be able to demonstrate:

Your application has well-defined SLIs that measure user experience and SLOs that set appropriate reliability targets. Alert policies trigger on user-impacting problems with minimal false positives, using both fast Prometheus rules and SLO-based Google Cloud policies. Incident response playbooks provide clear procedures for common scenarios, and notification channels ensure appropriate team members receive alerts. The alerting system focuses on actionable problems and provides sufficient context for effective response.

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

**Notification channels not receiving alerts**: Confirm notification channel configuration with `gcloud alpha monitoring channels list` and test channel connectivity using Google Cloud Console notification testing features.

**SLO measurements showing incorrect values**: Verify that your SLI queries return expected results using Prometheus web interface and ensure that time windows align with your service's behavior patterns.

**Error budget calculations appearing inconsistent**: Check that SLO definitions match your actual service behavior and verify that measurement windows provide sufficient data points for accurate calculations.

**Alert fatigue from excessive notifications**: Review alert policies for overly sensitive thresholds, implement proper alert grouping and deduplication, and consider using multi-burn-rate alerting to reduce noise.

### Advanced Troubleshooting

**Debugging Prometheus alerting rules**: Use `kubectl exec deployment/prometheus -- promtool check rules /etc/prometheus/rules/*.yml` to validate rule syntax and test alert conditions with historical data.

**Investigating alert policy effectiveness**: Analyze alert history in Google Cloud Monitoring to identify patterns of false positives and adjust policies based on actual incident correlation.

**Optimizing incident response procedures**: Track MTTR metrics for different incident types and refine playbooks based on actual response experiences and post-incident reviews.

---

## Next Steps

You have successfully implemented comprehensive alerting and incident response capabilities that focus on user impact rather than system behavior. You've defined meaningful SLIs and SLOs that guide reliability decisions, created alert policies that notify teams of actionable problems, established incident response procedures that minimize MTTR, and implemented error budget management that balances reliability with development velocity.

**Proceed to [Exercise 6](../exercise6/)** where you will implement production-ready CI/CD pipelines with GitOps principles, establish automated deployment workflows that maintain service reliability, implement rollback procedures and deployment safety measures, and integrate deployment processes with your monitoring and alerting infrastructure.

**Key Concepts to Remember**: Effective alerting focuses on user impact and provides actionable information for problem resolution, SLOs provide objective measures for balancing reliability and development velocity, error budgets enable data-driven decisions about risk tolerance and operational focus, and incident response procedures should minimize MTTR while ensuring thorough problem resolution.

**Before Moving On**: Ensure you can explain how your alerting strategy prevents both alert fatigue and missed incidents, and why SLO-based alerting is more effective than traditional threshold-based approaches. In the next exercise, you'll integrate these reliability practices with automated deployment workflows.