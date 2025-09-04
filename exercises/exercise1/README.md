# Exercise 1: Cloud Development Environment Setup

## Table of Contents

* [Introduction](#introduction)
* [Learning Objectives](#learning-objectives)
* [Prerequisites](#prerequisites)
* [Theory Foundation](#theory-foundation)
* [Understanding the Application Structure](#understanding-the-application-structure)
* [Setting Up Your Cloud Development Environment](#setting-up-your-cloud-development-environment)
* [Exploring the SRE Application](#exploring-the-sre-application)
* [Running and Testing the Application](#running-and-testing-the-application)
* [Understanding Observability in Action](#understanding-observability-in-action)
* [Final Objective](#final-objective)
* [Troubleshooting](#troubleshooting)
* [Next Steps](#next-steps)

---

## Introduction

In this exercise, you will learn to set up and work in a complete cloud-based development environment using GitHub Codespaces. You'll explore a pre-built SRE-instrumented Flask application to understand how modern applications implement observability from day one.

This approach eliminates local environment complexity while teaching you the cloud-native development practices used in enterprise environments.

---

## Learning Objectives

By completing this exercise, you will understand:

* **Cloud Development Workflows**: How modern teams develop software entirely in cloud environments
* **SRE Application Patterns**: What makes an application "SRE-ready" from the beginning
* **Observability Fundamentals**: How metrics, logging, and health checks work together
* **Production-Ready Code Structure**: How to organize applications for reliability and maintainability

---

## Prerequisites

Before starting this exercise, ensure you have completed:

* [Installation Guide](../../installation.md)
* GitHub account with Codespaces access
* Forked this repository to your GitHub account

Note: No local software installation is required. Everything runs in the cloud.

---

## Theory Foundation

### Cloud Development Environments

**Essential Watching** (15 minutes):

* [Development with GitHub Codespaces](https://www.youtube.com/watch?v=UClpu3s1Ul4) by Betabit - Comprehensive Codespaces tutorial

**Reference Documentation**:

* [Official GitHub Codespaces Documentation](https://docs.github.com/en/codespaces) - Complete setup and usage guide

### SRE Observability Principles

**Essential Watching** (1 hour approx):

* [Site Reliability Engineering Playlist](https://www.youtube.com/playlist?list=PLIivdWyY5sqJrKl7D2u-gmis8h9K66qoj) by Google Cloud Tech - Official SRE concepts

**Reference Documentation**:

* [Google SRE Book - Monitoring Distributed Systems](https://sre.google/sre-book/monitoring-distributed-systems/) - Foundational monitoring principles
* [Google SRE Book - Service Level Objectives](https://sre.google/sre-book/service-level-objectives/) - SLO implementation guide

### Key Concepts You'll Learn

**Cloud-First Development** eliminates the inconsistencies that arise from different local development environments. Modern software teams develop entirely in cloud environments because it provides consistency, eliminates "works on my machine" problems, and scales instantly when you need more resources.

**SRE Application Design** principles require that applications include monitoring, logging, and health checks from the first line of code, not as an afterthought. This approach ensures that reliability engineering considerations are built into the application architecture from the beginning.

**Structured Observability** replaces basic print statements with structured logging and metrics that can be automatically collected and analyzed by monitoring systems. This enables proactive monitoring and faster troubleshooting in production environments.

---

## Understanding the Application Structure

In your Codespace, you'll find a complete Flask application with SRE best practices already implemented. Look at the `exercises/exercise1/` folder in the VS Code file explorer to see the application structure.

### Why Start Here?

Before we run any commands, it's crucial to understand the foundation of our application. The SRE mindset emphasizes that an application's design is key to its reliability. By exploring the code structure and key files first, you'll gain an appreciation for how observability (metrics, logging, health checks) is baked into the application from the very beginning. This is a core practice of building production-ready systems.

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

The **requirements.txt** file specifies all Python dependencies including Flask for the web framework, prometheus\_client for metrics collection, and structured logging libraries for better observability.

---

## Setting Up Your Cloud Development Environment

### Preparing Your Toolkit

The cloud development environment provides a clean slate, but to interact with cloud resources and manage future deployments, you need a set of essential tools. This section guides you through installing the **Google Cloud CLI (`gcloud`)** and the **Kubernetes CLI (`kubectl`)**. These tools are your command-line interface to the cloud, enabling you to manage infrastructure and deploy your application in later exercises.

### Step 1: Launch GitHub Codespaces

Navigate to your forked repository on GitHub and click the green "Code" button. Select the "Codespaces" tab and click "Create codespace on main". Wait 2-3 minutes for the environment to initialize.

GitHub is creating a complete Linux development environment in the cloud with Python and Docker pre-installed. This environment provides everything you need without any local configuration.

### Step 2: Install Required Cloud Tools

Once your Codespace loads, install the cloud tools required for this course:

```bash
# Install Google Cloud CLI
curl -sSL https://sdk.cloud.google.com | bash
```

```bash
# Reload shell to update PATH
exec -l $SHELL
```

```bash
# Install kubectl (Kubernetes CLI)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

```bash
# Clean up downloaded file
rm kubectl
```

You're installing the Google Cloud CLI (gcloud) for managing Google Cloud Platform resources and kubectl for managing Kubernetes cluster resources. These tools are essential for later exercises where you'll deploy applications to Google Kubernetes Engine.

### Step 3: Verify Your Development Environment

Verify that all required tools are installed and working:

```bash
# Check Python installation
python3 --version
```

```bash
# Check current location and repository structure
pwd
ls -la
```

```bash
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
```

```bash
# Install the required Python packages
pip install -r requirements.txt
```

You're installing Flask for creating HTTP APIs, prometheus\_client for exposing metrics that monitoring systems can collect, and structlog for advanced logging capabilities that provide better troubleshooting information.

### Step 5: Examine the Application Configuration

```bash
# Look at the application structure
ls -la app/
```

```bash
# Examine the dependencies
cat requirements.txt
```

```bash
# Check the configuration file structure
cat app/config.py
```

Notice how the application is designed to work with environment variables. This allows the same code to run in development, testing, and production with different configurations without code changes.

---

## Running and Testing the Application

### Step 6: Start the Application

### From Code to Action

You have now examined the application's structure and set up your environment. The next logical step is to bring the application to life. In the following steps, you will run the Flask application and use command-line tools like `curl` to interact with its various endpoints. This will give you your first hands-on experience with a running, observable application.

```bash
# Run the Flask application
python -m app.main
```

You should see log messages showing the application starting, including the host (0.0.0.0) and port (8080). The application is now running and ready to accept requests. Notice the structured format of the log messages where each entry contains structured information that monitoring systems can parse and analyze.

### Step 7: Test Application Endpoints

Open a new terminal (keep the application running in the first terminal) using `Ctrl+Shift+` and test the endpoints:

```bash
# Test the home endpoint (basic connectivity)
curl http://localhost:8080/
```

```bash
# Test the business logic endpoint (returns list of stores)
curl http://localhost:8080/stores
```

```bash
# Test a specific store
curl http://localhost:8080/stores/1
```

```bash
# Test health check (liveness probe for Kubernetes)
curl http://localhost:8080/health
```

```bash
# Test readiness check (readiness probe for Kubernetes)
curl http://localhost:8080/ready
```

**What you’ll see:**

* `/` → returns a welcome message with environment, version, and health status.
* `/stores` → simulates a real business endpoint, returning multiple stores with products, pricing, and stock levels.
* `/stores/1` → fetches details for a specific store, including items and inventory.
* `/health` → always returns `healthy`, simulating a **liveness probe** that Kubernetes uses to decide if a container should be restarted.
* `/ready` → returns ready when the application is prepared to serve traffic, simulating a readiness probe that Kubernetes uses to determine if a pod should receive requests.

**Why this matters:**

* These endpoints are not just for demo — they map directly to **SRE principles**:

  * Structured logging for observability.
  * Liveness and readiness probes for Kubernetes reliability.
  * Simulated failures in `/stores` and `/ready` to practice debugging and resilience testing.

### Understanding the Responses

**Reference Documentation**:

* [HTTP Status Codes](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)
* [Kubernetes Health Checks](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
* [REST API Basics](https://restfulapi.net/http-methods/)

### Step 8: Access via Browser

GitHub Codespaces automatically detects your running application and offers browser access. Look for the notification popup about port 8080 being available, then click the globe icon next to port 8080 in the Ports tab. Test different endpoints in your browser including the root path, /stores for store data, and /health for health status.

If the popup does not appear, open the **Ports** tab manually, look for port `8080`, and click the globe icon to open it in your browser.

---

## Understanding Observability in Action

### Seeing Observability in the Real World

In the theory section, you learned about the core SRE observability principles: metrics, logging, and health checks. Now, you will get a chance to see them in action. The following steps demonstrate how the pre-built instrumentation in the application captures critical data and signals that SRE teams rely on to monitor system health and troubleshoot issues in production.

### Step 9: Explore Application Metrics

```bash
# View the metrics endpoint (this is what Prometheus would collect)
curl http://localhost:8080/metrics
```

You will see a stream of **Prometheus-formatted metrics**, which SRE teams use for observability. These include:

* **Python runtime metrics** (garbage collection, memory, CPU usage)
* **Application request metrics** (counts, durations, error rates)
* **Custom business metrics** (operations such as store lookups)
* **Health and readiness probes**
* **Application metadata** (name, version, environment)

### Why This Matters

By exposing metrics in Prometheus format, the app integrates seamlessly with tools like **Prometheus, Grafana, and Alertmanager**.

* **SRE teams** can:

  * Track latency, throughput, and error rates.
  * Correlate infrastructure signals with business signals.
  * Set **SLOs and alerts** based on real user-facing behavior.

This is a hands-on example of **observability in action**: metrics connect code, infrastructure, and reliability practices.

### Step 10: Generate Load and Observe Behavior

Open a **new terminal window** (keep the app running in the first one). Then generate traffic to simulate real users:

```bash
# Generate multiple requests to see metrics change
for i in {1..20}; do
  curl -s http://localhost:8080/ > /dev/null
  curl -s http://localhost:8080/stores > /dev/null
  sleep 0.5
done
```

Now check how the metrics were updated:

```bash
# Check how metrics changed
curl http://localhost:8080/metrics | grep -E "(http_requests_total|business_operations)"
```

**What’s happening?**

* The loop sends 20 rounds of requests to `/` and `/stores`.
* Structured logs will show entries for each request.
* When you query `/metrics`, counters increase and some simulated failures appear.

Example output:

```text
http_requests_total{endpoint="home",status_code="200"} 36.0
http_requests_total{endpoint="get_stores",status_code="200"} 29.0
http_requests_total{endpoint="get_stores",status_code="503"} 5.0
business_operations_total{operation_type="store_fetch",status="success"} 29.0
business_operations_total{operation_type="store_fetch",status="error"} 5.0
```

This demonstrates how observability captures **success, error, and total operations**, which is exactly how SRE teams monitor reliability in production.

### Step 11: Understand Health Check Patterns

Open a **new terminal** and run the health and readiness checks multiple times.

```bash
# Test health checks multiple times
for i in {1..5}; do
  echo "Health check $i:"
  curl -s http://localhost:8080/health
  echo ""
done
```

Expected output:

```json
{
  "checks": { "application": "ok", "disk": "ok", "memory": "ok" },
  "status": "healthy",
  "version": "1.0.0"
}
```

Health checks (liveness probes) always return **healthy**. Kubernetes uses this to decide if a container is alive or should be restarted.

Now run the readiness checks:

```bash
# Test readiness checks multiple times  
for i in {1..10}; do
  echo "Readiness check $i:"
  curl -s http://localhost:8080/ready
  curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:8080/ready
  echo ""
done
```

Expected output:

```json
{
  "checks": { "cache": "ok", "database": "ok", "external_api": "ok" },
  "status": "ready"
}
Status: 200
```

Readiness checks always confirm whether the app is prepared to serve traffic. Kubernetes uses these signals to manage load balancing and routing effectively.

---

## Final Objective

By completing this exercise, you should be able to demonstrate:

The application starts without errors and shows structured log output. The home endpoint returns JSON with application information while the stores endpoint returns store data. The health endpoint always returns 200 status with health information, while the ready endpoint also returns 200 status, indicating readiness through the JSON body. The metrics endpoint returns Prometheus-formatted metrics data, browser access works through GitHub Codespaces port forwarding, and load testing generates visible changes in metrics output.

### Verification Questions

1. What happens if you change the `LOG_LEVEL` environment variable to DEBUG?
2. What specific role does the readiness endpoint play compared to the liveness endpoint in Kubernetes?
3. What metrics would help you detect if the application is getting overloaded?
4. How would you modify the application to run on port 8081 instead?

---

## Troubleshooting

### Common Issues

**"Address already in use" error**: Find and kill processes using port 8080 with `sudo lsof -ti:8080 | xargs sudo kill -9`, or change the port with `export PORT=8081` before running `python -m app.main`.

**Import errors or missing packages**: Reinstall dependencies with `pip install -r requirements.txt --force-reinstall` and verify installation with `pip list | grep -E "(flask|prometheus|structlog)"`.

**Codespaces not showing port forwarding**: Check the Ports tab in the terminal panel, make sure the application is running on 0.0.0.0 (not 127.0.0.1), or try refreshing the browser or reopening the Codespace.

**Application logs not showing**: The application might be running in the background. Use `Ctrl+C` to stop it, then restart with `python -m app.main`.

**Slow performance in Codespaces**: If pip installs are slow or Codespaces feels unresponsive, stop other apps on your machine or restart the Codespace for a clean environment.

---

## Next Steps

You have successfully set up a complete cloud development environment, explored a production-ready SRE application, understood the fundamentals of application observability, and tested different endpoints while observing their behavior.

**Proceed to [Exercise 2](../exercise2/)** where you will learn containerization concepts and Docker fundamentals, build your application into a container image using cloud-based builds, understand how containers enable consistent deployments across environments, and prepare your application for Kubernetes deployment.

**Key Concepts to Remember**: Observability must be built into applications from the beginning, cloud development environments provide consistency and eliminate local issues, health checks are essential for container orchestration platforms, and structured logging and metrics enable proactive monitoring and faster troubleshooting.

**Before Moving On**: Make sure you can explain why each component (metrics, logging, health checks) is important for SRE.
