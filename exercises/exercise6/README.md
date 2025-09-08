# Exercise 6: Production CI/CD with GitOps

## Table of Contents

* [Introduction](#introduction)
* [Learning Objectives](#learning-objectives)
* [Prerequisites](#prerequisites)
* [Theory Foundation](#theory-foundation)
* [Understanding GitOps for SRE](#understanding-gitops-for-sre)
* [Setting Up ArgoCD for Automated Deployments](#setting-up-argocd-for-automated-deployments)
* [Implementing GitOps Deployment Pipelines](#implementing-gitops-deployment-pipelines)
* [Exploring GitOps Operations](#exploring-gitops-operations)
* [Deployment Safety Gates and SLO Validation](#deployment-safety-gates-and-slo-validation)
* [Automated Rollback and Recovery](#automated-rollback-and-recovery)
* [Testing End-to-End Pipeline Reliability](#testing-end-to-end-pipeline-reliability)
* [Final Objective](#final-objective)
* [Troubleshooting](#troubleshooting)
* [Next Steps](#next-steps)

---

## Introduction

In this exercise, you will implement production-ready GitOps principles using ArgoCD for automated deployment management. You'll establish declarative deployment workflows that integrate with your monitoring infrastructure from Exercises 4-5, implement deployment safety gates based on SLO compliance, and establish automated rollback capabilities that minimize Mean Time to Resolution (MTTR).

This exercise demonstrates how modern SRE teams manage deployments with reliability, traceability, and minimal human intervention while maintaining service availability through automated validation and recovery procedures.

---

## Learning Objectives

By completing this exercise, you will understand:

- **GitOps Implementation**: How to implement declarative, Git-based deployment workflows that eliminate configuration drift
- **ArgoCD Configuration**: How to deploy and configure ArgoCD for continuous deployment with proper security
- **Deployment Safety Gates**: How to use SLO metrics to validate deployment success automatically
- **Automated Rollback**: How to implement SLO-based rollback automation that responds to service degradation
- **Operational Benefits**: How GitOps provides audit trails, reduces manual effort, and improves deployment reliability
- **Release Reliability**: How to coordinate releases with incident response and monitoring systems

---

## Prerequisites

Before starting this exercise, ensure you have completed:

- Exercise 1: Cloud Development Environment & SRE Application
- Exercise 2: Container Builds & GitHub Actions  
- Exercise 3: Kubernetes Deployment
- Exercise 4: Cloud Monitoring Stack
- Exercise 5: Alerting and Response

**Verify your monitoring infrastructure is operational:**

```bash
# Check that your complete observability stack is working
kubectl get pods -l app=prometheus
kubectl get pods -l app=sre-demo-app
export PROMETHEUS_IP=$(kubectl get service prometheus-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Prometheus accessible at: http://$PROMETHEUS_IP:9090"
```

**Expected output:**
```
NAME                          READY   STATUS    RESTARTS   AGE
prometheus-7b8c4f9d4c-xyz12   1/1     Running   0          4h

NAME                            READY   STATUS    RESTARTS   AGE
sre-demo-app-7458c58c57-abc34   1/1     Running   0          4h
sre-demo-app-7458c58c57-def56   1/1     Running   0          4h

Prometheus accessible at: http://35.9.23.171:9090
```

---

## Theory Foundation

### GitOps and Continuous Deployment

**Essential Watching** (15 minutes):
- [What is GitOps, How GitOps works and Why it's so useful](https://www.youtube.com/watch?v=f5EpcWp0THw) by TechWorld with Nana - Quick GitOps overview
- [ArgoCD Tutorial for Beginners](https://www.youtube.com/watch?v=MeU5_k9ssrs) by TechWorld with Nana - ArgoCD implementation

**Reference Documentation**:
- [GitOps Principles](https://opengitops.dev/) - Official GitOps working group principles
- [ArgoCD Getting Started](https://argo-cd.readthedocs.io/en/stable/getting_started/) - Quick start guide

### SRE Deployment Practices

**Essential Watching** (10 minutes):
- [SRE Deployment Best Practices](https://www.youtube.com/watch?v=AWVTKBUnoIg) by ByteByteGo - Production deployment patterns

**Reference Documentation**:
- [Google SRE Book - Release Engineering](https://sre.google/sre-book/release-engineering/) - Production deployment practices

### Key Concepts You'll Learn

**GitOps Benefits for SRE** include declarative infrastructure that prevents configuration drift, Git-based audit trails for all deployment changes, automated rollback capabilities when monitoring detects issues, and clear separation between application development and deployment operations.

**Deployment Safety Gates** use your existing monitoring infrastructure to validate that deployments don't violate SLO targets. This includes automated error rate validation, latency monitoring during deployments, and SLO compliance checks before marking deployments successful.

**Automated Recovery Systems** respond to deployment-related SLO violations by automatically reverting to the last known good version, minimizing user impact and reducing Mean Time to Resolution without requiring human intervention during incidents.

---

## Understanding GitOps for SRE

Your current deployment approach from Exercise 2 builds container images automatically but relies on manual kubectl commands for deployment management. This creates reliability challenges including potential configuration drift, manual rollback procedures, and lack of deployment audit trails.

### Current State vs GitOps Target

**Current Manual Process** requires direct cluster access for deployments, uses imperative commands that can create inconsistent state, provides limited deployment history, and relies on human intervention for rollback during incidents.

**GitOps Target State** uses Git repositories as the single source of truth for deployment configuration. ArgoCD continuously monitors Git for changes and automatically applies updates, validates deployments against SLO metrics, and provides automated rollback when monitoring indicates service degradation.

### Why GitOps Matters for Reliability

**Reduced Mean Time to Resolution** through automated rollback when SLO violations are detected during deployments. **Improved Change Management** through Git-based approval workflows and complete audit trails. **Decreased Human Error** through automation of manual deployment processes that are error-prone during incident response.

---

## Setting Up ArgoCD for Automated Deployments

### Preparing the GitOps Engine

ArgoCD serves as the automation engine that continuously synchronizes your desired deployment state (stored in Git) with your actual cluster state. This section guides you through deploying ArgoCD with production-ready configuration.

### Step 1: Navigate to Exercise Environment and Deploy ArgoCD

Set up your working directory and install ArgoCD:

```bash
# Navigate to Exercise 6 directory
cd exercises/exercise6
```

```bash
# Install ArgoCD using provided automation
chmod +x scripts/setup-argocd.sh
./scripts/setup-argocd.sh
```

**Expected output:**
```
[SUCCESS] ArgoCD installation manifest applied
[INFO] Configuring LoadBalancer access...
service/argocd-server-lb created
[SUCCESS] LoadBalancer service configured
[INFO] Waiting for ArgoCD components to be ready...
deployment.apps/argocd-server condition met
deployment.apps/argocd-repo-server condition met
deployment.apps/argocd-dex-server condition met
deployment.apps/argocd-applicationset-controller condition met
[SUCCESS] ArgoCD components are ready
[INFO] Waiting for LoadBalancer IP assignment...
[SUCCESS] LoadBalancer IP assigned: 34.31.169.228
ARGOCD_IP=34.31.169.228
[INFO] Retrieving initial admin password...
[SUCCESS] Initial admin password retrieved
ARGOCD_PASSWORD=5yK1I0fkL2HyrsxV
[INFO] ArgoCD installation completed!

======================================================
           ArgoCD Access Information
======================================================
URL: https://34.31.169.228
Username: admin
Password: PASSWORD

Note: Accept the self-signed certificate in your browser
======================================================
```

**Wait for all ArgoCD components to be ready:**
**ArgoCD deployment takes 3-5 minutes.** Wait until all pods show `Running` status before proceeding.

```bash
# Monitor ArgoCD deployment
kubectl get pods -n argocd
```

**Access the ArgoCD web interface** using the URL from your output (accept the self-signed certificate). The interface provides visual representation of applications, deployment status, and synchronization history.

**Test web interface access:**
- Navigate to the ARGOCD_IP URL from your terminal output
- Accept the self-signed certificate when prompted by your browser
- Login with username `admin` and the password from your terminal output
- Verify you can see the ArgoCD dashboard (should be empty initially)

**Install ArgoCD CLI for command-line management:**

```bash
# Install ArgoCD CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# Login to ArgoCD
argocd login $ARGOCD_IP --username admin --password $ARGOCD_PASSWORD --insecure
```

**Expected output:**
```
'admin:login' logged in successfully
Context '$ARGOCD_IP' updated
```

---

## Implementing GitOps Deployment Pipelines

### Connecting Code Changes to Automated Deployments

This section establishes the GitOps deployment pipeline that connects your application state to cluster deployment through declarative manifests, demonstrating the core principles of GitOps workflows.

### Step 2: Configure GitOps Repository Structure

Examine and understand the GitOps deployment configuration:

```bash
# Review the GitOps deployment manifests
ls -la k8s/gitops/
cat k8s/gitops/deployment.yaml
```

```bash
# Examine the ArgoCD application configuration
cat k8s/argocd/application.yaml
```

**Understanding GitOps structure:** The `k8s/gitops/` directory contains declarative Kubernetes manifests that define your application's desired state. ArgoCD monitors this directory and automatically applies changes when manifests are updated.

**Key GitOps principles implemented:**
- **Declarative Configuration**: All deployment state defined in version-controlled YAML
- **Git as Source of Truth**: Changes must go through Git workflows
- **Automated Synchronization**: ArgoCD applies changes without manual intervention
- **Complete Auditability**: All changes tracked through Git commit history

### Step 3: Create ArgoCD Application

Configure ArgoCD to manage your SRE demo application:

**Important:** Before applying the ArgoCD application, update the repository URL to match your GitHub repository.

**Edit `k8s/argocd/application.yaml` line 16:**

```yaml
# CURRENT:
repoURL: https://github.com/YOUR_USERNAME/kubernetes-sre-cloud-native

# SHOULD BE (replace with your actual GitHub username):
repoURL: https://github.com/your-actual-username/kubernetes-sre-cloud-native
```

**Also update the container image reference in `k8s/gitops/deployment.yaml` line 38:**

```yaml
# CURRENT:
image: gcr.io/PROJECT_ID/sre-demo-app:latest

# SHOULD BE (replace with your actual registry path from previous exercises):
image: us-central1-docker.pkg.dev/your-project-id/sre-demo-app/sre-demo-app:latest
```

**Apply the ArgoCD application configuration:**

```bash
# Apply the ArgoCD application configuration
kubectl apply -f k8s/argocd/application.yaml
```

**Expected output:**
```
application.argoproj.io/sre-demo-gitops created
```

**Verify application creation:**

```bash
# Check application status
argocd app get sre-demo-gitops
```

**Expected output:**
```
Name:               argocd/sre-demo-gitops
Project:            default
Server:             https://kubernetes.default.svc
Namespace:          default
URL:                https://34.31.169.228/applications/sre-demo-gitops
Source:
- Repo:             https://github.com/your-username/kubernetes-sre-cloud-native
  Target:           HEAD
  Path:             exercises/exercise6/k8s/gitops
SyncWindow:         Sync Allowed
Sync Policy:        Automated (Prune)
Sync Status:        OutOfSync from HEAD (4a9a460)
Health Status:      Progressing

GROUP  KIND        NAMESPACE  NAME               STATUS     HEALTH       HOOK  MESSAGE
apps   Deployment  default    sre-demo-app       OutOfSync  Progressing        deployment.apps/sre-demo-app configured
       Service     default    sre-demo-headless  Synced     Healthy            
       Service     default    sre-demo-service   Synced     Healthy            
```

**Access the ArgoCD application view:**

Navigate to the URL shown in the `argocd app get` output (e.g., `https://ARGOCD_IP/applications/sre-demo-gitops`).

**Understanding ArgoCD Application Status**

The ArgoCD web interface shows your GitOps deployment in action. Key status indicators you'll observe:

**Sync Status Progression:**
- **🟡 OutOfSync** → **🟢 Sync OK**: ArgoCD detects Git changes and applies them to the cluster
- **🔄 Progressing** → **🟢 Healthy**: Kubernetes resources are being created/updated and reaching ready state

**Resource Tree View** displays your application components:
- **Deployment** (sre-demo-app): Your application pods with replica management
- **Services** (sre-demo-service, sre-demo-headless): Network access and service discovery
- **Individual Pods**: Each pod instance with age and status indicators

**Visual Cues in the Interface:**
- **Green indicators**: Resources are healthy and synchronized
- **Blue/Gray pods**: Individual application instances managed by the deployment
- **Resource hierarchy**: Shows parent-child relationships between Kubernetes resources
- **Timeline information**: Displays how long resources have been running

**This demonstrates GitOps declarative management** - ArgoCD continuously monitors your Git repository and ensures the cluster state matches your defined configuration. The visual interface provides real-time insight into deployment health and synchronization status that would require multiple kubectl commands to gather manually.

**If ArgoCD shows OutOfSync:**

```bash
# Trigger manual sync (especially useful in development environments)
argocd app sync sre-demo-gitops

# Verify sync completed successfully
kubectl get pods -l app=sre-demo-app
kubectl get deployment sre-demo-app -o jsonpath='{.spec.template.spec.containers[0].image}'
```

**Note**: In production environments, automated sync typically occurs within 30-60 seconds. Development environments like Codespaces may require manual sync due to network latency and resource constraints.

---

## Exploring GitOps Operations

### Understanding GitOps Through Hands-On Exploration

This section focuses on understanding GitOps operations through direct interaction with ArgoCD, demonstrating how declarative configuration management works in practice without the complexity of full CI/CD automation.

### Step 4: Explore ArgoCD Interface and GitOps Concepts

**Navigate to your ArgoCD application** and explore the GitOps interface:

**Application Overview**: View sync status, health indicators, and resource hierarchy to understand how ArgoCD visualizes your application state.

**Resource Tree**: Examine how ArgoCD displays the relationships between Kubernetes resources (Deployment → ReplicaSet → Pods → Services).

**Sync Controls**: Understand the difference between manual and automatic synchronization options available in the interface.

**History Tab**: Review deployment history and previous configurations to see how GitOps maintains change tracking.

**Practice GitOps operations using ArgoCD CLI:**

```bash
# View current application status
argocd app get sre-demo-gitops

# Trigger manual sync to ensure latest state
argocd app sync sre-demo-gitops

# Check sync history
argocd app history sre-demo-gitops

# View application details in YAML format
argocd app get sre-demo-gitops -o yaml
```

### Step 5: Experiment with GitOps Configuration Changes

**Make a controlled change to demonstrate GitOps workflow:**

```bash
# Make a small, safe change to test GitOps sync
sed -i 's/replicas: 2/replicas: 3/g' k8s/gitops/deployment.yaml

# Verify the change
grep "replicas:" k8s/gitops/deployment.yaml
```

**Commit and observe GitOps automation:**

```bash
git add k8s/gitops/deployment.yaml
git commit -m "gitops: Scale application to 3 replicas for testing"
git push origin main
```

**Monitor ArgoCD detect and apply the change:**

```bash
# Watch ArgoCD sync the change (this may take 1-3 minutes)
argocd app get sre-demo-gitops -w

# Or check periodically
watch -n 10 'argocd app get sre-demo-gitops'
```

**Observe the scaling operation:**

```bash
# Verify that pods scaled to 3 replicas
kubectl get pods -l app=sre-demo-app

# Check deployment status
kubectl get deployment sre-demo-app
```

**Expected output:**
```
NAME                            READY   STATUS    RESTARTS   AGE
sre-demo-app-74b756bb8b-abc12   1/1     Running   0          5m
sre-demo-app-74b756bb8b-def34   1/1     Running   0          5m
sre-demo-app-74b756bb8b-ghi56   1/1     Running   0          2m

NAME           READY   UP-TO-DATE   AVAILABLE   AGE
sre-demo-app   3/3     3            3           2h
```

**Explore the visual diff in ArgoCD web interface:**
- Navigate to your application in the ArgoCD UI
- Click on the Deployment resource
- Review the "Last Sync" information showing what changed
- Examine the "Desired Manifest" vs "Live Manifest" comparison

### Step 6: Understand GitOps Rollback Capabilities

**Test ArgoCD's rollback functionality:**

```bash
# View deployment history to see available revisions
argocd app history sre-demo-gitops

# Rollback to previous revision (before scaling)
argocd app rollback sre-demo-gitops <previous-revision-id>

# Watch the rollback process
kubectl get pods -l app=sre-demo-app -w
```

**Key GitOps concepts demonstrated:**
- **Declarative State Management**: Changes are defined in Git and applied automatically
- **Audit Trail**: Complete history of changes with commit messages and timestamps
- **Rollback Capability**: Easy reversion to previous known-good states
- **Visual Operations**: Clear interface showing current vs desired state
- **Automated Synchronization**: No manual kubectl commands required for deployments

**Reset to desired state:**

```bash
# Reset replicas back to 2 for consistency
sed -i 's/replicas: 3/replicas: 2/g' k8s/gitops/deployment.yaml
git add k8s/gitops/deployment.yaml
git commit -m "gitops: Reset to 2 replicas"
git push origin main
```

---

## Deployment Safety Gates and SLO Validation

### Using Monitoring Data to Validate Deployments

This section implements safety mechanisms that prevent problematic deployments from degrading user experience by using your existing monitoring infrastructure to validate SLO compliance.

### Step 7: Implement SLO-Based Deployment Validation

Configure deployment validation that uses your Prometheus monitoring to ensure deployments maintain service reliability:

```bash
# Examine the SLO validation configuration
cat monitoring/slo-validation.yaml
```

**Key validation checks implemented:**

**Availability SLO Validation** ensures successful request rate stays above 99.5% during deployment windows.

**Latency SLO Validation** verifies that 95% of requests complete within 500ms after deployment.

**Error Rate Validation** confirms that 5xx error rates remain below 1% post-deployment.

**Business Operation Validation** ensures core functionality maintains 99% success rates.

```bash
# Deploy SLO validation configuration
kubectl apply -f monitoring/slo-validation.yaml
```

**Expected output:**
```
configmap/slo-validation-queries created
prometheusrule.monitoring.coreos.com/deployment-validation created
```

**Test validation queries against your current system:**

```bash
# Test availability SLO query
curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=sum(rate(http_requests_total{status_code!~\"5..\"}[5m])) / sum(rate(http_requests_total[5m])) * 100" | jq '.data.result[0].value[1]'
```

**Expected output:**
```
"100"
```

This confirms your availability SLO is currently at 100%, providing the baseline for deployment validation.

### Step 8: Configure Automated Deployment Health Checks

Set up comprehensive health validation for new deployments:

```bash
# Review deployment health check configuration
cat scripts/deployment-health-check.sh
chmod +x scripts/deployment-health-check.sh
```

```bash
# Test deployment health check logic
./scripts/deployment-health-check.sh test
```

**Expected output:**
```
[INFO] Deployment Health Check - Test Mode
[INFO] Checking application endpoints...
[SUCCESS] Health endpoint responding correctly
[SUCCESS] Metrics endpoint accessible
[SUCCESS] Business endpoints functional
[INFO] Checking SLO compliance...
[SUCCESS] All SLOs within acceptable ranges
[TEST] Deployment health check validated successfully
```

**Understanding health check validation:** The system verifies that all application endpoints respond correctly, Prometheus metrics are being collected properly, SLO targets are being met consistently, and business functionality works as expected before marking deployments successful.

---

## Automated Rollback and Recovery

### Minimizing Impact Through Intelligent Automation

This section implements automated rollback systems that respond to SLO violations by reverting to known good application versions, minimizing user impact without requiring human intervention.

### Step 9: Implement SLO-Based Rollback Automation

Configure rollback automation that monitors SLO compliance and triggers recovery when deployments cause service degradation:

```bash
# Examine rollback automation configuration
cat policies/rollback-automation.yaml
```

**Rollback trigger conditions:**

**Availability SLO Violation** triggers rollback when successful request rate drops below 99.5% for more than 2 minutes.

**Latency SLO Violation** initiates rollback when P95 latency exceeds 800ms for more than 5 minutes.

**Error Rate Spike** activates rollback when 5xx error rate exceeds 5% for more than 1 minute.

**Business Operation Failure** triggers rollback when core operations drop below 95% success rate.

```bash
# Deploy rollback automation
kubectl apply -f policies/rollback-automation.yaml
```

**Expected output:**
```
prometheusrule.monitoring.coreos.com/rollback-automation created
```

```bash
# Review and test rollback automation script
cat scripts/rollback-automation.sh
chmod +x scripts/rollback-automation.sh
./scripts/rollback-automation.sh test
```

**Expected output:**
```
[INFO] Rollback Automation - Test Mode
[INFO] Checking SLO compliance...
[SUCCESS] Availability SLO: 100.0% (target: 99.5%)
[SUCCESS] Latency SLO: 95.8% under 500ms (target: 95%)
[SUCCESS] Error Rate: 0.0% (threshold: 5%)
[SUCCESS] Business Operations: 100.0% (target: 99%)
[INFO] All SLOs within acceptable ranges - no rollback needed
[TEST] Rollback automation logic validated successfully
```

### Step 10: Test Rollback with Controlled Deployment Failure

Simulate a deployment issue to validate rollback automation:

```bash
# Create a backup of current working configuration
cp k8s/gitops/deployment.yaml k8s/gitops/deployment-backup.yaml

# Simulate deployment issue by setting invalid resource requests
sed -i 's/memory: 128Mi/memory: 10Gi/g' k8s/gitops/deployment.yaml
```

**This change creates unrealistic memory requests that will cause deployment issues,** allowing you to test rollback without affecting service functionality.

**Trigger the problematic deployment:**

```bash
# Commit the problematic change to trigger ArgoCD sync
git add k8s/gitops/deployment.yaml
git commit -m "test: Simulate deployment failure for rollback validation"
git push origin main
```

**Monitor the deployment and rollback process:**

```bash
# Watch ArgoCD application status in real-time
argocd app get sre-demo-gitops -w
```

**Expected behavior:**
1. **ArgoCD detects** configuration change and attempts deployment
2. **Kubernetes fails** to schedule pods due to resource constraints
3. **Monitoring detects** deployment issues or SLO violations
4. **Rollback automation** triggers and reverts configuration
5. **Service returns** to healthy state automatically

**Restore proper configuration:**

```bash
# Stop watching (Ctrl+C) and restore working configuration
cp k8s/gitops/deployment-backup.yaml k8s/gitops/deployment.yaml
git add k8s/gitops/deployment.yaml
git commit -m "restore: Fix deployment after rollback test"
git push origin main

# Clean up
rm k8s/gitops/deployment-backup.yaml
```

---

## Testing End-to-End Pipeline Reliability

### Validating Complete GitOps Workflow

This section validates the complete GitOps workflow functionality including deployment management, monitoring integration, and operational procedures.

### Step 11: Verify Deployment Success and Monitoring Integration

Confirm that your GitOps deployment is functioning correctly and monitoring continues to work:

```bash
# Verify current deployment is running correctly
kubectl get pods -l app=sre-demo-app
kubectl describe deployment sre-demo-app | grep Image:
```

**Test application functionality:**

```bash
# Verify application endpoints work correctly
export EXTERNAL_IP=$(kubectl get service sre-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

curl http://$EXTERNAL_IP/health
curl http://$EXTERNAL_IP/deployment
```

**Expected output:**
```
{"status":"ready","timestamp":1756767389.123456}

{
  "deployment_method": "gitops",
  "version": "1.2.0",
  "environment": "production",
  "features": {
    "automated_rollback": true,
    "slo_validation": true,
    "blue_green_ready": true,
    "monitoring_integration": true
  }
}
```

**Verify monitoring continues to collect metrics:**

```bash
# Check that Prometheus is scraping application metrics
curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=up{job=\"sre-demo-app\"}" | jq '.data.result'
```

### Step 12: Validate GitOps Audit Trail and Operational Benefits

Examine the audit trail and operational improvements provided by GitOps:

```bash
# Review Git commit history showing deployment changes
git log --oneline -10
```

**Expected output showing clear audit trail:**
```
abc123ef restore: Fix deployment after rollback test
def456gh test: Simulate deployment failure for rollback validation
ghi789jk gitops: Reset to 2 replicas
jkl012mn gitops: Scale application to 3 replicas for testing
```

**Check ArgoCD application history:**

```bash
# View ArgoCD deployment history
argocd app history sre-demo-gitops
```

**Expected output:**
```
ID  DATE                           REVISION
10  2025-09-06 15:42:33 +0000 UTC  abc123ef (restore: Fix deployment after rollback test)
9   2025-09-06 15:38:21 +0000 UTC  def456gh (test: Simulate deployment failure)
8   2025-09-06 15:35:18 +0000 UTC  ghi789jk (gitops: Reset to 2 replicas)
```

**Demonstrate operational benefits:**

```bash
# Show declarative deployment state
argocd app get sre-demo-gitops --output yaml | grep -A5 -B5 "syncPolicy\|health\|sync"
```

**GitOps benefits demonstrated:**
- **Complete Audit Trail**: Every deployment change tracked in Git
- **Declarative State**: Current deployment state visible and version-controlled
- **Automated Recovery**: Rollback procedures tested and validated
- **Monitoring Integration**: SLO compliance validated automatically
- **Reduced Manual Effort**: Deployments managed through Git workflows

---

## Final Objective

By completing this exercise, you should be able to demonstrate:

Your application deploys using GitOps principles with ArgoCD managing automated synchronization from Git. You understand how to make declarative configuration changes that ArgoCD automatically applies to your cluster. The deployment pipeline integrates with your monitoring infrastructure to validate SLO compliance. Automated rollback systems respond to deployment-related SLO violations by reverting to known good versions. The complete workflow provides audit trails, reduces manual deployment effort, and improves deployment reliability.

### Verification Questions

Test your understanding by answering these questions:

1. **How does** GitOps improve deployment reliability compared to manual kubectl deployment approaches?

2. **What role** do SLO metrics play in automated deployment validation and rollback decisions?

3. **Why is** Git-based audit trail important for compliance and incident investigation?

4. **How would** you modify the rollback automation to be more or less sensitive to service degradation?

5. **What are** the key differences between imperative and declarative deployment management?

---

## Troubleshooting

### Common Issues

**ArgoCD not syncing changes from Git**: Check repository access with `argocd app get sre-demo-gitops` and verify that ArgoCD can reach your GitHub repository. Ensure the repository path and branch are correctly configured in the application definition.

**Deployment validation failing**: Verify SLO queries work in Prometheus with `curl "http://$PROMETHEUS_IP:9090/api/v1/query?query=<your_slo_query>"` and check that your application generates metrics correctly. Review validation thresholds in the deployment health check script.

**Rollback automation not activating**: Check Prometheus alert rules with `kubectl logs -l app=prometheus | grep "rule evaluation"` and verify that alert conditions match actual deployment failure scenarios.

**ArgoCD application stuck in OutOfSync**: Check for resource conflicts with `argocd app get sre-demo-gitops -o yaml` and verify that ArgoCD has necessary RBAC permissions for the target namespace.

**Manual sync required repeatedly**: This is common in development environments like Codespaces due to network latency. Use `argocd app sync sre-demo-gitops` when needed.

### Advanced Troubleshooting

**Debugging GitOps sync failures**: Check ArgoCD server logs with `kubectl logs -n argocd deployment/argocd-server` and review application events with `argocd app get sre-demo-gitops --show-events`.

**Investigating deployment validation issues**: Review validation script logs and test individual SLO queries manually in Prometheus to identify which metrics are causing validation failures.

**Analyzing rollback behavior**: Monitor rollback automation logs during controlled failures and verify that rollback conditions align with actual service degradation patterns.

---

## Next Steps

You have successfully implemented GitOps principles using ArgoCD for automated deployment management with integrated monitoring and rollback capabilities. You've established declarative deployment workflows, created safety gates using SLO metrics, implemented automated rollback systems based on monitoring data, and built comprehensive audit trails for deployment operations.

**Proceed to [Exercise 7](../exercise7/)** where you will implement comprehensive production readiness including security hardening, cost optimization strategies, disaster recovery procedures, and compliance frameworks that build upon your reliable deployment infrastructure.

**Key Concepts to Remember**: GitOps provides declarative, auditable deployment management that reduces human error and improves reliability. SLO-based deployment validation ensures deployments don't degrade user experience. Automated rollback systems minimize MTTR when issues occur. Git-based audit trails support compliance and incident investigation requirements.

**Before Moving On**: Ensure you can explain how GitOps improves deployment reliability compared to manual processes, why SLO validation is critical for deployment safety, and how automated rollback reduces the impact of problematic deployments. In the next exercise, you'll add production readiness capabilities including security, disaster recovery, and compliance features.