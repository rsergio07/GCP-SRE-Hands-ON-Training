# Kubernetes SRE Cloud-Native

**Production-Ready Site Reliability Engineering with Cloud-Native Kubernetes**

A comprehensive, hands-on course that transforms developers into production-ready Site Reliability Engineers through systematic implementation of enterprise-grade Kubernetes platforms. This course eliminates local environment complexity by using cloud-based development and deployment, making advanced SRE practices accessible to students regardless of hardware limitations while teaching modern enterprise workflows used by leading technology companies.

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

This course teaches Kubernetes through the comprehensive lens of **Site Reliability Engineering (SRE)**, using Google Cloud Platform and cloud-based development environments to build production-ready systems. Students develop a complete understanding of modern operational practices while constructing a **enterprise-grade monitoring and deployment platform** that demonstrates industry-standard reliability engineering principles.

### What You'll Build: A Complete SRE Platform

Your journey culminates in a comprehensive, production-ready platform that includes:

**Foundation and Observability:**
* **SRE-instrumented Python application** with Prometheus metrics, structured logging, and comprehensive health monitoring that provides complete visibility into application behavior and user experience
* **Production Kubernetes deployment** on Google Kubernetes Engine with intelligent autoscaling, resource management, and automated recovery capabilities that maintain availability under varying load conditions
* **Advanced observability stack** with monitoring, logging, alerting, and custom dashboards that enable data-driven operational decisions and proactive problem resolution

**Automation and Reliability:**
* **GitOps deployment automation** with ArgoCD providing declarative infrastructure management, automated synchronization, and complete audit trails for all configuration changes
* **Intelligent alerting systems** with SLO-based policies that focus on user impact rather than system symptoms, reducing noise while ensuring critical issues receive immediate attention
* **Chaos engineering validation** that proves system resilience through controlled failure injection and systematic testing of recovery procedures

**Production Readiness:**
* **Enterprise security hardening** with defense-in-depth strategies including network policies, pod security standards, RBAC controls, and comprehensive secret management
* **Cost optimization frameworks** with intelligent resource management, automated scaling policies, and financial governance that balance performance requirements with economic efficiency
* **Disaster recovery capabilities** with automated backup procedures, multi-region deployment strategies, and tested recovery processes that ensure business continuity

### Why This Approach Matters

**Industry Relevance**: This course teaches the same tools, practices, and operational patterns used by leading technology companies to manage production systems at scale. Students graduate with immediately applicable skills that align with current industry expectations for SRE roles.

**Production Focus**: Rather than simplified tutorial examples, every component is designed for actual production deployment with proper security controls, cost optimization, and operational procedures that scale with business growth and regulatory requirements.

**Cloud-Native Excellence**: By using cloud-based development and deployment from day one, students learn modern operational practices without the complexity and inconsistency of local development environments while gaining experience with enterprise-grade cloud platforms.

---

## Learning Objectives

By completing this comprehensive course, you will demonstrate the ability to:

**Foundation SRE Capabilities:**
1. **Deploy and operate production Kubernetes applications** with proper resource management, health monitoring, and automated scaling that maintains availability and performance under varying conditions
2. **Implement comprehensive observability** for distributed systems including metrics collection, structured logging, distributed tracing, and custom dashboards that provide actionable insights into system behavior
3. **Design and implement intelligent alerting strategies** that focus on user impact, prevent alert fatigue, and enable rapid incident response through SLO-based policies and escalation procedures

**Advanced Operational Excellence:**
4. **Build automated deployment pipelines** using GitOps principles that eliminate manual errors, provide complete audit trails, and enable rapid rollback capabilities for incident recovery
5. **Optimize costs and security** for cloud-native workloads through intelligent resource management, comprehensive security hardening, and governance frameworks that balance performance with economic efficiency
6. **Troubleshoot complex issues** in containerized environments using systematic approaches, comprehensive logging analysis, and performance optimization techniques that minimize mean time to resolution

