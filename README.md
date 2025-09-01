# Kubernetes SRE Cloud-Native

**Cloud-First Kubernetes Course for Site Reliability Engineers**

A comprehensive, hands-on course designed to teach Kubernetes and SRE practices using cloud-based development and deployment. Ideal for students with limited hardware resources or those who want to learn modern enterprise workflows.

---

## Table of Contents

* [Introduction](#introduction)
* [Learning Objectives](#learning-objectives)
* [Prerequisites](#prerequisites)
* [Getting Started](#getting-started)
* [Course Structure](#course-structure)
* [Learning Path](#learning-path)
* [Key Technologies](#key-technologies)
* [Cost Management](#cost-management)
* [Course Philosophy](#course-philosophy)
* [Success Metrics](#success-metrics)
* [Community and Contributions](#community-and-contributions)
* [Support](#support)
* [Acknowledgments](#acknowledgments)
* [License](#license)

---

## Introduction

This course teaches Kubernetes through the lens of **Site Reliability Engineering (SRE)**, using Google Cloud Platform (GCP) and cloud-based development tools. Students will build a **production-ready monitoring platform** without requiring local compute resources beyond VS Code and Git.

### What You’ll Build

* **SRE-instrumented Python application** with Prometheus metrics
* **Production Kubernetes deployment** on Google Kubernetes Engine (GKE)
* **Complete observability stack** with monitoring, logging, and alerting
* **Automated CI/CD pipeline** with GitHub Actions
* **Production-ready platform** with security, cost optimization, and disaster recovery

---

## Learning Objectives

By completing this course, you will be able to:

1. Deploy and operate production Kubernetes applications.
2. Implement observability for distributed systems.
3. Design and respond to effective alerting strategies.
4. Build automated deployment pipelines using GitOps.
5. Optimize costs and security for cloud-native workloads.
6. Troubleshoot complex issues in containerized environments.

---

## Prerequisites

* Basic understanding of web applications and HTTP.
* Familiarity with command-line interfaces.
* Knowledge of SRE fundamentals (SLIs, SLOs, error budgets).
* Google Cloud Platform account with \$300 free credits.
* GitHub account (free tier includes Codespaces hours).

---

## Getting Started

This course uses **GitHub Codespaces** for cloud-based development, eliminating local setup issues.

### Setup Requirements

1. **Create a Google Cloud Platform account** and claim the \$300 free credits.
2. **Fork this repository** to your GitHub account to track progress.

Once forked, you can start **Exercise 1** directly by launching a Codespace. The environment comes pre-configured with Python, Docker, and Kubernetes tools.

Detailed setup instructions are available in the [installation guide](installation.md).

---

## Course Structure

| Exercise | Title                                       | Duration | Focus Area                                  |
|----------|---------------------------------------------|----------|---------------------------------------------|
| [Exercise 1](exercises/exercise1/) | Cloud Development Environment & SRE Application | 120 min  | GitHub Codespaces, Flask App, Observability |
| [Exercise 2](exercises/exercise2/) | Container Builds & GitHub Actions               | 120 min  | Docker, CI/CD Pipelines, Container Registry |
| [Exercise 3](exercises/exercise3/) | Kubernetes Deployment                          | 120 min  | GKE, kubectl, Service Management            |
| [Exercise 4](exercises/exercise4/) | Cloud Monitoring Stack                         | 120 min  | Prometheus, Cloud Monitoring, Dashboards    |
| [Exercise 5](exercises/exercise5/) | Alerting and Response                          | 90 min   | Alert Policies, SLOs, Incident Management   |
| [Exercise 6](exercises/exercise6/) | Production CI/CD                               | 120 min  | GitOps, Automated Deployments, Rollbacks    |
| [Exercise 7](exercises/exercise7/) | Production Readiness                           | 120 min  | Security, Cost Optimization, DR             |
| [Exercise 8](exercises/exercise8/) | Advanced SRE Operations                        | 90 min   | Chaos Engineering, Performance Optimization |

**Total Duration**: ~16 hours of hands-on learning

---

## Learning Path

* **Weeks 1–2: Foundation** → Exercises 1–2 (cloud development, app build).
* **Weeks 3–4: Kubernetes Deployment & Monitoring** → Exercises 3–4 (GKE deployment, dashboards).
* **Weeks 5–6: Production Operations** → Exercises 5–6 (alerting, CI/CD pipelines).
* **Weeks 7–8: Production Readiness & Advanced Operations** → Exercises 7–8 (security, DR, chaos engineering).

---

## Key Technologies

**Development Environment**

* GitHub Codespaces (cloud-based VS Code)
* Google Cloud Shell (browser terminal)
* Git and GitHub

**Application Stack**

* Python 3.11 + Flask
* Prometheus client for metrics
* JSON structured logging
* Health check endpoints

**Cloud Infrastructure**

* Google Kubernetes Engine (GKE Autopilot)
* Google Container Registry
* Google Cloud Build
* Google Cloud Operations Suite

**Observability**

* Google Managed Prometheus
* Cloud Monitoring and Dashboards
* Cloud Logging and Analytics
* Cloud Alerting and Notifications

---

## Cost Management

This course fits within GCP’s free credit offering:

* **GKE Autopilot**: Pay-per-pod, scales to zero.
* **Cloud Build**: 120 free minutes/day.
* **Container Registry**: 0.5 GB free storage.
* **Monitoring & Logging**: generous free tier.

**Estimated costs after credits**: \$30–50/month for a production platform.

---

## Course Philosophy

* **Cloud-First Development**: All work happens in the cloud for consistency and scalability.
* **SRE-Driven Learning**: Reliability and observability are priorities from day one.
* **Production-Ready Practices**: Security, cost control, and maintainability are integral.
* **Hands-On Focus**: Minimal theory, maximum practical implementation.

---

## Success Metrics

By the end of this course, you will have demonstrated the ability to:

* Deploy production-ready Kubernetes apps.
* Integrate full observability with metrics, logs, and alerts.
* Build CI/CD pipelines with GitOps.
* Implement cost-aware and secure operations.
* Troubleshoot distributed systems in production.

---

## Community and Contributions

This course is **open-source and community-driven**. Contributions are welcome:

* Reporting unclear instructions or issues.
* Proposing improvements or new scenarios.
* Enhancing troubleshooting guides.
* Sharing useful video or reading resources.

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

---

## Support

* Use **GitHub Issues** for exercise-specific problems.
* Use the **Discussions tab** for general Q\&A and peer support.
* For organizations interested in **custom training**, see the maintainer’s profile.

---

## Acknowledgments

This course builds on the methodology of the [SRE Academy](https://github.com/rsergio07/SRE-Academy) and Google’s SRE practices.

---

## License

Licensed under the MIT License. See [LICENSE.md](LICENSE.md) for details.

---

**Ready to begin?** Start with [Exercise 1: Cloud Development Environment](exercises/exercise1/).

---
