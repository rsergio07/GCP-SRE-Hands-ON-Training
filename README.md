# kubernetes-sre-cloud-native

**Cloud-First Kubernetes Course for Site Reliability Engineers**

A comprehensive, hands-on course designed to teach Kubernetes and SRE practices using entirely cloud-based development and deployment. Perfect for students with resource-constrained hardware or those wanting to learn modern enterprise development workflows.

## Course Overview

This course teaches Kubernetes through the lens of Site Reliability Engineering, using Google Cloud Platform and entirely cloud-based development tools. Students will build a complete, production-ready SRE monitoring platform without requiring any local compute resources beyond VS Code and Git.

### What You'll Build
- **SRE-instrumented Python application** with Prometheus metrics
- **Production Kubernetes deployment** on Google Kubernetes Engine
- **Complete observability stack** with monitoring, logging, and alerting
- **Automated CI/CD pipeline** using GitHub Actions
- **Production-ready platform** with security, cost optimization, and disaster recovery

### Prerequisites
- Basic understanding of web applications and HTTP
- Familiarity with command-line interfaces
- SRE fundamentals (SLIs, SLOs, error budgets)
- Google Cloud Platform account with $300 free credits
- GitHub account (free tier includes Codespaces hours)

## Getting Started

This course uses entirely cloud-based development through GitHub Codespaces, eliminating the need for local software installations or environment configuration.

### Prerequisites Setup
Before starting the exercises, you'll need to complete two simple setup steps. First, create a Google Cloud Platform account to claim your $300 free credits, which will cover all course exercises and provide hands-on experience with enterprise cloud infrastructure. Second, fork this repository to your GitHub account so you can work with your own copy of the course materials and track your progress.

### Course Access
Once you've forked the repository, you can immediately begin Exercise 1 by creating a GitHub Codespace directly from your fork. The Codespace will automatically provide a complete development environment with Python, Docker, and other necessary tools pre-configured. This cloud-first approach ensures consistency across all students while teaching modern enterprise development practices.

Complete setup instructions and detailed prerequisites are provided in the [installation guide](installation.md).

## Course Structure

| Exercise | Title | Duration | Focus Area |
|----------|-------|----------|------------|
| [Exercise 1](exercises/exercise1/) | Cloud Development Environment & SRE Application | 120 min | GitHub Codespaces, SRE Flask App, Observability |
| [Exercise 2](exercises/exercise2/) | Container Builds & GitHub Actions | 120 min | Docker, CI/CD Pipelines, Container Registry |
| [Exercise 3](exercises/exercise3/) | Kubernetes Deployment | 120 min | GKE, kubectl, Service Management |
| [Exercise 4](exercises/exercise4/) | Cloud Monitoring Stack | 120 min | Prometheus, Cloud Monitoring, Dashboards |
| [Exercise 5](exercises/exercise5/) | Alerting and Response | 90 min | Alert Policies, SLOs, Incident Management |
| [Exercise 6](exercises/exercise6/) | Production CI/CD | 120 min | GitOps, Automated Deployments, Rollbacks |
| [Exercise 7](exercises/exercise7/) | Production Readiness | 120 min | Security, Cost Optimization, DR |
| [Exercise 8](exercises/exercise8/) | Advanced SRE Operations | 90 min | Chaos Engineering, Performance Optimization |

**Total Course Duration**: 16+ hours of hands-on learning

## Learning Path

### Week 1-2: Foundation
Complete Exercises 1-2 to establish cloud development environment, build your SRE-instrumented application, and implement automated container builds.

### Week 3-4: Kubernetes Deployment & Monitoring
Complete Exercises 3-4 to deploy on Google Kubernetes Engine and implement comprehensive monitoring and dashboards.

### Week 5-6: Production Operations
Complete Exercises 5-6 to establish alerting strategies and automated deployment pipelines.

### Week 7-8: Production Readiness & Advanced Operations
Complete Exercises 7-8 to implement security, optimize costs, and learn advanced SRE techniques.

## Key Technologies

**Development Environment**:
- GitHub Codespaces (cloud-based VS Code)
- Google Cloud Shell (browser-based terminal)
- Git and GitHub (version control and collaboration)

**Application Stack**:
- Python 3.11 with Flask framework
- Prometheus client for metrics
- Structured logging with JSON output
- Health check endpoints for Kubernetes

**Cloud Infrastructure**:
- Google Kubernetes Engine (GKE Autopilot)
- Google Container Registry
- Google Cloud Build
- Google Cloud Operations Suite

**Observability**:
- Google Managed Prometheus
- Cloud Monitoring and Dashboards
- Cloud Logging and Log Analytics
- Cloud Alerting and Notification

## Cost Management

This course is designed to work within Google Cloud's $300 free credit offering:

- **GKE Autopilot**: Pay-per-pod, automatic scaling to zero
- **Cloud Build**: 120 free build minutes per day
- **Container Registry**: 0.5GB free storage
- **Monitoring and Logging**: Generous free tier limits

**Estimated costs after free credits**: $30-50/month for a production-ready platform.

## Course Philosophy

### Cloud-First Development
Every aspect of development, testing, and deployment happens in the cloud, teaching modern enterprise practices and eliminating local environment issues.

### SRE-Driven Learning
All exercises focus on reliability, observability, and operational excellence rather than just getting applications to work.

### Production-Ready Practices
Students learn security, cost optimization, and maintainability from the beginning, not as an afterthought.

### Hands-On Focus
Theory is delivered through curated video content, while course time focuses on practical implementation and problem-solving.

## Success Metrics

By completing this course, students will be able to:

- **Deploy and operate** production Kubernetes applications
- **Implement comprehensive observability** for distributed systems
- **Design and respond to** effective alerting strategies
- **Build automated deployment pipelines** using GitOps principles
- **Optimize costs and security** for cloud-native applications
- **Troubleshoot complex issues** in containerized environments

## Community and Contributions

This course is open-source and community-driven. The repository welcomes contributions from SRE practitioners and educators who want to improve the learning experience for future students. Whether you're reporting issues with unclear instructions, suggesting improvements to existing exercises, enhancing documentation with troubleshooting guides, or recommending better video resources for theory sections, your input helps make this course more effective.

## Support

Questions and technical issues can be addressed through GitHub Issues for problems specific to course content or exercise instructions. The Discussions tab provides a space for general questions, experience sharing, and community support among students and contributors. For organizations interested in corporate training or customized versions of this curriculum, contact information is available through the repository maintainer's profile.

## Acknowledgments

This course builds upon the proven methodology of the [SRE Academy](https://github.com/rsergio07/SRE-Academy) and incorporates Google's Site Reliability Engineering practices and cloud-native development patterns.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Community and Contributions

This course is open-source and community-driven. Contributions are welcome through:

- **Issue reporting for bugs or unclear instructions**
- **Exercise improvements and additional scenarios**
- **Documentation enhancements and troubleshooting guides**
- **Video recommendations for theory sections**

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed contribution guidelines.

---

**Ready to start your cloud-native SRE journey?** Begin with [Exercise 1: Cloud Development Environment](exercises/exercise1/).