**Enterprise Production Readiness:**
7. **Implement disaster recovery procedures** that ensure business continuity through automated backup systems, multi-region deployment strategies, and tested recovery processes that meet RTO and RPO requirements
8. **Validate system resilience** through chaos engineering experiments that prove recovery capabilities and identify weaknesses before they impact users in production environments
9. **Establish predictive operational practices** through capacity planning, performance optimization, and advanced monitoring that enable proactive problem prevention rather than reactive incident response

---

## Prerequisites

### Required Knowledge Foundation

**Technical Prerequisites:**
* **Web application fundamentals** including HTTP protocols, REST APIs, and basic understanding of client-server architecture that enables comprehension of distributed system concepts
* **Command-line proficiency** with basic terminal navigation, file manipulation, and command execution that supports hands-on exercises and troubleshooting procedures
* **Version control experience** with Git including basic commands, branching concepts, and collaborative workflows that enable effective use of GitOps deployment strategies

**SRE Conceptual Understanding:**
* **SRE fundamentals** including Service Level Indicators (SLIs), Service Level Objectives (SLOs), error budgets, and the basic principles of reliability engineering that guide operational decision-making
* **Basic systems thinking** including understanding of system dependencies, failure modes, and the importance of monitoring and alerting in maintaining service reliability

### Required Accounts and Access

**Cloud Platform Access:**
* **Google Cloud Platform account** with $300 free credits (sufficient for complete course completion with additional credits for continued learning and experimentation)
* **GitHub account** with access to Codespaces (free tier includes sufficient hours for course completion, with paid tiers available for extended learning)

**Optional but Recommended:**
* **Basic Docker familiarity** helpful but not required, as containerization concepts are taught within the course context
* **Previous cloud platform experience** beneficial but not essential, as cloud-specific concepts are introduced progressively throughout the exercises

---

## Getting Started

This course uses **GitHub Codespaces** for cloud-based development, providing a consistent, fully-configured environment that eliminates local setup complexity and ensures all students work with identical tooling and configurations.

### Quick Start Process

**Step 1: Environment Preparation**
1. **Create a Google Cloud Platform account** and activate the $300 free credits through the Google Cloud Console
2. **Fork this repository** to your GitHub account to track personal progress and enable GitOps workflows

**Step 2: Launch Cloud Development Environment**
1. **Open your forked repository** in GitHub and navigate to the Code tab
2. **Click "Create codespace on main"** to launch your cloud development environment
3. **Wait 2-3 minutes** for environment initialization including Python, Docker, and Kubernetes tools

**Step 3: Begin Learning Journey**
1. **Navigate to Exercise 1** directly within your Codespace environment
2. **Follow the comprehensive instructions** provided in each exercise README
3. **Complete verification steps** to ensure proper understanding before proceeding

The cloud environment comes pre-configured with all necessary tools including Python development environment, Docker container runtime, Kubernetes CLI tools, and Google Cloud SDK, enabling immediate focus on learning SRE concepts rather than environment configuration.

Detailed setup instructions with troubleshooting guidance are available in the [installation guide](installation.md).

---

## Course Structure

