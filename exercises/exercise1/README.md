# Exercise 1: Cloud Development Environment Setup

## Table of Contents
- [Introduction](#introduction)
- [Learning Objectives](#learning-objectives)
- [Prerequisites](#prerequisites)
- [Theory Foundation](#theory-foundation)
- [Navigate to Exercise Directory](#navigate-to-exercise-directory)
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

- Installation guide setup (../../installation.md)
- Visual Studio Code installed locally
- Git configured with your credentials
- GitHub account with Codespaces access
- Forked this repository to your GitHub account

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

**Cloud-First Development**:
Modern software teams develop entirely in cloud environments because it provides consistency, eliminates "works on my machine" problems, and scales instantly when you need more resources.

**SRE Application Design**:
Applications built with Site Reliability Engineering principles include monitoring, logging, and health checks from the first line of code, not as an afterthought.

**Structured Observability**:
Instead of basic print statements, production applications use structured logging and metrics that can be automatically collected and analyzed by monitoring systems.

---

## Navigate to Exercise Directory

Open your terminal and navigate to the exercise folder:

```bash
cd kubernetes-sre-cloud-native/exercises/exercise1
```

---

## Understanding the Application Structure

Before diving in, let's understand what has been prepared for you and why each component matters.

### Application Architecture Overview

Your exercise contains a complete Flask application with SRE best practices built in:

```
exercise1/
├── app/
│   ├── __init__.py      # Package initialization
│   ├── main.py          # Main application with SRE instrumentation  
│   └── config.py        # Configuration management
├── requirements.txt     # Python dependencies
└── README.md           # This guide
```

### Why This Structure Matters

**Separation of Concerns**: Configuration is separated from application logic, making it easier to deploy across different environments (development, staging, production).

**SRE Instrumentation**: The application includes Prometheus metrics, structured logging, and health endpoints that Kubernetes and monitoring systems expect.

**Production Readiness**: This isn't a "toy" application - it's structured like applications you'll work with in real SRE environments.

### Key Files and Their Purpose

**`app/main.py`** - The heart of your application containing:
- Flask web server with multiple endpoints
- Prometheus metrics collection for observability
- Structured logging for better troubleshooting
- Health check endpoints for Kubernetes deployment

**`app/config.py`** - Configuration management that:
- Handles different environments (development vs production)
- Manages settings through environment variables
- Provides sensible defaults for local development

**`requirements.txt`** - Dependency management specifying:
- Flask for the web framework
- Prometheus client for metrics collection
- Structured logging libraries for better observability

---

## Setting Up Your Cloud Development Environment

### Step 1: Launch GitHub Codespaces

1. **Navigate** to your forked repository on GitHub
2. **Click** the green "Code" button
3. **Select** the "Codespaces" tab
4. **Click** "Create codespace on main"
5. **Wait** 2-3 minutes for the environment to initialize

**What's happening**: GitHub is creating a complete Linux development environment in the cloud with Python, Docker, kubectl, and Google Cloud CLI pre-installed.

### Step 2: Install Required Cloud Tools

Once your Codespace loads, you need to install the cloud tools required for this course:

```bash
# Install Google Cloud CLI
curl -sSL https://sdk.cloud.google.com | bash
exec -l $SHELL  # Reload shell to update PATH

# Install kubectl (Kubernetes CLI)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl  # Clean up downloaded file
```

**What you're installing**:
- **Google Cloud CLI (gcloud)**: Command-line tools for managing Google Cloud Platform resources
- **kubectl**: Kubernetes command-line tool for managing cluster resources

### Step 3: Verify Your Development Environment

Verify that all required tools are installed and working:

```bash
# Check Python installation
python3 --version

# Check that we're in the right location
pwd
ls -la

# Verify cloud tools are available
docker --version
kubectl version --client
gcloud version
```

**Understanding the output**: You should see Python 3.11+, Docker, kubectl, and gcloud all installed and ready. This is your complete development environment - no local setup required.

**Why install these tools**: 
- **gcloud** will be used in later exercises to manage Google Kubernetes Engine clusters
- **kubectl** is essential for deploying and managing applications on Kubernetes
- **docker** is already available in Codespaces for container operations

---

## Exploring the SRE Application

### Step 4: Install Application Dependencies

```bash
# Navigate to the exercise directory
cd exercises/exercise1

# Install the required Python packages
pip install -r requirements.txt
```

**What you're installing**:
- **Flask**: Web framework for creating HTTP APIs
- **prometheus_client**: Library for exposing metrics that monitoring systems can collect
- **structlog**: Advanced logging library for better troubleshooting

### Step 5: Examine the Application Configuration

```bash
# Look at the application structure
tree app/

# Examine the dependencies
cat requirements.txt

# Check the configuration file (don't worry about understanding every line yet)
head -20 app/config.py
```

**Key insight**: Notice how the application is designed to work with environment variables. This allows the same code to run in development, testing, and production with different configurations.

---

## Running and Testing the Application

### Step 6: Start the Application

```bash
# Run the Flask application
python -m app.main
```

**What you should see**: Log messages showing the application starting, including the host (0.0.0.0) and port (8080). The application is now running and ready to accept requests.

**Understanding the logs**: Notice the structured format of the log messages. Each log entry contains structured information that monitoring systems can parse and analyze.

### Step 7: Test Application Endpoints

**Open a new terminal** (keep the application running in the first terminal) using `Ctrl+Shift+`` and test the different endpoints:

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

**What to observe**: 
- Each request generates structured log entries in your first terminal
- The health endpoint always returns success (liveness probe)
- The ready endpoint occasionally returns 503 (simulating real-world readiness checks)
- The stores endpoint sometimes returns errors (simulating real application behavior)

### Step 8: Access via Browser (GitHub Codespaces Magic)

GitHub Codespaces automatically detects your running application and offers browser access:

1. **Look for the notification** popup about port 8080 being available
2. **Click the globe icon** next to port 8080 in the Ports tab
3. **Test different endpoints** in your browser:
   - `/` - Home page  
   - `/stores` - Store data
   - `/health` - Health status

**Why this matters**: This port forwarding simulates how applications run in cloud environments and how you access them for testing.

---

## Understanding Observability in Action

### Step 9: Explore Application Metrics

```bash
# View the metrics endpoint (this is what Prometheus would collect)
curl http://localhost:8080/metrics
```

**What you're seeing**: Prometheus-formatted metrics including:
- HTTP request counts and durations
- Business operation metrics
- Application health indicators
- Custom metrics specific to your application

**Why this matters**: These metrics allow SRE teams to understand application performance, detect issues, and set up intelligent alerting before problems affect users.

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

**Key observations**:
- Watch the structured logs in your application terminal
- Notice how request counts increase in the metrics
- See how some requests might fail (this is intentional for learning)
- Observe how the application handles errors gracefully

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

**Understanding the difference**:
- **Health checks** (liveness probes): Tell Kubernetes if the application is alive
- **Readiness checks** (readiness probes): Tell Kubernetes if the application is ready to receive traffic
- Notice how readiness occasionally fails - this simulates real dependencies being unavailable

---

## Final Objective

By completing this exercise, you should be able to explain:

**Verification Checkboxes**:

- Application starts without errors and shows structured log output
- Home endpoint returns JSON with application information  
- Stores endpoint returns store data (may occasionally return 503 errors)
- Health endpoint always returns 200 status with health information
- Ready endpoint returns 200 status approximately 95% of the time
- Metrics endpoint returns Prometheus-formatted metrics data
- Browser access works through GitHub Codespaces port forwarding
- Load testing generates visible changes in metrics output

### Verification Questions

Test your understanding by answering these questions:

1. **What happens** if you change the LOG_LEVEL environment variable to DEBUG?
2. **Why does** the readiness endpoint sometimes return 503?
3. **What metrics** would help you detect if the application is getting overloaded?
4. **How would** you modify the application to run on port 8081 instead?

---

## Troubleshooting

### Common Issues

**"Address already in use" error**:
```bash
# Find and kill processes using port 8080
sudo lsof -ti:8080 | xargs sudo kill -9

# Or change the port
export PORT=8081
python -m app.main
```

**Import errors or missing packages**:
```bash
# Reinstall dependencies
pip install -r requirements.txt --force-reinstall

# Verify installation
pip list | grep -E "(flask|prometheus|structlog)"
```

**Codespaces not showing port forwarding**:
1. Check the Ports tab in the terminal panel
2. Make sure the application is running on 0.0.0.0 (not 127.0.0.1)
3. Try refreshing the browser or reopening the Codespace

**Application logs not showing**:
The application might be running in the background. Use `Ctrl+C` to stop it, then restart with `python -m app.main`.

---

## Next Steps

Congratulations! You have successfully:

- Set up a complete cloud development environment
- Explored a production-ready SRE application
- Understood the fundamentals of application observability
- Tested different endpoints and observed their behavior

**Proceed to [Exercise 2](../exercise2/)** where you will:

- Learn containerization concepts and Docker fundamentals
- Build your application into a container image using cloud-based builds
- Understand how containers enable consistent deployments across environments
- Prepare your application for Kubernetes deployment

**Key Concepts to Remember**:
- Observability must be built into applications from the beginning
- Cloud development environments provide consistency and eliminate local issues
- Health checks are essential for container orchestration platforms
- Structured logging and metrics enable proactive monitoring and faster troubleshooting

**Before Moving On**:
Make sure you can explain why each component (metrics, logging, health checks) is important for SRE work. In the next exercise, you'll package this observable application into containers for deployment.