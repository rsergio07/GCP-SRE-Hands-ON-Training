# Exercise 1: Cloud Development Environment Setup

## Table of Contents
- [Introduction](#introduction)
- [Learning Objectives](#learning-objectives)
- [Prerequisites](#prerequisites)
- [Theory Foundation](#theory-foundation)
- [Understanding the Application Structure](#understanding-the-application-structure)
- [Setting Up Your Cloud Development Environment](#setting-up-your-cloud-development-environment)
- [Exploring the SRE Application](#exploring-the-sre-application)
- [Running and Testing the Application](#running-and-testing-the-application)
- [Understanding Observability in Action](#understanding-observability-in-action)
- [Final Objective](#final-objective)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)

---

## Introduction

In this exercise, you will learn to set up and work in a complete cloud-based development environment using GitHub Codespaces. You'll explore a pre-built SRE-instrumented Flask application to understand how modern applications implement observability from day one.

This approach eliminates local environment complexity while teaching you the cloud-native development practices used in enterprise environments.

---

## Learning Objectives

By completing this exercise, you will understand:

- **Cloud Development Workflows**: How modern teams develop software entirely in cloud environments
- **SRE Application Patterns**: What makes an application "SRE-ready" from the beginning
- **Observability Fundamentals**: How metrics, logging, and health checks work together
- **Production-Ready Code Structure**: How to organize applications for reliability and maintainability

---

## Prerequisites

Before starting this exercise, ensure you have completed:

- [Installation Guide](../../installation.md)
- GitHub account with Codespaces access
- Forked this repository to your GitHub account

Note: No local software installation is required. Everything runs in the cloud.

---

## Theory Foundation

### Cloud Development Environments

**Essential Watching** (15 minutes):
- [Development with GitHub Codespaces](https://www.youtube.com/watch?v=UClpu3s1Ul4) by Betabit - Comprehensive Codespaces tutorial

**Reference Documentation**:
- [Official GitHub Codespaces Documentation](https://docs.github.com/en/codespaces) - Complete setup and usage guide

### SRE Observability Principles

**Essential Watching** (15 minutes - Select 2-3 videos from playlist):
- [Site Reliability Engineering Playlist](https://www.youtube.com/playlist?list=PLIivdWyY5sqJrKl7D2u-gmis8h9K66qoj) by Google Cloud Tech - Official SRE concepts

**Recommended videos from the playlist**:
- "What is Site Reliability Engineering (SRE)?"
- "SRE fundamentals: SLIs, SLAs and SLOs"
- "How to monitor your applications"

**Reference Documentation**:
- [Google SRE Book - Monitoring Distributed Systems](https://sre.google/sre-book/monitoring-distributed-systems/) - Foundational monitoring principles
- [Google SRE Book - Service Level Objectives](https://sre.google/sre-book/service-level-objectives/) - SLO implementation guide

### Key Concepts You'll Learn

**Cloud-First Development** eliminates the inconsistencies that arise from different local development environments. Modern software teams develop entirely in cloud environments because it provides consistency, eliminates "works on my machine" problems, and scales instantly when you need more resources.

**SRE Application Design** principles require that applications include monitoring, logging, and health checks from the first line of code, not as an afterthought. This approach ensures that reliability engineering considerations are built into the application architecture from the beginning.

**Structured Observability** replaces basic print statements with structured logging and metrics that can be automatically collected and analyzed by monitoring systems. This enables proactive monitoring and faster troubleshooting in production environments.

---

## Understanding the Application Structure

In your Codespace, you'll find a complete Flask application with SRE best practices already implemented. Look at the `exercises/exercise1/` folder in the VS Code file explorer to see the application structure.

### Application Architecture Overview

The exercise contains a complete Flask application structured for production use:

```
exercise1/
├── app/
│   ├── __init__.py      # Package initialization
│   ├── main.py          # Main application with SRE instrumentation  
│   └── config.py        # Configuration management
├── requirements.txt     # Python dependencies
└── README.md            # This guide
```

### Why This Structure Matters

**Separation of Concerns** ensures that configuration is separated from application logic, making it easier to deploy the same code across different environments such as development, staging, and production without modification.

**SRE Instrumentation** is built into the application architecture. The application includes Prometheus metrics, structured logging, and health endpoints that Kubernetes and monitoring systems expect in production deployments.

**Production Readiness** means this isn't a simplified tutorial application. It's structured like applications you'll encounter in real SRE environments, with proper error handling, configuration management, and observability patterns.

### Key Files and Their Purpose

The **main.py** file contains the heart of your application including the Flask web server with multiple endpoints, Prometheus metrics collection for observability, structured logging for better troubleshooting, and health check endpoints required for Kubernetes deployment.

The **config.py** file handles configuration management across different environments. It manages settings through environment variables and provides sensible defaults for local development while allowing production overrides.

The **requirements.txt** file specifies all Python dependencies including Flask for the web framework, prometheus_client for metrics collection, and structured logging libraries for better observability.

---

## Setting Up Your Cloud Development Environment

### Step 1: Launch GitHub Codespaces

Navigate to your forked repository on GitHub and click the green "Code" button. Select the "Codespaces" tab and click "Create codespace on main". Wait 2-3 minutes for the environment to initialize.

GitHub is creating a complete Linux development environment in the cloud with Python and Docker pre-installed. This environment provides everything you need without any local configuration.

### Step 2: Install Required Cloud Tools

Once your Codespace loads, install the cloud tools required for this course:

```bash
# Install Google Cloud CLI
curl -sSL https://sdk.cloud.google.com | bash
exec -l $SHELL  # Reload shell to update PATH

# Install kubectl (Kubernetes CLI)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl  # Clean up downloaded file
```

You're installing the Google Cloud CLI (gcloud) for managing Google Cloud Platform resources and kubectl for managing Kubernetes cluster resources. These tools are essential for later exercises where you'll deploy applications to Google Kubernetes Engine.

### Step 3: Verify Your Development Environment

Verify that all required tools are installed and working:

```bash
# Check Python installation
python3 --version

# Check current location and repository structure
pwd
ls -la

# Verify cloud tools are available
docker --version
kubectl version --client
gcloud version
```

You should see Python 3.11+, Docker, kubectl, and gcloud all installed and ready. This represents your complete development environment with no local setup required.

---

## Exploring the SRE Application

### Step 4: Navigate to Exercise Directory and Install Dependencies

```bash
# Navigate to the exercise directory
cd exercises/exercise1

# Install the required Python packages
pip install -r requirements.txt
```

You're installing Flask for creating HTTP APIs, prometheus_client for exposing metrics that monitoring systems can collect, and structlog for advanced logging capabilities that provide better troubleshooting information.

### Step 5: Examine the Application Configuration

```bash
# Look at the application structure
ls -la app/

# Examine the dependencies
cat requirements.txt

# Check the configuration file structure
head -20 app/config.py
```

Notice how the application is designed to work with environment variables. This allows the same code to run in development, testing, and production with different configurations without code changes.

---

## Running and Testing the Application

### Step 6: Start the Application

```bash
# Run the Flask application
python -m app.main
```

You should see log messages showing the application starting, including the host (0.0.0.0) and port (8080). The application is now running and ready to accept requests. Notice the structured format of the log messages where each entry contains structured information that monitoring systems can parse and analyze.

### Step 7: Test Application Endpoints

Open a new terminal (keep the application running in the first terminal) using `Ctrl+Shift+` and test the different endpoints:

```bash
# Test the home endpoint
curl http://localhost:8080/

# Test the business logic endpoint
curl http://localhost:8080/stores

# Test a specific store
curl http://localhost:8080/stores/1

# Test health check (important for Kubernetes)
curl http://localhost:8080/health

# Test readiness check (also important for Kubernetes)
curl http://localhost:8080/ready
```

Observe that each request generates structured log entries in your first terminal. The health endpoint always returns success (liveness probe), while the ready endpoint occasionally returns 503 status (simulating real-world readiness checks). The stores endpoint sometimes returns errors, which simulates real application behavior and provides learning opportunities.

### Understanding the Responses

**Reference Documentation**:
- [HTTP Status Codes](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status) - Understanding 200, 503, and other response codes
- [Kubernetes Health Checks](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) - Official documentation on liveness and readiness probes
- [REST API Basics](https://restfulapi.net/http-methods/) - Understanding GET requests and API design patterns

### Step 8: Access via Browser

GitHub Codespaces automatically detects your running application and offers browser access. Look for the notification popup about port 8080 being available, then click the globe icon next to port 8080 in the Ports tab. Test different endpoints in your browser including the root path, /stores for store data, and /health for health status.

This port forwarding simulates how applications run in cloud environments and demonstrates how you access them for testing and monitoring purposes.

---

## Understanding Observability in Action

### Step 9: Explore Application Metrics

```bash
# View the metrics endpoint (this is what Prometheus would collect)
curl http://localhost:8080/metrics
```

You're seeing Prometheus-formatted metrics including HTTP request counts and durations, business operation metrics, application health indicators, and custom metrics specific to your application. These metrics allow SRE teams to understand application performance, detect issues, and set up intelligent alerting before problems affect users.

### Step 10: Generate Load and Observe Behavior

Create some traffic to see the observability in action:

```bash
# Generate multiple requests to see metrics change
for i in {1..20}; do
  curl -s http://localhost:8080/ > /dev/null
  curl -s http://localhost:8080/stores > /dev/null
  sleep 0.5
done

# Check how metrics changed
curl http://localhost:8080/metrics | grep -E "(http_requests_total|business_operations)"
```

Watch the structured logs in your application terminal and notice how request counts increase in the metrics. Some requests might fail intentionally for learning purposes, and observe how the application handles errors gracefully while maintaining observability.

### Step 11: Understand Health Check Patterns

```bash
# Test health checks multiple times
for i in {1..5}; do
  echo "Health check $i:"
  curl -s http://localhost:8080/health | head -1
  echo ""
done

# Test readiness checks multiple times  
for i in {1..10}; do
  echo "Readiness check $i:"
  curl -s -w "Status: %{http_code}\n" http://localhost:8080/ready | head -1
  echo ""
done
```

Health checks (liveness probes) tell Kubernetes if the application is alive and should be restarted if failing. Readiness checks (readiness probes) tell Kubernetes if the application is ready to receive traffic and should be removed from load balancing if not ready. Notice how readiness occasionally fails, which simulates real dependencies being unavailable.

---

## Final Objective

By completing this exercise, you should be able to demonstrate:

The application starts without errors and shows structured log output. The home endpoint returns JSON with application information while the stores endpoint returns store data but may occasionally return 503 errors as designed. The health endpoint always returns 200 status with health information, while the ready endpoint returns 200 status approximately 95% of the time. The metrics endpoint returns Prometheus-formatted metrics data, browser access works through GitHub Codespaces port forwarding, and load testing generates visible changes in metrics output.

### Verification Questions

Test your understanding by answering these questions:

1. **What happens** if you change the LOG_LEVEL environment variable to DEBUG?
2. **Why does** the readiness endpoint sometimes return 503?
3. **What metrics** would help you detect if the application is getting overloaded?
4. **How would** you modify the application to run on port 8081 instead?

---

## Troubleshooting

### Common Issues

**"Address already in use" error**: Find and kill processes using port 8080 with `sudo lsof -ti:8080 | xargs sudo kill -9`, or change the port with `export PORT=8081` before running `python -m app.main`.

**Import errors or missing packages**: Reinstall dependencies with `pip install -r requirements.txt --force-reinstall` and verify installation with `pip list | grep -E "(flask|prometheus|structlog)"`.

**Codespaces not showing port forwarding**: Check the Ports tab in the terminal panel, make sure the application is running on 0.0.0.0 (not 127.0.0.1), or try refreshing the browser or reopening the Codespace.

**Application logs not showing**: The application might be running in the background. Use `Ctrl+C` to stop it, then restart with `python -m app.main`.

---

## Next Steps

You have successfully set up a complete cloud development environment, explored a production-ready SRE application, understood the fundamentals of application observability, and tested different endpoints while observing their behavior.

**Proceed to [Exercise 2](../exercise2/)** where you will learn containerization concepts and Docker fundamentals, build your application into a container image using cloud-based builds, understand how containers enable consistent deployments across environments, and prepare your application for Kubernetes deployment.

**Key Concepts to Remember**: Observability must be built into applications from the beginning, cloud development environments provide consistency and eliminate local issues, health checks are essential for container orchestration platforms, and structured logging and metrics enable proactive monitoring and faster troubleshooting.

**Before Moving On**: Make sure you can explain why each component (metrics, logging, health checks) is important for SRE work. In the next exercise, you'll package this observable application into containers for deployment.