| Exercise | Title | Duration | Focus Area | Key Learning Outcomes |
|----------|-------|----------|------------|----------------------|
| [Exercise&nbsp;1](exercises/exercise1/) | Cloud Development Environment & SRE Application | 2 hours | GitHub Codespaces, Flask App, Basic Observability | Master cloud development workflows, implement SRE instrumentation, understand observability fundamentals |
| [Exercise&nbsp;2](exercises/exercise2/) | Container Builds & GitHub Actions | 2 hours | Docker, CI/CD Pipelines, Container Registry | Build production containers, implement automated testing, establish CI/CD foundations |
| [Exercise&nbsp;3](exercises/exercise3/) | Kubernetes Deployment | 2 hours | GKE, kubectl, Service Management, Autoscaling | Deploy to production Kubernetes, configure load balancing, implement autoscaling policies |
| [Exercise&nbsp;4](exercises/exercise4/) | Cloud Monitoring Stack | 2 hours | Prometheus, Cloud Monitoring, Custom Dashboards | Build comprehensive monitoring, create operational dashboards, establish observability practices |
| [Exercise&nbsp;5](exercises/exercise5/) | Alerting and Response | 1.5 hours | Alert Policies, SLOs, Incident Management | Implement intelligent alerting, define SLOs, establish incident response procedures |
| [Exercise&nbsp;6](exercises/exercise6/) | ArgoCD GitOps Deployment Management | 2 hours | GitOps, Automated Deployments, Rollback Procedures | Master GitOps workflows, automate deployments, implement rollback capabilities |
| [Exercise&nbsp;7](exercises/exercise7/) | Production Readiness | 2 hours | Security Hardening, Cost Optimization, Disaster Recovery | Achieve production readiness, implement security controls, establish disaster recovery |
| [Exercise&nbsp;8](exercises/exercise8/) | Advanced SRE Operations | 1.5 hours | Chaos Engineering, Performance Optimization, Predictive Operations | Validate system resilience, optimize performance, implement predictive operations |

**Total Investment**: ~16 hours of intensive, hands-on learning with immediate practical application

### Progressive Complexity Design

**Foundation Building (Exercises 1-2)**: Establishes cloud development workflows and containerization practices that form the basis for all subsequent work

**Core Platform (Exercises 3-4)**: Implements production Kubernetes deployment and comprehensive monitoring that provides operational visibility and control

**Operational Excellence (Exercises 5-6)**: Adds intelligent alerting and automated deployment workflows that enable reliable, efficient operations

**Production Maturity (Exercises 7-8)**: Achieves enterprise-grade security, optimization, and advanced operational practices that demonstrate complete SRE mastery

---

## Learning Path

### Flexible Scheduling Options

**Intensive Learning Track (2 weeks)**:
* **Week 1**: Exercises 1-4 (Foundation, Containerization, Kubernetes, Monitoring)
* **Week 2**: Exercises 5-8 (Alerting, GitOps, Production Readiness, Advanced Operations)

**Standard Learning Track (4 weeks)**:
* **Week 1**: Exercises 1-2 (Cloud development environment, container builds)
* **Week 2**: Exercises 3-4 (Kubernetes deployment, monitoring infrastructure)
* **Week 3**: Exercises 5-6 (Alerting systems, GitOps automation)
* **Week 4**: Exercises 7-8 (Production readiness, advanced operations)

**Extended Learning Track (8 weeks)**:
* **Weeks 1-2**: Exercises 1-2 with additional exploration and experimentation
* **Weeks 3-4**: Exercises 3-4 with deep-dive into Kubernetes concepts and monitoring patterns
* **Weeks 5-6**: Exercises 5-6 with comprehensive alerting design and GitOps best practices
* **Weeks 7-8**: Exercises 7-8 with advanced security, optimization, and chaos engineering

### Self-Paced Learning Support

Each exercise includes comprehensive verification questions, troubleshooting guidance, and extension activities that support different learning speeds and depths of exploration while maintaining consistent learning outcomes across all tracks.

---

## Key Technologies

### Development Environment
**Cloud-Native Development Platform**:
* **GitHub Codespaces** - Complete cloud-based VS Code environment with pre-configured tools and extensions
* **Google Cloud Shell** - Browser-based terminal with integrated cloud tools and persistent storage
* **Git and GitHub** - Version control and collaboration platform with CI/CD integration

### Application and Runtime Stack
**Production-Ready Application Framework**:
* **Python 3.11 + Flask** - Modern web framework with comprehensive ecosystem support
* **Prometheus client libraries** - Industry-standard metrics collection and exposition
* **Structured JSON logging** - Production-grade logging with automated parsing and analysis
* **Comprehensive health endpoints** - Kubernetes-native liveness and readiness probes

