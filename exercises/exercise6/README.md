# Exercise 6: Production CI/CD

## Table of Contents

* [Introduction](#introduction)
* [Learning Objectives](#learning-objectives)
* [Prerequisites](#prerequisites)
* [Theory Foundation](#theory-foundation)
* [Understanding GitOps for SRE](#understanding-gitops-for-sre)
* [Setting Up ArgoCD for GitOps](#setting-up-argocd-for-gitops)
* [Implementing Automated Deployment Pipelines](#implementing-automated-deployment-pipelines)
* [Deployment Safety and Validation Gates](#deployment-safety-and-validation-gates)
* [Rollback Procedures and Automation](#rollback-procedures-and-automation)
* [Pipeline Monitoring and Observability](#pipeline-monitoring-and-observability)
* [Final Objective](#final-objective)
* [Troubleshooting](#troubleshooting)
* [Next Steps](#next-steps)

---

## Introduction

In this exercise, you will implement production-ready CI/CD pipelines using GitOps principles with ArgoCD. You'll create automated deployment workflows that include safety gates, monitoring validation, and automated rollback capabilities. This exercise demonstrates how modern SRE teams manage deployments with reliability, traceability, and minimal human intervention while maintaining service availability.

The deployment system you'll build integrates seamlessly with the monitoring and alerting infrastructure from Exercises 4-5, using SLO metrics to validate deployments and trigger rollbacks when necessary.

---

## Learning Objectives

By completing this exercise, you will understand:

- **GitOps Implementation**: How to implement declarative, Git-based deployment workflows
- **ArgoCD Configuration**: How to deploy and configure ArgoCD for continuous deployment
- **Deployment Safety Gates**: How to use monitoring data to validate deployment success
- **Automated Rollback**: How to implement SLO-based rollback automation
- **Blue-Green Deployments**: How to implement zero-downtime deployment strategies
- **Pipeline Observability**: How to monitor and alert on deployment pipeline health
- **Release Management**: How to coordinate releases with monitoring and incident response

---

## Prerequisites

Before starting this exercise, ensure you have completed:

- Exercise 1: Cloud Development Environment & SRE Application
- Exercise 2: Container Builds & GitHub Actions  
- Exercise 3: Kubernetes Deployment
- Exercise 4: Cloud Monitoring Stack
- Exercise 5: Alerting and Response
- Successfully deployed monitoring infrastructure with Prometheus and Alertmanager
- Working alerting system with SLO-based alerts
- Understanding of your application's key metrics and SLO targets

Note: This exercise requires the complete observability stack from previous exercises for deployment validation.

---

## Theory Foundation

### GitOps Principles and Benefits

**Essential Watching** (20 minutes):
- [GitOps Explained in 100 Seconds](https://www.youtube.com/watch?v=f5EpcWp0THw) by Fireship - Quick GitOps overview
- [GitOps with ArgoCD](https://www.youtube.com/watch?v=MeU5_k9ssrs) by TechWorld with Nana - ArgoCD implementation

**Reference Documentation**:
- [GitOps Principles](https://opengitops.dev/) - Official GitOps working group principles
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/en/stable/) - Complete ArgoCD implementation guide

### Deployment Strategies and SRE

**Essential Watching** (15 minutes):
- [Blue-Green vs Rolling vs Canary Deployments](https://www.youtube.com/watch?v=AWVTKBUnoIg) by TechWorld with Nana - Deployment strategy comparison
- [SRE Deployment Best Practices](https://www.youtube.com/watch?v=4xzs2mMDiUE) by Google Cloud - Production deployment patterns

**Reference Documentation**:
- [Google SRE Book - Release Engineering](https://sre.google/sre-book/release-engineering/) - Production deployment practices
- [Kubernetes Deployment Strategies](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) - Native Kubernetes deployment patterns

### Key Concepts You'll Learn

**GitOps Benefits for SRE** include declarative infrastructure that eliminates configuration drift, Git-based audit trails for all changes, automated rollback capabilities when issues are detected, and separation of concerns between application code and deployment configuration.

**Deployment Safety Gates** use your existing monitoring infrastructure to validate that deployments don't degrade user experience. This includes SLO compliance checks, error rate validation, and latency monitoring before marking deployments as successful.

**Automated Rollback Systems** respond to SLO violations or alert conditions by automatically reverting to the last known good version, minimizing Mean Time to Resolution (MTTR) and reducing the impact of problematic deployments.

---

## Understanding GitOps for SRE

Your current deployment process from Exercise 2 uses GitHub Actions to build and push container images, but lacks the declarative, Git-driven deployment management that GitOps provides. GitOps transforms your deployment process into a reliable, observable, and automatically recoverable system.

### Current State vs GitOps Target State

**Current State** uses imperative kubectl commands and manual deployment verification. Changes require direct cluster access, configuration drift is possible, rollbacks require manual intervention, and deployment state isn't consistently tracked.

**GitOps Target State** uses declarative Git repositories as the single source of truth for deployments. ArgoCD continuously monitors Git for changes, automatically applies updates, validates deployments against SLO metrics, and provides automated rollback when issues are detected.

### SRE Benefits of GitOps

**Reduced MTTR** through automated rollback when monitoring indicates deployment issues. **Improved Reliability** through consistent, repeatable deployment processes. **Enhanced Observability** through Git-based audit trails and deployment tracking. **Decreased Human Error** through automation of manual deployment tasks.

---

## Setting Up ArgoCD for GitOps

### Preparing the Orchestration Engine

You have defined your reliability targets and built a robust monitoring and alerting stack. The final step is to automate the deployment process itself to ensure consistency and reliability. This section focuses on setting up **ArgoCD**, the "orchestration engine" that will manage your deployments. ArgoCD continuously monitors your Git repository for changes and automatically synchronizes them to your cluster, eliminating manual intervention and providing a single source of truth for your entire production environment.

### Step 1: Deploy ArgoCD to Your Cluster

Navigate to Exercise 6 and deploy ArgoCD using the provided automation:

```bash
# Navigate to Exercise 6 directory
cd exercises/exercise6
```

```bash
# Examine the ArgoCD setup configuration
cat scripts/setup-gitops.sh
```

```bash
# Make setup script executable and run
chmod +x scripts/setup-gitops.sh
./scripts/setup-gitops.sh
```

```bash
# Monitor ArgoCD deployment
kubectl get pods -n argocd -w
```

The setup script creates the ArgoCD namespace, deploys ArgoCD components, configures RBAC permissions, sets up LoadBalancer access, and generates initial admin credentials for secure access.

ArgoCD deployment typically takes 3-5 minutes. The script waits for all components to be ready before proceeding.

### Step 2: Access ArgoCD Web Interface

```bash
# Get ArgoCD external IP
export ARGOCD_IP=$(kubectl get service argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "ArgoCD URL: https://$ARGOCD_IP"
```

```bash
# Get initial admin password
export ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Admin username: admin"
echo "Admin password: $ARGOCD_PASSWORD"
```

Access the ArgoCD web interface using HTTPS (accept the self-signed certificate) and log in with the admin credentials. The interface provides visual representation of your applications, deployment status, and synchronization history.

### Step 3: Configure Git Repository Access

Set up ArgoCD to monitor your GitHub repository for deployment configurations:

```bash
# Add your GitHub repository to ArgoCD
argocd app create sre-demo-app \
  --repo https://github.com/$(git config --get remote.origin.url | cut -d: -f2 | cut -d. -f1) \
  --path exercises/exercise6/k8s \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy automated \
  --sync-option CreateNamespace=true
```

This configuration tells ArgoCD to monitor your repository's `exercises/exercise6/k8s` directory for Kubernetes manifests and automatically apply changes when detected.

---

## Implementing Automated Deployment Pipelines

### Connecting Code to the Cluster

The core of a GitOps pipeline is the seamless integration between your application's code repository and the deployment environment. This section shows you how to connect your **GitHub Actions** workflow to your new ArgoCD setup. The process you'll build ensures that every approved code change automatically triggers a new container build, updates your Kubernetes manifests in Git, and then lets ArgoCD take over to manage the deployment to your cluster.

### Step 4: Enhance GitHub Actions for GitOps

Update your GitHub Actions workflow to work with GitOps principles:

```bash
# Examine the enhanced GitHub Actions workflow
cat .github/workflows/gitops-deploy.yml
```

```bash
# Review the automated deployment validation
cat scripts/deploy-validation.sh
```

The enhanced workflow builds container images, updates Kubernetes manifests with new image tags, commits changes to trigger ArgoCD sync, validates deployment success using SLO metrics, and triggers rollback if validation fails.

### Step 5: Configure ArgoCD Application

Create the ArgoCD application configuration for your SRE demo app:

```bash
# Examine the ArgoCD application definition
cat k8s/argocd-app.yaml
```

```bash
# Apply the ArgoCD application
kubectl apply -f k8s/argocd-app.yaml
```

```bash
# Verify application is created in ArgoCD
argocd app list
argocd app get sre-demo-app
```

The ArgoCD application configuration defines source repository, target cluster, synchronization policies, health check configuration, and automated sync settings that govern how deployments are managed.

### Step 5b: Create Feature Branch for Pipeline Testing

Use a feature branch to test the workflow’s **test-application job** (linting, security scan, startup validation) without triggering full deployments.

```bash
# Create and switch to a feature branch for testing
git checkout -b exercise6-pipeline-test
```

```bash
# Add a pipeline test file
echo "Pipeline test for Exercise 6 - $(date)" > exercises/exercise6/.pipeline-test
```

```bash
# Commit and push to trigger the workflow
git add exercises/exercise6/.pipeline-test
git commit -m "test: Trigger Exercise 6 pipeline checks"
git push origin exercise6-pipeline-test
```

**Expected behavior**: only the **test-application job** runs.
The container build, manifest updates, and deployment validation jobs will only run when changes are merged into `main`.

### Step 6: Test Automated Deployment

> The **full pipeline (build, push, manifest update, ArgoCD validation)** only runs on `main`.
> Use feature branches (`exercise*`) for safe testing, then merge into `main` to trigger production-grade deployments.

Make a change to trigger the complete GitOps workflow:

```bash
# Make a small change to trigger deployment
echo "GitOps deployment test $(date)" >> app/config.py
```

```bash
# Commit and push to trigger GitHub Actions
git add .
git commit -m "test: Trigger GitOps deployment workflow"
git push origin main
```

```bash
# Monitor the deployment process
echo "Monitor GitHub Actions at: https://github.com/$(git config --get remote.origin.url | cut -d: -f2 | cut -d. -f1)/actions"
echo "Monitor ArgoCD at: https://$ARGOCD_IP"
```

This process triggers GitHub Actions to build new container images, update Kubernetes manifests, sync changes via ArgoCD, and validate deployment success using your monitoring infrastructure.

### Step 7: Clean Up Feature Branch

After verifying that your feature branch ran tests successfully, delete it to keep your repository clean:

```bash
# Switch back to main
git checkout main
```

```bash
# Delete local feature branch
git branch -d exercise6-pipeline-test
```

```bash
# Delete remote feature branch
git push origin --delete exercise6-pipeline-test
```

---

## Deployment Safety and Validation Gates

### The SRE Safety Net

Automation is powerful, but it's only truly reliable when it includes safeguards. A key tenet of SRE is to build systems that fail gracefully and avoid human error. This section focuses on creating **deployment safety gates** that use your monitoring and alerting stack to validate deployments. You will learn how to ensure that a new version of your application is only considered "successful" if it doesn't violate your **SLO** targets for latency, traffic, and error rates.

### Step 8: Implement SLO-Based Validation

Configure deployment validation that uses your SLO metrics to determine success:

```bash
# Examine the SLO validation configuration
cat monitoring/slo-queries.yaml
```

```bash
# Review deployment validation script
cat scripts/deploy-validation.sh
```

```bash
# Test validation logic manually
chmod +x scripts/deploy-validation.sh
./scripts/deploy-validation.sh test
```

The validation system checks availability SLO compliance, latency SLO metrics, error rate thresholds, business operation success rates, and resource utilization patterns before marking deployments as successful.

### Step 9: Configure Blue-Green Deployment Strategy

Implement blue-green deployments for zero-downtime updates:

```bash
# Examine blue-green deployment configuration
cat k8s/deployment-blue-green.yaml
```

```bash
# Review traffic switching configuration
cat k8s/service-blue-green.yaml
```

```bash
# Understand the blue-green orchestration
cat scripts/blue-green-deploy.sh
```

Blue-green deployment creates parallel environments, validates new version before traffic switch, provides instant rollback capability, and minimizes deployment risk through traffic management.

### Step 10: Set Up Deployment Monitoring

Configure monitoring for deployment pipeline health:

```bash
# Deploy deployment monitoring configuration
cat monitoring/deployment-alerts.yaml
kubectl apply -f monitoring/deployment-alerts.yaml
```

```bash
# Check deployment-specific dashboards
cat monitoring/deployment-dashboard.json
gcloud monitoring dashboards create --config-from-file=monitoring/deployment-dashboard.json
```

Deployment monitoring tracks deployment frequency, success rates, rollback frequency, deployment duration, and SLO impact during deployments.

---

## Rollback Procedures and Automation

### Minimizing Mean Time to Resolution (MTTR)

Even with safety gates, a problematic deployment can occasionally slip through. The key to maintaining high reliability is to have a fast and reliable recovery mechanism. This section focuses on automating the recovery process. You will implement a system that automatically triggers a **rollback** to the last known good version of your application when an SLO alert fires, drastically reducing the time it takes to restore service availability and preventing user-facing impact.

### Step 11: Implement Automated Rollback

Configure automated rollback based on SLO violations and alert conditions:

```bash
# Review rollback automation configuration
cat policies/rollback-rules.yaml
```

```bash
# Examine the rollback automation script
cat scripts/rollback-automation.sh
chmod +x scripts/rollback-automation.sh
```

```bash
# Test rollback procedures
./scripts/rollback-automation.sh test
```

Automated rollback monitors SLO compliance post-deployment, triggers rollback on alert conditions, coordinates with ArgoCD for Git-based rollback, and provides notification to relevant teams.

### Step 12: Test Rollback Scenarios

Simulate deployment issues to validate rollback automation:

```bash
# Create a problematic deployment for testing
echo "Creating test rollback scenario..."
```

```bash
# Deploy a version that will fail health checks
kubectl patch deployment sre-demo-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"sre-demo-app","env":[{"name":"FAIL_HEALTH_CHECKS","value":"true"}]}]}}}}'
```

```bash
# Monitor rollback automation
./scripts/rollback-automation.sh monitor
```

```bash
# Verify rollback occurred successfully
kubectl get deployment sre-demo-app -o yaml | grep -A5 -B5 env:
```

This test validates that rollback automation correctly detects deployment issues, initiates rollback procedures, restores service functionality, and logs rollback events for analysis.

---

## Pipeline Monitoring and Observability

### Step 13: Implement Deployment Pipeline Metrics

Create comprehensive monitoring for your deployment pipeline:

```bash
# Deploy pipeline monitoring configuration
kubectl apply -f monitoring/pipeline-metrics.yaml
```

```bash
# Create pipeline observability dashboard
gcloud monitoring dashboards create --config-from-file=dashboards/pipeline-dashboard.json
```

```bash
# Review pipeline health queries
cat monitoring/pipeline-queries.md
```

Pipeline metrics include deployment frequency (lead time, deployment frequency), quality metrics (deployment success rate, rollback rate), and performance metrics (deployment duration, time to rollback).

### Step 14: Configure Pipeline Alerting

Set up alerts for deployment pipeline health:

```bash
# Create deployment pipeline alert policies
gcloud alpha monitoring policies create --policy-from-file=alerting/deployment-alerts.yaml
```

```bash
# Configure pipeline notification channels
kubectl apply -f k8s/pipeline-notifications.yaml
```

```bash
# Test pipeline alerting
argocd app sync sre-demo-app --force
```

Pipeline alerting covers deployment failures, excessive rollback rates, SLO violations during deployment, ArgoCD sync failures, and deployment duration exceeding thresholds.

### Step 15: Establish Deployment Metrics Dashboard

Create comprehensive visibility into deployment pipeline performance:

```bash
# Access your deployment dashboard
echo "Deployment Dashboard: https://console.cloud.google.com/monitoring/dashboards?project=$(gcloud config get-value project)"
```

```bash
# Review key deployment metrics
export PROMETHEUS_IP=$(kubectl get service prometheus-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Prometheus deployment metrics: http://$PROMETHEUS_IP:9090"
```

```bash
# Check ArgoCD deployment status
echo "ArgoCD applications: https://$ARGOCD_IP/applications"
```

The dashboard displays deployment frequency trends, success/failure rates, rollback statistics, SLO impact during deployments, and deployment pipeline health metrics.

---

## Final Objective

By completing this exercise, you should be able to demonstrate:

Your application uses GitOps principles with ArgoCD for declarative, Git-driven deployments. The deployment pipeline includes automated safety gates that validate SLO compliance before marking deployments successful. Automated rollback systems respond to SLO violations by reverting to known good versions. The entire deployment process is observable through comprehensive metrics and dashboards. Blue-green deployment capabilities provide zero-downtime updates with instant rollback options.

### Verification Questions

Test your understanding by answering these questions:

1. **How does** GitOps improve deployment reliability compared to imperative deployment approaches?
2. **What role** do SLO metrics play in automated deployment validation and rollback decisions?
3. **Why is** the separation between application code repositories and configuration repositories important in GitOps?
4. **How would** you modify the system to support canary deployments instead of blue-green deployments?

---

## Troubleshooting

### Common Issues

**ArgoCD not syncing changes from Git**: Verify repository access and webhook configuration with `argocd app get sre-demo-app` and check that ArgoCD can reach your GitHub repository. Ensure the repository path and branch are correctly configured.

**Deployment validation failing**: Check SLO queries in Prometheus with `curl "http://$PROMETHEUS_IP:9090/api/v1/query?query=<your_slo_query>"` and verify that your application is generating metrics correctly. Review validation thresholds in `scripts/deploy-validation.sh`.

**Rollback automation not triggering**: Verify alert policy configuration and check Prometheus alert rules with `kubectl logs -l app=prometheus | grep "rule evaluation"`. Ensure alert conditions match actual deployment scenarios.

**Blue-green deployments not switching traffic**: Check service selector configuration and verify that both blue and green deployments are healthy before traffic switch. Review load balancer configuration and endpoint status.

**ArgoCD application stuck in "OutOfSync" state**: Check for resource conflicts or permission issues with `argocd app get sre-demo-app -o yaml` and verify that ArgoCD has necessary RBAC permissions for the target namespace.

### Advanced Troubleshooting

**Debugging GitOps workflow failures**: Check GitHub Actions logs for build failures, review ArgoCD sync status for deployment issues, and verify webhook delivery for repository events.

**Investigating rollback loop scenarios**: Monitor rollback automation logs, check for conflicting automated processes, and verify that rollback targets are actually stable and healthy.

**Analyzing deployment performance issues**: Review deployment duration metrics, check resource availability during deployments, and analyze the impact of deployment frequency on service stability.

---

## Next Steps

You have successfully implemented production-ready CI/CD pipelines using GitOps principles with automated deployment validation and rollback capabilities. You've established ArgoCD for declarative deployment management, created safety gates using SLO metrics for deployment validation, implemented automated rollback systems based on monitoring data, and built comprehensive observability into your deployment pipeline.

**Proceed to [Exercise 7](../exercise7/)** where you will implement comprehensive production readiness including security hardening, cost optimization strategies, disaster recovery procedures, and compliance frameworks that build upon your reliable deployment infrastructure.

**Key Concepts to Remember**: GitOps provides declarative, auditable deployment management that reduces human error and improves reliability. SLO-based deployment validation ensures that deployments don't degrade user experience. Automated rollback systems minimize MTTR when issues occur. Comprehensive pipeline observability enables continuous improvement of deployment practices.

**Before Moving On**: Ensure you can explain how your GitOps implementation improves deployment reliability and reduces operational burden compared to manual deployment processes. In the next exercise, you'll add production readiness capabilities including security, disaster recovery, and compliance features to your complete platform.