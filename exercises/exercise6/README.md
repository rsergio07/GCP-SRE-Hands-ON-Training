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
* [Rollback in the ArgoCD UI](#step-7-test-rollback-using-the-argocd-ui)
* [Sync Policies in the ArgoCD UI](#step-8-explore-sync-policies-and-manual-control)
* [Final Objective](#final-objective)
* [Troubleshooting](#troubleshooting)
* [Next Steps](#next-steps)

---

## Introduction

In this exercise, you will implement GitOps deployment management using ArgoCD to automate Kubernetes deployments through declarative configuration. You'll learn how to use Git repositories as the single source of truth for application deployment state, configure ArgoCD to continuously synchronize cluster state with Git, and manage application lifecycles through GitOps workflows.

This exercise demonstrates how modern SRE teams manage deployments with reliability, traceability, and automation while maintaining complete visibility into application state and deployment history. GitOps represents a fundamental shift from imperative deployment commands to declarative infrastructure management that reduces human error, improves audit trails, and enables automated rollback capabilities essential for production reliability.

---

## Learning Objectives

By completing this exercise, you will understand:

* **GitOps Fundamentals**: How to implement declarative, Git-based deployment workflows that eliminate configuration drift
* **ArgoCD Architecture**: How to deploy and configure ArgoCD in Kubernetes clusters for continuous deployment automation
* **Application Lifecycle Management**: How to create and manage ArgoCD applications with automated synchronization and health monitoring
* **Declarative Workflow Implementation**: How to make configuration changes through Git that automatically deploy to clusters with full audit trails
* **Operational Visibility**: How to use ArgoCD's interface to monitor deployment status, track changes, and maintain system health
* **Production Rollback Operations**: How to revert deployments using the ArgoCD web interface with minimal downtime impact
* **Synchronization Policy Control**: How to toggle between manual and automated synchronization strategies based on operational requirements
* **Configuration Drift Prevention**: How GitOps prevents and corrects configuration drift in production systems through continuous reconciliation

---

## Prerequisites

Before starting this exercise, ensure you have completed:

- Exercise 1: Cloud Development Environment & SRE Application
- Exercise 2: Container Builds & GitHub Actions  
- Exercise 3: Kubernetes Deployment
- Exercise 4: Cloud Monitoring Stack
- Exercise 5: Alerting and Response

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

**Verify your application deployment foundation from previous exercises:**

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

**Understanding the foundation you've built:** Your existing deployment from Exercise 3 provides the application foundation that you'll now manage through GitOps workflows. This transition from imperative deployment management to declarative GitOps practices represents a critical evolution in production deployment strategies.

---

## Theory Foundation

### GitOps and Continuous Deployment

**Essential Watching** (15 minutes):
- [What is GitOps, How GitOps works and Why it's so useful](https://www.youtube.com/watch?v=f5EpcWp0THw) by TechWorld with Nana - Comprehensive GitOps overview
- [ArgoCD Tutorial for Beginners](https://www.youtube.com/watch?v=MeU5_k9ssrs) by TechWorld with Nana - Practical ArgoCD implementation

**Reference Documentation**:
- [GitOps Principles](https://opengitops.dev/) - Official GitOps working group principles and best practices
- [ArgoCD Getting Started](https://argo-cd.readthedocs.io/en/stable/getting_started/) - Official quick start guide

### ArgoCD Architecture and Components

**Reference Documentation**:
- [ArgoCD Architecture](https://argo-cd.readthedocs.io/en/stable/operator-manual/architecture/) - Comprehensive architecture documentation

### Key Concepts You'll Learn

**GitOps Benefits for SRE Operations** include declarative infrastructure that prevents configuration drift through continuous reconciliation, Git-based audit trails that provide complete change history for compliance and troubleshooting, automated synchronization between Git state and cluster state that reduces manual deployment errors, and clear separation between application development and deployment operations that enables better security and governance.

**ArgoCD Architecture Components** consist of the API Server that provides the web UI and gRPC API for user interaction, the Repository Server that maintains cached copies of Git repositories for efficient synchronization, the Application Controller that monitors applications and synchronizes cluster state with Git definitions, and the Dex component that provides authentication integration with external identity providers.

**Deployment Automation Through GitOps** enables ArgoCD to continuously monitor Git repositories for configuration changes, compare desired state defined in Git with actual cluster state, automatically apply configuration changes through Kubernetes APIs, and provide real-time visibility into deployment status and application health through comprehensive dashboards and alerting integration.

---

## Understanding GitOps for Deployment Management

Your current deployment approach from previous exercises relies on manual kubectl commands for deployment management. While functional for development and learning, this approach creates operational challenges in production environments including potential configuration drift between environments, manual change tracking that lacks comprehensive audit trails, limited deployment history and rollback capabilities, and imperative deployment processes that can create inconsistent state across cluster resources.

### Current State vs GitOps Target

**Current Manual Process Limitations** require direct cluster access for deployments, creating security and scalability concerns. Manual processes use imperative commands that modify cluster state directly without declarative tracking, provide limited deployment history and audit trails for compliance requirements, and rely on human intervention for deployment coordination and rollback procedures that increase mean time to recovery during incidents.

**GitOps Target State Benefits** use Git repositories as the single source of truth for deployment configuration, enabling version control and collaborative review processes. ArgoCD continuously monitors Git for changes and automatically applies updates through reconciliation loops, maintains complete deployment history through Git commits with author attribution and change descriptions, and provides automated synchronization with clear visibility into deployment status, drift detection, and health monitoring.

### Why GitOps Matters for Production Operations

**Improved Deployment Reliability** through declarative configuration ensures consistent deployment state across environments and eliminates manual configuration errors. **Enhanced Change Management** through Git-based approval workflows provides mandatory code review processes, complete audit trails for compliance frameworks, and automated rollback capabilities that reduce incident response time.

**Reduced Operational Overhead** through automation of manual deployment processes eliminates human error during deployments, provides automated configuration drift detection and correction, and enables self-service deployment capabilities for development teams while maintaining operational control and visibility.

**Security and Compliance Benefits** include removal of direct cluster access requirements for developers, centralized audit logging of all infrastructure changes, and integration with existing Git-based security tools and policies that support enterprise governance frameworks.

---

## Setting Up ArgoCD for Automated Deployments

### Preparing the GitOps Engine

ArgoCD serves as the automation engine that continuously synchronizes your desired deployment state (stored in Git) with your actual cluster state. This section guides you through deploying ArgoCD with production-ready configuration that includes proper security settings, resource management, and operational visibility features essential for production GitOps workflows.

### Step 1: Navigate to Exercise Environment and Deploy ArgoCD

Set up your working directory and install ArgoCD with comprehensive automation:

```bash
# Navigate to Exercise 6 directory
cd exercises/exercise6
```

**Examine the ArgoCD setup automation before execution:**

```bash
# Review the setup script structure
head -30 scripts/setup-argocd.sh
```

The setup script implements production-ready ArgoCD deployment including namespace isolation, LoadBalancer configuration for external access, comprehensive health checking with timeout handling, and automated credential retrieval for immediate access.

**Execute the automated ArgoCD installation:**

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

# Retrieve ArgoCD Credentials and URL

> If you ever need to retrieve the ArgoCD credentials and access URL, you can run the following commands:

```bash
# Get ArgoCD IP and password together
export ARGOCD_IP=$(kubectl get service argocd-server-lb -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "ArgoCD Access Information:"
echo "URL: https://$ARGOCD_IP"
echo "Username: admin"
echo "Password: $ARGOCD_PASSWORD"
```

> This will print the ArgoCD access URL, along with the username and password needed to log in.

**Understanding the deployment process:** ArgoCD deployment takes 3-5 minutes as the system provisions LoadBalancer resources, initializes authentication systems, and establishes repository connections. The automated script handles all complexity while providing clear progress indicators and troubleshooting information.

**Monitor ArgoCD deployment components:**

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

**Component analysis:** Each ArgoCD component serves specific purposes in the GitOps workflow. The application controller manages deployment synchronization, the repository server caches Git content for performance, the API server provides user interface and API access, and the notification controller handles integration with external alerting systems.

**Access and verify the ArgoCD web interface:**

Navigate to the ARGOCD_IP URL from your terminal output and accept the self-signed certificate when prompted by your browser. Login with username `admin` and the password from your terminal output. Verify you can see the ArgoCD dashboard, which should be empty initially but ready for application configuration.

This initial interface verification confirms that ArgoCD is properly deployed and accessible, providing the foundation for GitOps workflow implementation.

### Step 2: Install and Configure ArgoCD CLI

Set up command-line access for ArgoCD management and automation integration:

```bash
# Install ArgoCD CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

**Authenticate with ArgoCD server:**

```bash
# Login to ArgoCD
argocd login $ARGOCD_IP --username admin --password $ARGOCD_PASSWORD --insecure
```

**Expected output:**
```
'admin:login' logged in successfully
Context '$ARGOCD_IP' updated
```

**Note**: If you receive ArgoCD CLI help text instead of successful login, the environment variables may have been cleared. Re-export them using the provided commands and retry authentication.

**Alternative authentication method if environment variables are cleared:**

```bash
# Re-export ArgoCD credentials if needed
export ARGOCD_IP=$(kubectl get service argocd-server-lb -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Then retry the login
argocd login $ARGOCD_IP --username admin --password $ARGOCD_PASSWORD --insecure
```

**Understanding CLI authentication:** The ArgoCD CLI provides programmatic access to GitOps operations including application management, synchronization control, and status monitoring. This CLI access enables integration with automation scripts and CI/CD pipelines for comprehensive deployment workflows.

---

## Implementing GitOps Deployment Pipelines

### Connecting Git State to Cluster Deployments

This section establishes the GitOps deployment pipeline that connects your application configuration stored in Git repositories to automated cluster deployments through ArgoCD. You'll experience the fundamental GitOps principle where Git becomes the single source of truth for your infrastructure state.

### Step 3: Configure GitOps Repository Structure

Examine and understand the GitOps deployment configuration that implements declarative infrastructure management:

```bash
# Examine the ArgoCD deployment
cat k8s/gitops/deployment.yaml
```

**Understanding enhanced deployment configuration:** The GitOps deployment extends your Exercise 3 configuration with additional metadata, deployment tracking annotations, and enhanced observability features that support automated rollback and health monitoring through ArgoCD integration.

```bash
# Examine the ArgoCD application configuration
cat k8s/argocd/application.yaml
```

**Critical GitOps structure principles implemented:** The `k8s/gitops/` directory contains declarative Kubernetes manifests that define your application's desired state in a format that ArgoCD can monitor and apply automatically. This separation between application code and deployment configuration enables independent versioning and change management processes.

**Key GitOps architecture patterns:** 
- **Declarative Configuration**: All deployment state defined in version-controlled YAML manifests that can be reviewed, approved, and audited
- **Git as Source of Truth**: Changes must go through Git workflows with proper review processes and commit attribution
- **Automated Synchronization**: ArgoCD applies changes without manual intervention through continuous reconciliation loops
- **Complete Auditability**: All changes tracked through Git commit history with author information and change descriptions

**Repository structure benefits:** This organization pattern enables team collaboration on infrastructure changes, provides rollback capabilities through Git history, and maintains separation between application development and operational deployment concerns.

### Step 4: Create ArgoCD Application

Configure ArgoCD to manage your demo application through GitOps workflows:

**Important configuration customization:** Before applying the ArgoCD application, update the repository URL to match your GitHub repository for proper Git-based synchronization.

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
kubectl apply -f k8s/argocd/application.yaml
```

**Expected output:**
```
application.argoproj.io/sre-demo-gitops created
```

**Verify application creation and initial sync status:**

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

**Understanding application status indicators:** The output shows successful GitOps implementation with sync status indicating Git commit tracking, health status confirming proper resource deployment, and individual resource status providing detailed deployment feedback.

**Access the ArgoCD application view:** Navigate to the URL shown in the `argocd app get` output to access the visual representation of your GitOps-managed application with real-time status updates and resource relationship visualization.

---

## Exploring ArgoCD Operations

### Understanding GitOps Through ArgoCD Interface

This section focuses on understanding GitOps operations through direct interaction with ArgoCD, demonstrating how declarative configuration management works in practice while providing operational visibility essential for production deployment management.

### Step 5: Explore ArgoCD Interface and Concepts

**Navigate to your ArgoCD application** and explore the comprehensive interface that provides operational visibility:

**Application Overview Analysis** provides real-time sync status indicating Git synchronization state, health indicators showing resource operational status, and resource hierarchy visualization that displays relationships between Kubernetes resources for troubleshooting and understanding deployment dependencies.

**Resource Tree Exploration** demonstrates how ArgoCD displays the relationships between Kubernetes resources through visual representation of Deployment → ReplicaSet → Pod relationships, Service networking configuration and endpoint discovery, and configuration management through ConfigMaps and Secrets with dependency tracking.

**Sync Controls Understanding** reveals the difference between manual and automatic synchronization options available in the interface, providing operational control over deployment timing, risk management during critical operations, and emergency override capabilities for incident response scenarios.

**History Tab Analysis** enables review of deployment history and previous configurations through comprehensive change tracking, Git commit correlation with deployment events, and rollback capability assessment with impact analysis for operational decision-making.

**Practice ArgoCD operations using CLI for programmatic access:**

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

**Understanding ArgoCD Application Status Indicators:**

The ArgoCD interface provides comprehensive visibility into your GitOps deployment lifecycle. Key status indicators you'll observe include detailed sync status progression and resource health monitoring.

**Sync Status Progression Analysis:**
- **OutOfSync**: ArgoCD detects differences between Git configuration and actual cluster state, indicating pending changes
- **Sync OK**: Git state matches cluster state successfully, confirming desired configuration is deployed
- **Progressing**: Kubernetes resources are being created or updated, showing active deployment in progress  
- **Healthy**: All resources are running and ready, indicating successful deployment completion

**Resource Tree View Components** display your application infrastructure including Deployment resource management with replica scaling and update strategies, Service networking configuration with load balancing and endpoint management, and individual Pod instances with detailed status, age indicators, and resource consumption metrics for operational monitoring.

---

## Testing GitOps Configuration Management

### Experimenting with Declarative Configuration Changes

This section demonstrates the core GitOps workflow by making controlled configuration changes and observing how ArgoCD automatically applies them to your cluster. You'll experience the fundamental difference between imperative commands and declarative infrastructure management that defines modern SRE practices.

### Step 6: Test GitOps Workflow with Configuration Changes

#### Understanding Configuration Change Workflows

Before making configuration changes, understand that GitOps workflows require all changes to flow through Git commits and ArgoCD synchronization rather than direct kubectl commands. This approach provides audit trails, rollback capabilities, and prevents configuration drift that can occur with manual cluster modifications.

#### 1. Check Current Application State

Before making configuration changes, examine the current state of your application to establish a baseline for comparison:

```bash
# Check current deployment configuration
kubectl get deployment sre-demo-app -o yaml | grep -A 5 "replicas\|image:"
```

**Expected output:**

```
  labels:
    app: sre-demo-app
    component: backend
--
  replicas: 2
  revisionHistoryLimit: 1
  selector:
    matchLabels:
      app: sre-demo-app
  strategy:
--
        image: us-central1-docker.pkg.dev/gcp-sre-lab/sre-demo-app/sre-demo-app:latest
        imagePullPolicy: Always
        livenessProbe:
          failureThreshold: 3
          httpGet:
            path: /health
--
  replicas: 2
  updatedReplicas: 2
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

**Understanding baseline importance:** Establishing current state provides reference points for validating that GitOps changes apply correctly and enables rollback planning if configuration changes cause unexpected issues.

```bash
# Check ArgoCD application current state
argocd app get sre-demo-gitops | grep -A 10 "GROUP.*KIND"
```

**Expected output:**

```
GROUP  KIND        NAMESPACE  NAME               STATUS  HEALTH   HOOK  MESSAGE
       Service     default    sre-demo-service   Synced  Healthy        service/sre-demo-service unchanged
       Service     default    sre-demo-headless  Synced  Healthy        service/sre-demo-headless unchanged
apps   Deployment  default    sre-demo-app       Synced  Healthy        deployment.apps/sre-demo-app configured
```

#### 2. Make a Configuration Change

Scale the application to test GitOps synchronization and observe automated deployment management:

```bash
sed -i 's/replicas: 2/replicas: 3/g' k8s/gitops/deployment.yaml
grep "replicas:" k8s/gitops/deployment.yaml
```

**Expected output:**

```
replicas: 3
```

**Understanding declarative changes:** This modification updates the desired state definition in Git, but doesn't immediately affect cluster state. The change becomes effective only after Git commit and ArgoCD synchronization, demonstrating the GitOps principle of Git as the single source of truth.

#### 3. Commit and Push

Create a Git commit that triggers the GitOps workflow:

```bash
git add k8s/gitops/deployment.yaml
git commit -m "gitops: Scale application to 3 replicas for testing"
git push origin main
```

**Git workflow importance:** The commit creates an immutable change record with author attribution, timestamp, and change description that supports audit requirements and rollback capabilities essential for production operations.

#### 4. Refresh ArgoCD and Apply Changes

ArgoCD may take time to detect the new commit through polling. Force a refresh to demonstrate immediate synchronization:

**From the CLI:**

```bash
argocd app get sre-demo-gitops --refresh
```

**Important ArgoCD Configuration Note:** If you encounter the "OutOfSync" issue where ArgoCD shows as synchronized but the cluster maintains different replica counts, this indicates the ArgoCD application configuration contains `ignoreDifferences` for replicas. Remove this configuration to allow proper GitOps management:

```bash
# Edit the ArgoCD application configuration to remove replica ignore rules
# Remove the /spec/replicas line from ignoreDifferences section in k8s/argocd/application.yaml
kubectl apply -f k8s/argocd/application.yaml

# Force synchronization
argocd app sync sre-demo-gitops
```

**From the ArgoCD UI:**

1. Open your application in the ArgoCD interface
2. Click **SYNC** and then **SYNCHRONIZE** to trigger immediate synchronization
3. Observe the application transition to showing 3 replicas with real-time status updates

#### 5. Verify GitOps Synchronization

**From the Terminal verification:**

```bash
kubectl get pods -l app=sre-demo-app
```

**Expected output:**

```
NAME                            READY   STATUS    RESTARTS   AGE
sre-demo-app-84b5769f44-xyz123  1/1     Running   0          2m
sre-demo-app-84b5769f44-xyz456  1/1     Running   0          2m
sre-demo-app-84b5769f44-xyz789  1/1     Running   0          1m
```

```bash
kubectl get deployment sre-demo-app
```

**Expected output:**

```
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
sre-demo-app   3/3     3            3           2d20h
```

```bash
# Verify ArgoCD shows synchronized status
argocd app get sre-demo-gitops | grep -E "Sync Status|Health Status"
```

**Expected output:**

```
Sync Status:        Synced to HEAD (513bb96)
Health Status:      Healthy
```

#### 6. Test GitOps Anti-Drift Protection

Demonstrate how GitOps prevents configuration drift by automatically correcting manual changes:

```bash
# Attempt manual scaling (should be automatically reverted)
kubectl scale deployment sre-demo-app --replicas=5

# Wait 30 seconds and observe automatic correction
sleep 30
kubectl get deployment sre-demo-app -o jsonpath='{.spec.replicas}' && echo
```

**Expected behavior:** The deployment should automatically revert from 5 replicas back to 3 replicas within 30 seconds, demonstrating ArgoCD's continuous reconciliation loop.

```bash
# Verify ArgoCD maintains sync status during drift correction
argocd app get sre-demo-gitops | grep -E "Sync Status|Health Status"
```

```bash
# Examine deployment events showing the anti-drift correction
kubectl describe deployment sre-demo-app | tail -10
```

**Expected output showing anti-drift events:**

```
Events:
  Type    Reason             Age                From                   Message
  ----    ------             ----               ----                   -------
  Normal  ScalingReplicaSet  45s                deployment-controller  Scaled up replica set sre-demo-app-84b5769f44 from 3 to 5
  Normal  ScalingReplicaSet  38s                deployment-controller  Scaled down replica set sre-demo-app-84b5769f44 from 5 to 3
```

### Understanding Configuration Drift Prevention

**Key GitOps Learning Points:** Git serves as the authoritative source of truth and ArgoCD continuously enforces this state. Manual scaling attempts are automatically corrected through reconciliation loops within seconds. This demonstrates how GitOps prevents configuration drift by automatically detecting and correcting deviations from the declared state.

**Production Benefits:** This anti-drift protection ensures that unauthorized changes cannot persist in production environments, maintaining consistency across all deployments while providing complete audit trails through Git commit history.

**GitOps Workflow Validation:** You have successfully demonstrated:
1. **Declarative Configuration Management** - Changes flow through Git commits
2. **Automated Synchronization** - ArgoCD detects and applies Git changes automatically  
3. **Configuration Drift Prevention** - Manual changes are automatically reverted
4. **Complete Audit Trails** - All changes tracked through Git commit history
5. **Self-Healing Infrastructure** - System maintains desired state without human intervention

## Step 7: Test Rollback Using the ArgoCD UI

Now that you've experienced GitOps reconciliation with scaling changes, explore how ArgoCD handles **production rollback scenarios** directly through the web interface.

### Understanding Rollback Operations

Rollback capabilities represent critical operational functionality for incident response and change management. ArgoCD provides multiple rollback mechanisms that enable rapid recovery while maintaining audit trails and change tracking essential for production operations.

1. **Open your ArgoCD Application** (`sre-demo-gitops`) in the UI.
   The interface displays your complete resource tree showing Services, Deployment, ReplicaSets, and Pods with real-time status indicators.

2. **Navigate to the "History and Rollback" tab**.
   This comprehensive view shows the complete deployment history ArgoCD has recorded, with each entry tied to specific Git commits including author information, timestamps, and change descriptions.

3. **Select a previous revision** in the deployment history list.
   Choose the commit immediately before your scaling change to demonstrate rollback to a known-good configuration state.

4. **Click "Rollback"** to redeploy the selected revision.
   ArgoCD will update your cluster to match the older commit configuration, demonstrating automated rollback capabilities essential for incident response.

**⚠️ Critical Production Understanding:** The rollback operation is temporary in the ArgoCD interface. Since Git still declares the current state in the manifest files, ArgoCD's reconciliation loop will eventually restore the Git-declared configuration. This behavior illustrates the fundamental GitOps principle that **Git always serves as the single source of truth**.

**Production rollback workflow:** In real production scenarios, permanent rollbacks require either updating the Git repository to the desired state or creating new commits that revert previous changes, ensuring that Git history maintains accurate deployment records.

---

## Step 8: Explore Sync Policies and Manual Control

Experiment with ArgoCD's **synchronization policies** to understand operational control mechanisms for deployment management.

### Understanding Synchronization Strategy Options

Synchronization policies provide operational flexibility for different deployment scenarios including emergency changes, staged rollouts, and maintenance windows where manual control becomes essential for risk management.

1. **In the ArgoCD Application view**, navigate to the **App Details** tab.
   Locate the **Sync Policy** section that displays current automation settings and available policy options.

2. **Switch the policy from "Automated" to "Manual."**
   This configuration change stops ArgoCD from automatically applying Git changes, providing manual gate control over deployment timing while maintaining drift detection capabilities.

3. **Make a Git change** to test manual synchronization workflow.
   Add a comment line to `deployment.yaml` and push the change to your repository to simulate configuration updates.

4. **Observe OutOfSync detection without automatic remediation.**
   Return to the ArgoCD UI where you'll see the application status change to **OutOfSync**, indicating ArgoCD has detected repository changes but is waiting for manual approval to apply them.

5. **Apply changes manually through UI control:**
   Click **SYNC** → **SYNCHRONIZE** to apply the detected changes manually, providing controlled deployment timing and change validation opportunities.

6. **Restore automated synchronization** when testing is complete.
   Switch the sync policy back to Automated mode so ArgoCD resumes enforcing Git state automatically through continuous reconciliation.

**Operational policy benefits:** Manual sync policies enable controlled deployment timing during critical operations, provide approval gates for high-risk changes, and support staged rollout procedures while maintaining GitOps audit trails and rollback capabilities.

## Step 9: Environment Cleanup

Restore the environment to its original state by scaling back to 2 replicas:

```bash
# Scale back to original configuration
sed -i 's/replicas: 3/replicas: 2/g' k8s/gitops/deployment.yaml
```

```bash
# Commit and push the cleanup change
git add k8s/gitops/deployment.yaml
git commit -m "gitops: Restore original replica count to 2"
git push origin main
```

```bash
# Force ArgoCD synchronization
argocd app sync sre-demo-gitops
```

```bash
# Verify cleanup completed
kubectl get deployment sre-demo-app -o jsonpath='{.spec.replicas}' && echo
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

---

### Key Learning Summary

* **Rollback through the UI** provides rapid recovery capabilities for incident response, but permanent changes require Git repository updates to maintain consistent state
* **Synchronization Policies** offer operational flexibility including automated enforcement for normal operations and manual control for staged deployments or emergency changes
* **ArgoCD Interface** provides comprehensive visibility including resource tree visualization, deployment history tracking, health monitoring, and synchronization control without requiring CLI command expertise

---

## Final Objective

By completing this exercise, you should be able to demonstrate:

Your application deploys using GitOps principles with ArgoCD managing automated synchronization from Git repositories, providing continuous reconciliation between desired and actual state. You understand how to make declarative configuration changes that ArgoCD automatically detects and applies to your cluster through Git-based workflows. You can use ArgoCD's interface to monitor deployment status, review deployment history, and perform rollback operations with full audit trail maintenance. The complete GitOps workflow provides comprehensive audit trails through Git commits and reduces manual deployment effort through automated synchronization while preventing configuration drift through continuous reconciliation.

### Verification Questions

Test your understanding by answering these questions:

1. **How does** ArgoCD detect when configuration changes are made in Git repositories, and what mechanisms ensure timely synchronization?

2. **What is** the fundamental difference between imperative and declarative deployment management in terms of operational reliability and audit capabilities?

3. **Why is** Git-based audit trail valuable for deployment operations and compliance frameworks in enterprise environments?

4. **How would** you troubleshoot an ArgoCD application that shows "OutOfSync" status, and what steps ensure successful synchronization?

5. **What are** the operational benefits of using GitOps compared to direct kubectl deployment commands for production environment management?

---

## Troubleshooting

### Common Issues

**ArgoCD not syncing changes from Git**: Check repository access with `argocd app get sre-demo-gitops` and verify that ArgoCD can reach your GitHub repository. Ensure the repository path and branch are correctly configured in the application definition and that network policies allow ArgoCD to access external Git repositories.

**ArgoCD application stuck in OutOfSync**: Check for resource conflicts with `argocd app get sre-demo-gitops -o yaml` and verify that ArgoCD has necessary RBAC permissions for the target namespace. Try manual sync with `argocd app sync sre-demo-gitops` and examine sync operation logs for specific error details.

**Manual sync required repeatedly**: This behavior is common in development environments like Codespaces due to network latency and polling intervals. Use `argocd app sync sre-demo-gitops` when needed, or switch to manual sync policy for testing to maintain control over synchronization timing.

**Web interface not accessible**: Verify LoadBalancer IP assignment with `kubectl get service argocd-server-lb -n argocd` and ensure firewall rules allow access to the ArgoCD port. Check that the LoadBalancer service has successfully provisioned an external IP address.

**CLI login issues**: Confirm ArgoCD server is accessible and use the `--insecure` flag for development environments with self-signed certificates. Verify that the admin password is correctly retrieved and that network connectivity allows GRPC communication.

### Advanced Troubleshooting

**Debugging GitOps sync failures**: Check ArgoCD server logs with `kubectl logs -n argocd deployment/argocd-server` and review application events with `argocd app get sre-demo-gitops --show-events`. Examine repository server logs for Git connectivity issues and authentication problems.

**Repository access issues**: Verify repository URL in application definition and check ArgoCD repository server logs with `kubectl logs -n argocd deployment/argocd-repo-server`. Ensure that SSH keys or authentication tokens are properly configured for private repositories.

**Resource sync conflicts**: Use `kubectl get events` to identify resource-level issues and compare desired state in Git with actual cluster state using `kubectl diff`. Check for resource dependencies and timing issues that may cause synchronization failures.

**Performance and scaling considerations**: Monitor ArgoCD resource usage with `kubectl top pods -n argocd` and adjust resource limits if applications experience sync delays. Consider implementing repository caching strategies for large repositories with frequent changes.

### Networking and Connectivity Issues

**LoadBalancer IP assignment failures**: Check Google Cloud Platform quotas for external IP addresses and verify that the Container Registry API is enabled. Ensure that your GKE cluster has proper networking configuration for LoadBalancer services.

**Git repository connectivity problems**: Verify DNS resolution for Git providers and check firewall rules that may block ArgoCD from accessing external repositories. Test repository access manually from ArgoCD pods using kubectl exec for debugging.

**Certificate and authentication failures**: For self-signed certificates, use the `--insecure` flag with ArgoCD CLI commands. For production environments, configure proper TLS certificates and certificate authorities for secure communication.

---

## Next Steps

You have successfully implemented GitOps deployment management using ArgoCD for automated Kubernetes deployments with comprehensive audit trails and operational visibility. You've established declarative deployment workflows that eliminate configuration drift, learned to use ArgoCD's interface for deployment management and troubleshooting, tested configuration changes through Git workflows that provide complete change tracking, and experienced the operational benefits of GitOps including automated rollback capabilities and reduced manual deployment effort.

**Proceed to [Exercise 7](../exercise7/)** where you will implement comprehensive production readiness including security hardening strategies, cost optimization techniques, disaster recovery procedures, and compliance frameworks that build upon your reliable GitOps deployment infrastructure for enterprise-grade operations.

**Key Concepts to Remember**: GitOps provides declarative, auditable deployment management that reduces human error and improves reliability through continuous reconciliation. ArgoCD serves as the automation engine that continuously synchronizes Git state with cluster state while providing operational visibility and control. Git-based workflows provide complete audit trails and enable easy rollback to previous configurations through version control history. Automated synchronization eliminates configuration drift and reduces manual deployment effort while maintaining security through controlled access and approval processes.

**Before Moving On**: Ensure you can explain how GitOps improves deployment reliability compared to manual processes through declarative state management, how ArgoCD detects and applies configuration changes through continuous monitoring and reconciliation, and how Git-based workflows provide better audit trails and rollback capabilities than imperative deployment approaches. In the next exercise, you'll implement enterprise-grade production readiness practices that build upon this reliable GitOps foundation.