### Cloud Infrastructure Platform
**Google Cloud Platform Services**:
* **Google Kubernetes Engine (GKE) Autopilot** - Managed Kubernetes with automated operations and security
* **Google Artifact Registry** - Enterprise container registry with vulnerability scanning
* **Google Cloud Build** - Cloud-native CI/CD platform with integrated security scanning
* **Google Cloud Operations Suite** - Comprehensive monitoring, logging, and alerting platform

### Observability and Operations
**Enterprise-Grade Monitoring Stack**:
* **Prometheus** - Open-source metrics collection and time-series database
* **Grafana-compatible dashboards** - Comprehensive visualization and alerting interface
* **Google Cloud Monitoring** - Managed monitoring service with advanced analytics
* **ArgoCD** - GitOps continuous deployment with comprehensive audit trails
* **Litmus Chaos Engineering** - Kubernetes-native chaos engineering platform

### Advanced Operations Tools
**Production Readiness Platform**:
* **Network Policies** - Kubernetes-native network security and micro-segmentation
* **Pod Security Standards** - Container security controls and compliance frameworks
* **Horizontal Pod Autoscaler** - Intelligent scaling based on multiple metrics
* **Vertical Pod Autoscaler** - Automated resource optimization and right-sizing

---

## Cost Management

### Free Tier Utilization Strategy

This course is designed to operate entirely within Google Cloud Platform's generous free tier offerings:

**Compute Resources**:
* **GKE Autopilot**: Pay-per-pod pricing with automatic scaling to zero during inactivity
* **Cloud Build**: 120 free build minutes per day (sufficient for course exercises)
* **Codespaces**: GitHub provides substantial free hours for educational use

**Storage and Registry**:
* **Artifact Registry**: 0.5 GB free storage (adequate for course container images)
* **Cloud Storage**: 5 GB free storage for backups and configuration data
* **Persistent Disks**: Minimal usage through ephemeral configurations

**Monitoring and Operations**:
* **Cloud Monitoring**: Generous free tier covering course monitoring requirements
* **Cloud Logging**: Substantial free allotment for structured logging and analysis
* **Cloud Alerting**: Free notification policies and alert routing

### Post-Course Production Costs

**Estimated monthly costs for continued platform operation**:
* **Small production workload**: $30-50/month
* **Medium enterprise usage**: $100-200/month
* **Large-scale deployment**: $300-500/month

These estimates assume intelligent resource management and cost optimization practices taught throughout the course, making production deployment economically viable for organizations of all sizes.

### Cost Optimization Learning

The course teaches comprehensive cost optimization strategies including intelligent autoscaling policies, resource right-sizing based on actual usage, spot instance utilization for batch workloads, and monitoring-driven optimization that reduces costs while maintaining performance and reliability requirements.

---

## Course Philosophy

### Cloud-First Development Excellence
**Complete Cloud Integration**: All development, testing, and deployment occurs in cloud environments, eliminating local setup complexity while teaching modern operational practices used by enterprise organizations. This approach provides consistency across different operating systems and hardware configurations while introducing students to cloud-native development workflows from day one.

### SRE-Driven Learning Methodology
**Reliability as a Primary Concern**: Unlike traditional development courses that add operational considerations as an afterthought, this course integrates observability, reliability, and operational excellence from the first exercise. Students learn to think like Site Reliability Engineers, prioritizing user experience and system reliability throughout the development and deployment process.

### Production-Ready Practices Integration
**Enterprise-Grade Standards**: Every component is designed for actual production deployment with proper security controls, cost optimization, governance frameworks, and operational procedures. Students gain experience with the same tools, configurations, and practices used by leading technology companies to manage production systems at scale.

