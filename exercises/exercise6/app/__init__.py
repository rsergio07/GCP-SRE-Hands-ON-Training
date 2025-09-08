"""
SRE-Instrumented Flask Application with GitOps Support

A demonstration application that implements Site Reliability Engineering
best practices including structured logging, Prometheus metrics, proper
health check endpoints for Kubernetes deployment, and GitOps deployment
tracking for automated CI/CD workflows.

Version 1.2.0 adds GitOps deployment support with:
- Deployment tracking metrics
- Enhanced observability for CI/CD pipelines
- Rollback automation integration
- Blue-green deployment readiness
"""

__version__ = "1.2.0"
__author__ = "SRE Course"
__deployment_method__ = "GitOps"

