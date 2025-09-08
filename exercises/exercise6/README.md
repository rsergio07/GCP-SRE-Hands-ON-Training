# Exercise 6: ArgoCD GitOps Deployment Management

## Table of Contents

* [Introduction](#introduction)
* [Learning Objectives](#learning-objectives)
* [Prerequisites](#prerequisites)
* [Theory Foundation](#theory-foundation)
* [Understanding GitOps for Deployment Management](#understanding-gitops-for-deployment-management)
* [Setting Up ArgoCD for Automated Deployments](#setting-up-argocd-for-automated-deployments)
* [Implementing GitOps Deployment Pipelines](#implementing-gitops-deployment-pipelines)
* [Exploring ArgoCD Operations](#exploring-argocd-operations)
* [Testing GitOps Configuration Management](#testing-gitops-configuration-management)
* [Advanced ArgoCD Features](#advanced-argocd-features)
* [Final Objective](#final-objective)
* [Troubleshooting](#troubleshooting)
* [Next Steps](#next-steps)

---

## Introduction

In this exercise, you will implement GitOps deployment management using ArgoCD to automate Kubernetes deployments through declarative configuration. You'll learn how to use Git repositories as the single source of truth for application deployment state, configure ArgoCD to continuously synchronize cluster state with Git, and manage application lifecycles through GitOps workflows.

This exercise demonstrates how modern DevOps teams manage deployments with reliability, traceability, and automation while maintaining complete visibility into application state and deployment history.

---

## Learning Objectives

By completing this exercise, you will understand:

- **GitOps Fundamentals**: How to implement declarative, Git-based deployment workflows
- **ArgoCD Installation**: How to deploy and configure ArgoCD in Kubernetes clusters
- **Application Management**: How to create and manage ArgoCD applications for continuous deployment
- **GitOps Workflows**: How to make configuration changes through Git that automatically deploy to clusters
- **Deployment Visibility**: How to use ArgoCD's interface to monitor deployment status and health
- **Rollback Operations**: How to revert deployments using ArgoCD's rollback capabilities
- **Configuration Drift**: How GitOps prevents and corrects configuration drift in production systems

---

## Prerequisites

Before starting this exercise, ensure you have completed:

- Exercise 1: Cloud Development Environment & SRE Application
- Exercise 2: Container Builds & GitHub Actions  
- Exercise 3: Kubernetes Deployment

**Verify your Kubernetes environment is operational:**

```bash
# Check that your Kubernetes cluster is accessible
kubectl cluster-info
```

**Expected output:**

```
Kubernetes control plane is running at https://34.42.233.203
GLBCDefaultBackend is running at https://34.42.233.203/api/v1/namespaces/kube-system/services/default-http-backend:http/proxy
KubeDNS is running at https://34.42.233.203/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://34.42.233.203/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

```bash
# Verify your application deployment from previous exercises
kubectl get pods -l app=sre-demo-app
```

**Expected output:**

```
NAME                            READY   STATUS    RESTARTS   AGE
sre-demo-app-7458c58c57-abc34   1/1     Running   0          4h
sre-demo-app-7458c58c57-def56   1/1     Running   0          4h
```

```bash
kubectl get deployment sre-demo-app
```

**Expected output:**

```
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
sre-demo-app   2/2     2            2           4h
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

### ArgoCD Architecture

- [ArgoCD Architecture](https://argo-cd.readthedocs.io/en/stable/operator-manual/architecture/) - Official architecture documentation

### Key Concepts You'll Learn

**GitOps Benefits** include declarative infrastructure that prevents configuration drift, Git-based audit trails for all deployment changes, automated synchronization between Git state and cluster state, and clear separation between application development and deployment operations.

**ArgoCD Components** consist of the API Server that provides the web UI and gRPC API, the Repository Server that maintains cached copies of Git repositories, the Application Controller that monitors applications and synchronizes cluster state, and the Dex component that provides authentication integration.

**Deployment Automation** through ArgoCD continuously monitors Git repositories for changes, compares desired state with actual cluster state, automatically applies configuration changes, and provides real-time visibility into deployment status and application health.

---

## Understanding GitOps for Deployment Management

Your current deployment approach from previous exercises relies on manual kubectl commands for deployment management. This creates operational challenges including potential configuration drift, manual change tracking, limited deployment history, and imperative deployment processes that can create inconsistent state.

### Current State vs GitOps Target

**Current Manual Process** requires direct cluster access for deployments, uses imperative commands that modify cluster state directly, provides limited deployment history and audit trails, and relies on human intervention for deployment coordination and rollback procedures.

**GitOps Target State** uses Git repositories as the single source of truth for deployment configuration. ArgoCD continuously monitors Git for changes and automatically applies updates, maintains complete deployment history through Git commits, and provides automated synchronization with clear visibility into deployment status.

### Why GitOps Matters for Operations

**Improved Deployment Reliability** through declarative configuration that ensures consistent deployment state across environments. **Enhanced Change Management** through Git-based approval workflows, complete audit trails, and rollback capabilities. **Reduced Operational Overhead** through automation of manual deployment processes and elimination of configuration drift.

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

ArgoCD deployment takes 3-5 minutes. Wait until all pods show `Running` status before proceeding.

```bash
# Monitor ArgoCD deployment
kubectl get pods -n argocd
```

**Expected output:**

```
NAME                                               READY   STATUS    RESTARTS   AGE
argocd-application-controller-0                    1/1     Running   0          79s
argocd-applicationset-controller-5b75d899b-lb7n8   1/1     Running   0          64s
argocd-dex-server-59746c9588-cwkcg                 1/1     Running   0          63s
argocd-notifications-controller-5f96c56f77-s9ms7   1/1     Running   0          20m
argocd-redis-56f98f7cd8-xv7gw                      1/1     Running   0          20m
argocd-repo-server-546fb64cd4-zd4rc                1/1     Running   0          20m
argocd-server-79b5565d68-fqljf                     1/1     Running   0          20m
```

**Access the ArgoCD web interface** using the URL from your output (accept the self-signed certificate). The interface provides visual representation of applications, deployment status, and synchronization history.

**Test web interface access:**
- Navigate to the ARGOCD_IP URL from your terminal output
- Accept the self-signed certificate when prompted by your browser
- Login with username `admin` and the password from your terminal output
- Verify you can see the ArgoCD dashboard (should be empty initially)

### Step 2: Install and Configure ArgoCD CLI

Set up command-line access for ArgoCD management:

```bash
# Install ArgoCD CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

```bash
# Login to ArgoCD
argocd login $ARGOCD_IP --username admin --password $ARGOCD_PASSWORD --insecure
```

**Expected output:**
```
'admin:login' logged in successfully
Context '$ARGOCD_IP' updated
```

**Note**: If you get ArgoCD CLI help text instead of a successful login, the environment variables may have been cleared. Re-export them:

```bash
# Re-export ArgoCD credentials if needed
export ARGOCD_IP=$(kubectl get service argocd-server-lb -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
```

```bash
# Then retry the login
argocd login $ARGOCD_IP --username admin --password $ARGOCD_PASSWORD --insecure
```

## Implementing GitOps Deployment Pipelines

### Connecting Git State to Cluster Deployments

This section establishes the GitOps deployment pipeline that connects your application configuration in Git to automated cluster deployments through ArgoCD.

### Step 3: Configure GitOps Repository Structure

Examine and understand the GitOps deployment configuration:

```bash
# Examine the ArgoCD deployment
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

### Step 4: Create ArgoCD Application

Configure ArgoCD to manage your demo application:

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

Apply the ArgoCD application configuration:

```bash
kubectl apply -f k8s/argocd/application.yaml
```

**Expected output:**
```
application.argoproj.io/sre-demo-gitops created
```

Verify application creation:

```bash
argocd app get sre-demo-gitops
```

**Expected output:**
```
Name:               argocd/sre-demo-gitops
Project:            default
Server:             https://kubernetes.default.svc
Namespace:          default
URL:                https://34.63.232.153/applications/sre-demo-gitops
Repo:               https://github.com/rsergio07/kubernetes-sre-cloud-native
Target:             main
Path:               exercises/exercise6/k8s/gitops
SyncWindow:         Sync Allowed
Sync Policy:        Automated (Prune)
Sync Status:        Synced to main (f0fe984)
Health Status:      Healthy

GROUP  KIND        NAMESPACE  NAME               STATUS  HEALTH   HOOK  MESSAGE
       Service     default    sre-demo-service   Synced  Healthy        service/sre-demo-service unchanged
       Service     default    sre-demo-headless  Synced  Healthy        service/sre-demo-headless unchanged
apps   Deployment  default    sre-demo-app       Synced  Healthy        deployment.apps/sre-demo-app configured          
```

**Access the ArgoCD application view:** Navigate to the URL shown in the `argocd app get` output (e.g., `https://ARGOCD_IP/applications/sre-demo-gitops`).

---

## Exploring ArgoCD Operations

### Understanding GitOps Through ArgoCD Interface

This section focuses on understanding GitOps operations through direct interaction with ArgoCD, demonstrating how declarative configuration management works in practice.

### Step 5: Explore ArgoCD Interface and Concepts

**Navigate to your ArgoCD application** and explore the interface:

**Application Overview**: View sync status, health indicators, and resource hierarchy to understand how ArgoCD visualizes your application state.

**Resource Tree**: Examine how ArgoCD displays the relationships between Kubernetes resources (Deployment → ReplicaSet → Pods → Services).

**Sync Controls**: Understand the difference between manual and automatic synchronization options available in the interface.

**History Tab**: Review deployment history and previous configurations to see how GitOps maintains change tracking.

Practice ArgoCD operations using CLI:

```bash
# View current application status
argocd app get sre-demo-gitops
```

```bash
# Trigger manual sync to ensure latest state
argocd app sync sre-demo-gitops
```

```bash
# Check sync history
argocd app history sre-demo-gitops
```

```bash
# View application details in YAML format
argocd app get sre-demo-gitops -o yaml
```

**Understanding ArgoCD Application Status:**

The ArgoCD interface shows your GitOps deployment in action. Key status indicators you'll observe:

**Sync Status Progression:**
- **OutOfSync**: ArgoCD detects differences between Git and cluster state
- **Sync OK**: Git state matches cluster state successfully
- **Progressing**: Kubernetes resources are being created/updated
- **Healthy**: All resources are running and ready

**Resource Tree View** displays your application components:
- **Deployment**: Your application pods with replica management
- **Services**: Network access and service discovery
- **Individual Pods**: Each pod instance with age and status indicators

---

## Testing GitOps Configuration Management

### Experimenting with Declarative Configuration Changes

This section demonstrates the core GitOps workflow by making controlled configuration changes and observing how ArgoCD automatically applies them to your cluster.

### Step 6: Test GitOps Workflow with Configuration Changes

#### 1. Check Current Application State

Before making configuration changes, examine the current state of your application to understand the baseline:

```bash
# Check current deployment configuration
kubectl get deployment sre-demo-app -o yaml | grep -A 5 "replicas\|image:"
````

**Expected output:**

```
replicas: 2
...
image: us-central1-docker.pkg.dev/gcp-sre-lab/sre-demo-app/sre-demo-app:latest
```

```bash
# View current pod count and status
kubectl get pods -l app=sre-demo-app
```

**Expected output:**

```
NAME                            READY   STATUS    RESTARTS   AGE
sre-demo-app-84b5769f44-pqmh8   1/1     Running   0         9m
sre-demo-app-84b5769f44-vvs9z   1/1     Running   7         52m
```

```bash
# Check ArgoCD application current state
argocd app get sre-demo-gitops | grep -A 10 "GROUP.*KIND"
```

**Expected output:**

```
apps   Deployment  default    sre-demo-app   Synced  Healthy
```

---

#### 2. Make a Configuration Change

Scale the application to test GitOps synchronization:

```bash
sed -i 's/replicas: 2/replicas: 3/g' k8s/gitops/deployment.yaml
grep "replicas:" k8s/gitops/deployment.yaml
```

**Expected output:**

```
replicas: 3
```

---

#### 3. Commit and Push

```bash
git add k8s/gitops/deployment.yaml
git commit -m "gitops: Scale application to 3 replicas for testing"
git push origin main
```

---

#### 4. Refresh ArgoCD

ArgoCD may take time to detect the new commit. Force a refresh:

**From the CLI:**

```bash
argocd app get sre-demo-gitops --refresh
```

**From the ArgoCD UI:**

1. Open your application.
2. Click **REFRESH** (top right).
3. The app should now show **OutOfSync** (Git: 3 replicas, Cluster: 2).
4. Click **SYNC** to apply the change.

---

#### 5. Verify Scaling

```bash
kubectl get pods -l app=sre-demo-app
```

**Expected output:**

```
NAME                            READY   STATUS    RESTARTS   AGE
sre-demo-app-xyz123             1/1     Running   0         2m
sre-demo-app-xyz456             1/1     Running   0         2m
sre-demo-app-xyz789             1/1     Running   0         1m
```

```bash
kubectl get deployment sre-demo-app
```

**Expected output:**

```
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
sre-demo-app   3/3     3            3           2d20h
```

---

### Key Learning

* **Git as Source of Truth**: Even if you scale manually, ArgoCD reconciles back to the Git-defined state.
* **Forcing Refresh**: Use `--refresh` or the UI **REFRESH** button to ensure ArgoCD picks up new commits immediately.
* **Configuration Drift Prevention**: GitOps ensures consistency by detecting and correcting drift automatically.

### Step 7: Test Configuration Rollback Capabilities

Demonstrate ArgoCD's rollback functionality:

```bash
# View deployment history to see available revisions
argocd app history sre-demo-gitops
```

Replace `<previous-revision-id>` with actual ID from history:

```bash
# Rollback to previous revision (before scaling)
argocd app rollback sre-demo-gitops <previous-revision-id>
```

```bash
# Watch the rollback process
kubectl get pods -l app=sre-demo-app
```

Test additional configuration changes:

```bash
# Add a label to test ArgoCD change detection
sed -i '/labels:/a\    environment: testing' k8s/gitops/deployment.yaml
```

```bash
git add k8s/gitops/deployment.yaml
git commit -m "gitops: Add environment label for testing"
git push origin gitops-config-test
```

```bash
# Sync and verify the label addition
argocd app sync sre-demo-gitops
```

```bash
kubectl get deployment sre-demo-app -o yaml | grep -A 5 labels:
```

Clean up the feature branch:

```bash
# Switch back to main branch
git checkout main

# Reset any configuration changes
git reset --hard HEAD

# Delete the feature branch locally and remotely
git branch -D gitops-config-test
git push origin --delete gitops-config-test

# Sync ArgoCD to main branch state
argocd app sync sre-demo-gitops
```

---

## Advanced ArgoCD Features

### Exploring ArgoCD Management Capabilities

This section covers advanced ArgoCD features for production deployment management including application sets, resource hooks, and sync policies.

### Step 8: Explore ArgoCD Application Management

Examine application configuration options:

```bash
# View detailed application configuration
argocd app get sre-demo-gitops -o yaml
```

Test different sync policies:

```bash
# Check current sync policy
argocd app get sre-demo-gitops | grep -A 5 "Sync Policy"
```

```bash
# Manually control sync behavior
argocd app set sre-demo-gitops --sync-policy manual
```

Make a change to test manual sync:

```bash
git checkout -b test-manual-sync
echo "# Manual sync test - $(date)" >> k8s/gitops/deployment.yaml
git add k8s/gitops/deployment.yaml
git commit -m "test: Manual sync configuration"
git push origin test-manual-sync
```

Observe that ArgoCD detects but doesn't auto-sync:

```bash
# ArgoCD detects but doesn't auto-sync
argocd app get sre-demo-gitops
```

```bash
# Manually trigger sync
argocd app sync sre-demo-gitops
```

### Step 9: Validate GitOps Operational Benefits

Examine the audit trail provided by GitOps:

```bash
# Review Git commit history showing deployment changes
git log --oneline -10
```

**Expected output showing clear audit trail:**
```
abc123ef test: Manual sync configuration
def456gh gitops: Add environment label for testing
ghi789jk gitops: Scale application to 3 replicas for testing
```

Check ArgoCD deployment history:

```bash
# View ArgoCD deployment history
argocd app history sre-demo-gitops
```

**Expected output:**
```
ID  DATE                           REVISION
5   2025-09-06 15:42:33 +0000 UTC  abc123ef (test: Manual sync configuration)
4   2025-09-06 15:38:21 +0000 UTC  def456gh (gitops: Add environment label)
3   2025-09-06 15:35:18 +0000 UTC  ghi789jk (gitops: Scale application to 3 replicas)
```

Demonstrate deployment state management:

```bash
# Show current deployment state
kubectl get deployment sre-demo-app -o yaml | grep -A 10 metadata:
```

```bash
# Compare with GitOps desired state
cat k8s/gitops/deployment.yaml | grep -A 10 metadata:
```

Clean up test configuration:

```bash
# Return to main branch and clean up
git checkout main
git branch -D test-manual-sync
git push origin --delete test-manual-sync
```

```bash
# Reset sync policy to automatic
argocd app set sre-demo-gitops --sync-policy automated
```

```bash
# Final sync to ensure clean state
argocd app sync sre-demo-gitops
```

---

## Final Objective

By completing this exercise, you should be able to demonstrate:

Your application deploys using GitOps principles with ArgoCD managing automated synchronization from Git repositories. You understand how to make declarative configuration changes that ArgoCD automatically detects and applies to your cluster. You can use ArgoCD's interface to monitor deployment status, review deployment history, and perform rollback operations. The complete workflow provides audit trails through Git commits and reduces manual deployment effort through automated synchronization.

### Verification Questions

Test your understanding by answering these questions:

1. **How does** ArgoCD detect when configuration changes are made in Git repositories?

2. **What is** the difference between imperative and declarative deployment management?

3. **Why is** Git-based audit trail valuable for deployment operations and compliance?

4. **How would** you troubleshoot an ArgoCD application that shows "OutOfSync" status?

5. **What are** the benefits of using GitOps compared to direct kubectl deployment commands?

---

## Troubleshooting

### Common Issues

**ArgoCD not syncing changes from Git**: Check repository access with `argocd app get sre-demo-gitops` and verify that ArgoCD can reach your GitHub repository. Ensure the repository path and branch are correctly configured in the application definition.

**ArgoCD application stuck in OutOfSync**: Check for resource conflicts with `argocd app get sre-demo-gitops -o yaml` and verify that ArgoCD has necessary RBAC permissions for the target namespace. Try manual sync with `argocd app sync sre-demo-gitops`.

**Manual sync required repeatedly**: This is common in development environments like Codespaces due to network latency. Use `argocd app sync sre-demo-gitops` when needed, or switch to manual sync policy for testing.

**Web interface not accessible**: Verify LoadBalancer IP assignment with `kubectl get service argocd-server-lb -n argocd` and ensure firewall rules allow access to the ArgoCD port.

**CLI login issues**: Confirm ArgoCD server is accessible and use the `--insecure` flag for development environments with self-signed certificates.

### Advanced Troubleshooting

**Debugging GitOps sync failures**: Check ArgoCD server logs with `kubectl logs -n argocd deployment/argocd-server` and review application events with `argocd app get sre-demo-gitops --show-events`.

**Repository access issues**: Verify repository URL in application definition and check ArgoCD repository server logs with `kubectl logs -n argocd deployment/argocd-repo-server`.

**Resource sync conflicts**: Use `kubectl get events` to identify resource-level issues and compare desired state in Git with actual cluster state using `kubectl diff`.

---

## Next Steps

You have successfully implemented GitOps deployment management using ArgoCD for automated Kubernetes deployments. You've established declarative deployment workflows, learned to use ArgoCD's interface for deployment management, tested configuration changes through Git workflows, and experienced the operational benefits of GitOps including audit trails and rollback capabilities.

**Proceed to [Exercise 7](../exercise7/)** where you will implement comprehensive production readiness including security hardening, cost optimization strategies, disaster recovery procedures, and compliance frameworks that build upon your reliable deployment infrastructure.

**Key Concepts to Remember**: GitOps provides declarative, auditable deployment management that reduces human error and improves reliability. ArgoCD serves as the automation engine that continuously synchronizes Git state with cluster state. Git-based workflows provide complete audit trails and enable easy rollback to previous configurations. Automated synchronization eliminates configuration drift and reduces manual deployment effort.

**Before Moving On**: Ensure you can explain how GitOps improves deployment reliability compared to manual processes, how ArgoCD detects and applies configuration changes, and how Git-based workflows provide better audit trails and rollback capabilities than imperative deployment approaches.