### Hands-On Learning Focus
**Minimal Theory, Maximum Implementation**: While foundational concepts are explained thoroughly, the primary learning mechanism is hands-on implementation with immediate feedback. Students build, deploy, monitor, and optimize real systems rather than studying abstract concepts, ensuring practical skills that transfer directly to production environments.

### Progressive Complexity Management
**Systematic Skill Building**: Each exercise builds systematically on previous knowledge while introducing new concepts at an appropriate pace. This approach ensures students develop deep understanding of fundamental concepts before tackling advanced topics, creating a solid foundation for continued learning and professional growth.

---

## Success Metrics

By successfully completing this course, you will have demonstrated the following measurable capabilities:

### Technical Implementation Skills
**Production Deployment Mastery**:
* Deploy and manage production-ready Kubernetes applications with proper resource management, security controls, and automated scaling policies
* Implement comprehensive observability including metrics collection, structured logging, distributed tracing, and custom dashboards that provide actionable operational insights
* Build and maintain automated CI/CD pipelines with GitOps principles that eliminate manual deployment errors while providing complete audit trails and rollback capabilities

### Operational Excellence Capabilities
**SRE Practice Implementation**:
* Design and implement intelligent alerting strategies based on SLOs that focus on user impact while preventing alert fatigue and enabling rapid incident response
* Establish and validate disaster recovery procedures that ensure business continuity through automated backup systems, multi-region deployment strategies, and tested recovery processes
* Optimize costs and security for cloud-native workloads through intelligent resource management, comprehensive security hardening, and governance frameworks that scale with business growth

### Advanced Problem-Solving Abilities
**Production Troubleshooting Expertise**:
* Troubleshoot complex issues in distributed containerized environments using systematic approaches, comprehensive logging analysis, and performance optimization techniques
* Implement chaos engineering practices that validate system resilience through controlled failure injection and systematic testing of recovery procedures
* Establish predictive operational practices through capacity planning, performance optimization, and advanced monitoring that enable proactive problem prevention

### Portfolio and Career Advancement
**Demonstrable Professional Value**:
* **Complete GitHub repository** showcasing production-ready SRE platform with comprehensive documentation and implementation examples
* **Practical experience** with enterprise-grade tools and practices that align with current industry expectations for SRE and DevOps roles
* **Systematic approach** to reliability engineering that demonstrates understanding of both technical implementation and business impact of operational decisions

### Verification and Assessment
**Comprehensive Skill Validation**:
Each exercise includes detailed verification questions that test synthesis and application rather than rote memorization, ensuring students can adapt their knowledge to new scenarios and business requirements while maintaining the operational excellence principles learned throughout the course.

---

## Community and Contributions

### Open Source Educational Excellence

This course represents a **community-driven initiative** to democratize access to enterprise-grade SRE education. We welcome contributions that enhance learning outcomes and expand accessibility:

**Course Content Enhancement**:
* **Clarity improvements** for exercise instructions, troubleshooting guides, and conceptual explanations
* **Additional scenarios** that demonstrate SRE practices in different industry contexts and use cases
* **Advanced extensions** for students who want to explore specialized topics or emerging technologies
* **Accessibility improvements** including alternative learning formats and accommodation for different learning styles

**Community Learning Support**:
* **Translation efforts** to make content accessible to global learners in multiple languages
* **Video walkthroughs** and supplementary content that support different learning preferences
* **Discussion facilitation** and peer support programs that enhance collaborative learning experiences
* **Industry perspective sharing** from practicing SRE professionals who can provide real-world context and career guidance

### Contribution Guidelines

**Getting Started with Contributions**:
* Review [CONTRIBUTING.md](CONTRIBUTING.md) for detailed contribution guidelines and coding standards
* Start with **documentation improvements** or **issue reporting** to become familiar with the project structure
* **Join discussions** on proposed enhancements to understand community priorities and coordination efforts
* **Test thoroughly** any suggested changes to ensure they enhance rather than complicate the learning experience

