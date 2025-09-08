# Exercise 6: Production CI/CD with GitOps

## Table of Contents

* [Introduction](#introduction)
* [Learning Objectives](#learning-objectives)
* [Prerequisites](#prerequisites)
* [Theory Foundation](#theory-foundation)
* [Understanding GitOps for SRE](#understanding-gitops-for-sre)
* [Setting Up ArgoCD for Automated Deployments](#setting-up-argocd-for-automated-deployments)
* [Implementing GitOps Deployment Pipelines](#implementing-gitops-deployment-pipelines)
* [Deployment Safety Gates and SLO Validation](#deployment-safety-gates-and-slo-validation)
* [Automated Rollback and Recovery](#automated-rollback-and-recovery)
* [Testing End-to-End Pipeline Reliability](#testing-end-to-end-pipeline-reliability)
* [Final Objective](#final-objective)
* [Troubleshooting](#troubleshooting)
* [Next Steps](#next-steps)

---

## Introduction

In this exercise, you will implement production-ready CI/CD pipelines using GitOps principles with ArgoCD. You'll create automated deployment workflows that integrate with your monitoring infrastructure from Exercises 4-5, implement deployment safety gates based on SLO compliance, and establish automated rollback capabilities that minimize Mean Time to Resolution (MTTR).

This exercise demonstrates how modern SRE teams manage deployments with reliability, traceability, and minimal human intervention while maintaining service availability through automated validation and recovery procedures.

---

## Learning Objectives

By completing this exercise, you will understand:

- **GitOps Implementation**: How to implement declarative, Git-based deployment workflows that eliminate configuration drift
- **ArgoCD Configuration**: How to deploy and configure ArgoCD for continuous deployment with proper security
- **Deployment Safety Gates**: How to use SLO metrics to validate deployment success automatically
- **Automated Rollback**: How to implement SLO-based rollback automation that responds to service degradation
- **Pipeline Integration**: How to connect CI/CD pipelines with monitoring infrastructure for intelligent deployments
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

This section establishes the automated pipeline that connects your application code changes to deployment updates through GitOps principles, integrating with your existing GitHub Actions workflow.

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

# SHOULD BE (replace with your actual Google Cloud Platform project ID):
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
- Repo:             https://github.com/rsergio07/kubernetes-sre-cloud-native
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

Navigate to the URL shown in the `argocd app get` output (e.g., `https://ARGOCD_IP URL/applications/sre-demo-gitops`).

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

**Note for students**: In production environments, automated sync typically occurs within 30-60 seconds. Development environments like Codespaces may require manual sync due to network latency and resource constraints.

**Step 4: Test GitOps Workflow with Safe Application Change**

This step demonstrates the complete GitOps pipeline by making a minimal, safe change to your application code and observing how it flows through the entire CI/CD system.

### Understanding the GitOps Testing Strategy

**Why we're testing with a small change:** GitOps workflows connect multiple systems (Git → GitHub Actions → Container Registry → ArgoCD → Kubernetes). Testing with a harmless modification validates that all components communicate correctly without risking application stability.

**The test change we'll make:** Adding a timestamped comment to your application configuration file. This triggers the build pipeline without affecting application behavior.

### Step 4A: Create Safe Test Change

**Create a feature branch for testing:**

```bash
# Create a feature branch for testing
git checkout -b exercise6-gitops-test

# Make a small change to test the pipeline
echo "# GitOps deployment test - $(date)" >> app/config.py
```

**What this command does:**
- **Appends a Python comment** to `app/config.py` with current timestamp
- **Creates a code change** that GitHub Actions will detect
- **Doesn't modify application behavior** since it's just a comment
- **Provides clear traceability** with the timestamp for tracking

**Commit and push to trigger the test phase:**

```bash
git add app/config.py
git commit -m "test: GitOps pipeline validation"
git push origin exercise6-gitops-test
```

### Step 4B: Monitor GitHub Actions Execution

**Navigate to your GitHub repository's Actions tab:**
1. **Open your repository** in GitHub (`https://github.com/your-username/kubernetes-sre-cloud-native`)
2. **Click the "Actions" tab** in the repository navigation
3. **Look for the new workflow run** triggered by your push

**What you should observe in the Actions interface:**

**Workflow Trigger Details:**
- **Run name:** Shows your commit message "test: GitOps pipeline validation"
- **Branch:** `exercise6-gitops-test` 
- **Trigger event:** `push` (from your git push command)
- **Workflow file:** `.github/workflows/gitops-deploy.yml`

**Job Execution for Feature Branch:**
- **test-application job:** Runs code quality checks, unit tests, and build validation
- **deploy-production job:** Skipped (only runs on main branch)
- **Status indicators:** Green checkmarks for successful steps, red X for failures

**Why this workflow behavior matters:**
- **Feature branch protection:** Prevents accidental deployments to production
- **Code validation:** Ensures changes don't break the application before merging
- **Development safety:** Allows testing pipeline components without affecting live systems

### Step 4C: Understanding the GitOps Safety Model

**Branch-based deployment strategy:**
- **Feature branches:** Run tests only, no deployment to production
- **Main branch:** Triggers full deployment pipeline to production
- **Pull request workflow:** Code review before production deployment

**This demonstrates GitOps best practices:**
- **Separation of concerns:** Testing separated from deployment
- **Review gates:** Human approval before production changes
- **Audit trails:** Complete history of what changed and when

**Clean up the test branch:**

```bash
# Switch back to main and clean up
git checkout main
git branch -D exercise6-gitops-test
git push origin --delete exercise6-gitops-test
```

**Key learning outcomes:** You've validated that your GitOps pipeline can detect code changes, execute appropriate workflow steps based on branch policies, and maintain separation between testing and production deployment processes. This foundation ensures that when you make real application changes on the main branch, the complete deployment automation will function correctly.

---

## Deployment Safety Gates and SLO Validation

### Using Monitoring Data to Validate Deployments

This section implements safety mechanisms that prevent problematic deployments from degrading user experience by using your existing monitoring infrastructure to validate SLO compliance.

### Step 5: Implement SLO-Based Deployment Validation

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

### Step 6: Configure Automated Deployment Health Checks

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

### Step 7: Implement SLO-Based Rollback Automation

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

### Step 8: Test Rollback with Controlled Deployment Failure

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

This section tests the complete GitOps pipeline from code change through deployment validation to ensure all components work together reliably.

### Step 9: Execute Full GitOps Deployment Test

Test the complete workflow with a real application change:

```bash
# Make a meaningful change to demonstrate end-to-end workflow
echo "GitOps_enabled = True  # Added $(date)" >> app/config.py
```

```bash
# Commit to main branch to trigger full pipeline
git add app/config.py
git commit -m "feat: Enable GitOps deployment workflow"
git push origin main
```

**Monitor the complete pipeline execution:**

```bash
# Check GitHub Actions progress
echo "Monitor GitHub Actions: https://github.com/$(git config --get remote.origin.url | cut -d: -f2 | cut -d. -f1)/actions"

# Watch ArgoCD synchronization
argocd app sync sre-demo-gitops --watch
```

**Expected pipeline flow:**
1. **GitHub Actions** builds new container image with updated code
2. **Manifest update** automatically updates deployment.yaml with new image tag
3. **ArgoCD detects** Git changes and syncs new configuration
4. **Deployment validation** confirms SLO compliance
5. **Application update** completes successfully

### Step 10: Verify Deployment Success and Monitoring Integration

Confirm that the deployment completed successfully and monitoring continues to function:

```bash
# Verify new deployment is running
kubectl get pods -l app=sre-demo-app
kubectl describe deployment sre-demo-app | grep Image:
```

**Expected output showing new image:**
```
NAME                            READY   STATUS    RESTARTS   AGE
sre-demo-app-7b8c9d3f5g-abc12   1/1     Running   0          3m
sre-demo-app-7b8c9d3f5g-def34   1/1     Running   0          3m

    Image:      us-central1-docker.pkg.dev/your-project/sre-demo-app/sre-demo-app:latest-abc123ef
```

**Test application functionality with new deployment:**

```bash
# Verify application endpoints work correctly
export EXTERNAL_IP=$(kubectl get service sre-demo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

curl http://$EXTERNAL_IP/health
curl http://$EXTERNAL_IP/metrics | grep http_requests_total | head -5
```

**Expected output:**
```
{"status":"ready","timestamp":1756767389.123456}

http_requests_total{endpoint="health_check",method="GET",status="200"} 1234.0
http_requests_total{endpoint="index",method="GET",status="200"} 567.0
```

**Verify monitoring continues to collect metrics from new deployment:**

```bash
# Check that Prometheus is scraping new pods
curl -s "http://$PROMETHEUS_IP:9090/api/v1/query?query=up{job=\"sre-demo-app\"}" | jq '.data.result'
```

**Expected output showing healthy targets:**
```
[
  {
    "metric": {
      "__name__": "up",
      "instance": "10.116.0.123:8080",
      "job": "sre-demo-app"
    },
    "value": [1756767389, "1"]
  }
]
```

### Step 11: Validate GitOps Audit Trail and Operational Benefits

Examine the audit trail and operational improvements provided by GitOps:

```bash
# Review Git commit history showing deployment changes
git log --oneline -10
```

**Expected output showing clear audit trail:**
```
abc123ef feat: Enable GitOps deployment workflow
def456gh restore: Fix deployment after rollback test
ghi789jk test: Simulate deployment failure for rollback validation
jkl012mn Initial GitOps configuration
```

**Check ArgoCD application history:**

```bash
# View ArgoCD deployment history
argocd app history sre-demo-gitops
```

**Expected output:**
```
ID  DATE                           REVISION
10  2025-09-06 15:42:33 +0000 UTC  abc123ef (feat: Enable GitOps deployment workflow)
9   2025-09-06 15:38:21 +0000 UTC  def456gh (restore: Fix deployment after rollback test)
8   2025-09-06 15:35:18 +0000 UTC  ghi789jk (test: Simulate deployment failure)
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
- **Reduced Manual Effort**: Deployments happen without human intervention

---

## Final Objective

By completing this exercise, you should be able to demonstrate:

Your application deploys using GitOps principles with ArgoCD managing automated synchronization from Git. The deployment pipeline integrates with your monitoring infrastructure to validate SLO compliance before marking deployments successful. Automated rollback systems respond to deployment-related SLO violations by reverting to known good versions. The complete workflow provides audit trails, reduces manual deployment effort, and improves deployment reliability through automated validation and recovery.

### Verification Questions

Test your understanding by answering these questions:

1. **How does** GitOps improve deployment reliability compared to manual kubectl deployment approaches?

2. **What role** do SLO metrics play in automated deployment validation and rollback decisions?

3. **Why is** Git-based audit trail important for compliance and incident investigation?

4. **How would** you modify the rollback automation to be more or less sensitive to service degradation?

---

## Troubleshooting

### Common Issues

**ArgoCD not syncing changes from Git**: Check repository access with `argocd app get sre-demo-gitops` and verify that ArgoCD can reach your GitHub repository. Ensure the repository path and branch are correctly configured in the application definition.

**Deployment validation failing**: Verify SLO queries work in Prometheus with `curl "http://$PROMETHEUS_IP:9090/api/v1/query?query=<your_slo_query>"` and check that your application generates metrics correctly. Review validation thresholds in the deployment health check script.

**GitHub Actions workflow not triggering**: Confirm that the enhanced workflow file is in the correct `.github/workflows/` directory and that webhook delivery is working from GitHub to trigger builds on push events.

**Rollback automation not activating**: Check Prometheus alert rules with `kubectl logs -l app=prometheus | grep "rule evaluation"` and verify that alert conditions match actual deployment failure scenarios.

**ArgoCD application stuck in OutOfSync**: Check for resource conflicts with `argocd app get sre-demo-gitops -o yaml` and verify that ArgoCD has necessary RBAC permissions for the target namespace.

### Advanced Troubleshooting

**Debugging GitOps sync failures**: Check ArgoCD server logs with `kubectl logs -n argocd deployment/argocd-server` and review application events with `argocd app get sre-demo-gitops --show-events`.

**Investigating deployment validation issues**: Review validation script logs and test individual SLO queries manually in Prometheus to identify which metrics are causing validation failures.

**Analyzing rollback behavior**: Monitor rollback automation logs during controlled failures and verify that rollback conditions align with actual service degradation patterns.

---

## Next Steps

You have successfully implemented production-ready CI/CD pipelines using GitOps principles with automated deployment validation and rollback capabilities. You've established ArgoCD for declarative deployment management, created safety gates using SLO metrics, implemented automated rollback systems based on monitoring data, and built comprehensive audit trails for deployment operations.

**Proceed to [Exercise 7](../exercise7/)** where you will implement comprehensive production readiness including security hardening, cost optimization strategies, disaster recovery procedures, and compliance frameworks that build upon your reliable deployment infrastructure.

**Key Concepts to Remember**: GitOps provides declarative, auditable deployment management that reduces human error and improves reliability. SLO-based deployment validation ensures deployments don't degrade user experience. Automated rollback systems minimize MTTR when issues occur. Git-based audit trails support compliance and incident investigation requirements.

**Before Moving On**: Ensure you can explain how GitOps improves deployment reliability compared to manual processes, why SLO validation is critical for deployment safety, and how automated rollback reduces the impact of problematic deployments. In the next exercise, you'll add production readiness capabilities including security, disaster recovery, and compliance features.