**Areas of Particular Need**:
* **Industry-specific examples** that demonstrate SRE practices in different business contexts
* **Advanced troubleshooting scenarios** based on real production incidents and resolution approaches
* **Integration guides** for emerging tools and platforms that complement the core curriculum
* **Assessment and evaluation tools** that help learners and instructors measure progress and competency

### Community Recognition

Contributors who make significant improvements to course content, learning accessibility, or community support will be recognized in course materials and project documentation, helping build professional portfolios while supporting educational excellence for future learners.

---

## Support

### Comprehensive Learning Assistance

**Technical Support Channels**:
* **GitHub Issues** - Exercise-specific technical problems, environment issues, and troubleshooting assistance with detailed problem description templates and triage procedures
* **GitHub Discussions** - General Q&A, concept clarification, peer learning support, and community knowledge sharing with organized categories for different topic areas
* **Real-time collaboration** - Synchronized problem-solving sessions and group learning opportunities for complex technical challenges

**Learning Resources**:
* **Comprehensive troubleshooting guides** included in each exercise with common issues, resolution steps, and prevention strategies
* **Video resources** and external learning materials curated for different learning styles and supplementary education
* **Industry best practices** documentation that connects course content to real-world professional requirements and career development

### Professional and Enterprise Support

**Individual Learners**:
* **Career guidance** connecting course completion to professional opportunities in SRE and cloud engineering roles
* **Portfolio development** assistance to showcase course projects effectively for job applications and professional advancement
* **Continued learning** pathways for specialization in advanced SRE topics and emerging technologies

**Organizations and Training Programs**:
For organizations interested in **customized training programs**, **enterprise deployments**, or **instructor-led workshops**, see the maintainer's profile for professional services and consulting opportunities that adapt course content to specific business requirements and organizational contexts.

---

## Acknowledgments

### Educational Foundation and Inspiration

This comprehensive course builds upon proven educational methodologies and industry best practices:

**Technical Foundation**:
* **Google SRE practices** and documented approaches from the foundational Site Reliability Engineering books and public documentation
* **CNCF ecosystem tools** and community best practices for cloud-native application development and operations
* **Industry expertise** from practicing Site Reliability Engineers at leading technology companies who have validated course content and approach

**Educational Methodology**:
* **SRE Academy** pedagogical approaches that emphasize hands-on learning and practical skill development
* **Cloud-native education** best practices that leverage modern development tools and cloud platforms for consistent learning experiences
* **Open source education** principles that prioritize accessibility, community collaboration, and continuous improvement

### Community and Industry Support

**Contributors and Reviewers**:
Recognition and appreciation for community members who have contributed content improvements, technical corrections, additional scenarios, and learning accessibility enhancements that benefit all future learners.

**Industry Professionals**:
Gratitude to Site Reliability Engineers, Platform Engineers, and DevOps professionals who have provided real-world context, career guidance, and practical insights that bridge the gap between academic learning and professional practice.

---

## License

This educational project is licensed under the **MIT License**, promoting open access to high-quality SRE education while enabling adaptation and improvement by the global learning community.

See [LICENSE.md](LICENSE.md) for complete licensing terms and conditions that support both individual learning and organizational training requirements.

---

## Ready to Transform Your Career?

**Begin your journey to SRE excellence** with [Exercise 1: Cloud Development Environment](exercises/exercise1/).

**Transform from developer to Site Reliability Engineer** through systematic implementation of production-ready platforms that demonstrate enterprise-grade operational capabilities and advance your professional career in cloud-native infrastructure and reliability engineering.

---

*Master the art and science of keeping production systems running reliably, efficiently, and cost-effectively while enabling rapid business growth through robust technical foundations.*

![Kubernetes SRE Cloud-Native](https://img.shields.io/badge/Kubernetes-SRE%20Cloud--Native-blue)