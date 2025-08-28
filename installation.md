# Installation Guide: Cloud Environment Setup

This guide will help you set up your complete cloud-based development and deployment environment. No local installations beyond VS Code and Git are required.

## Table of Contents
- [Local Windows Setup](#local-windows-setup)
- [Google Cloud Platform Setup](#google-cloud-platform-setup)
- [GitHub Account Configuration](#github-account-configuration)
- [Verification Steps](#verification-steps)
- [Troubleshooting](#troubleshooting)
- [Cost Management](#cost-management)

---

## Local Windows Setup

### Required Software (5 minutes)

#### 1. Visual Studio Code
- **Download**: [https://code.visualstudio.com/](https://code.visualstudio.com/)
- **Installation**: Run the installer with default settings
- **Recommended Extensions** (will be auto-installed in Codespaces):
  - Python
  - Kubernetes
  - YAML
  - Docker

#### 2. Git for Windows
- **Download**: [https://git-scm.com/download/win](https://git-scm.com/download/win)
- **Installation**: Use recommended settings
- **Configure Git**:
  ```bash
  git config --global user.name "Your Name"
  git config --global user.email "your.email@example.com"
  ```

### Verification
```bash
# Check installations
code --version
git --version
```

---

## Google Cloud Platform Setup

### 1. Create Google Cloud Account (10 minutes)

#### Sign Up Process
1. **Visit**: [https://cloud.google.com/](https://cloud.google.com/)
2. **Click**: "Get started for free"
3. **Complete** account verification (requires credit card for verification, not charged)
4. **Claim** $300 free credits (valid for 90 days)

#### Enable Billing Account
- **Navigate**: Cloud Console → Billing
- **Verify**: Free trial credits are active
- **Set up**: Billing alerts at $50, $100, $200 thresholds

### 2. Create Your First Project (5 minutes)

#### Via Cloud Console
1. **Navigate**: [https://console.cloud.google.com/](https://console.cloud.google.com/)
2. **Click**: "Select a project" → "New Project"
3. **Enter**: Project Name: `joshua-k8s-sre`
4. **Click**: "Create"

#### Via Cloud Shell
Access Cloud Shell (terminal icon in top right) and run:
```bash
# Create project
gcloud projects create joshua-k8s-sre-$(date +%s) \
  --name="Joshua K8s SRE Project"

# List projects to get exact project ID
gcloud projects list

# Set as default project
gcloud config set project YOUR_PROJECT_ID
```

### 3. Enable Required APIs (5 minutes)

#### Required Services
```bash
# Enable all required APIs
gcloud services enable \
  container.googleapis.com \
  cloudbuild.googleapis.com \
  containerregistry.googleapis.com \
  monitoring.googleapis.com \
  logging.googleapis.com \
  compute.googleapis.com
```

#### Verification
```bash
# Check enabled services
gcloud services list --enabled
```

### 4. Set Up Authentication (5 minutes)

#### Create Service Account for GitHub Actions
```bash
# Create service account
gcloud iam service-accounts create github-actions \
  --display-name="GitHub Actions Service Account"

# Grant necessary permissions
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
  --member="serviceAccount:github-actions@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com" \
  --role="roles/container.developer"

gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
  --member="serviceAccount:github-actions@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com" \
  --role="roles/cloudbuild.builds.builder"

# Create and download key
gcloud iam service-accounts keys create ~/github-actions-key.json \
  --iam-account=github-actions@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
```

---

## GitHub Account Configuration

### 1. GitHub Account Setup (5 minutes)

#### Create or Verify Account
- **Visit**: [https://github.com](https://github.com)
- **Sign up** or **sign in** to existing account
- **Verify** email address

#### GitHub Codespaces Entitlement
- **Free tier includes**: 120 core hours per month
- **Sufficient for**: Course completion and ongoing development
- **Upgrade available**: If additional hours needed

### 2. Fork Course Repository (2 minutes)

#### Repository Setup
1. **Navigate**: [https://github.com/rsergio07/kubernetes-sre-cloud-native](https://github.com/rsergio07/kubernetes-sre-cloud-native)
2. **Click**: "Fork" button (top right)
3. **Select**: Your personal account
4. **Wait**: For fork creation (30 seconds)

#### Clone Locally (Optional)
```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/kubernetes-sre-cloud-native.git
cd kubernetes-sre-cloud-native

# Add upstream remote
git remote add upstream https://github.com/rsergio07/kubernetes-sre-cloud-native.git
```

### 3. Configure GitHub Secrets (5 minutes)

#### Add GCP Credentials to GitHub
1. **Navigate**: Your forked repository → Settings → Secrets and variables → Actions
2. **Add** the following secrets:

| Secret Name | Value |
|-------------|--------|
| `GCP_PROJECT` | Your project ID (e.g., `joshua-k8s-sre-123456`) |
| `GCP_SA_KEY` | Contents of `github-actions-key.json` file |

#### Get Service Account Key Content
```bash
# Display key content for copying
cat ~/github-actions-key.json
```

---

## Verification Steps

### 1. Test Cloud Shell Access
1. **Open**: [https://console.cloud.google.com/](https://console.cloud.google.com/)
2. **Click**: Cloud Shell icon (terminal)
3. **Run**: Basic commands
   ```bash
   gcloud config get-value project
   kubectl version --client
   git --version
   python3 --version
   ```

### 2. Test GitHub Codespaces
1. **Navigate**: Your forked repository
2. **Click**: "Code" → "Codespaces" → "Create codespace on main"
3. **Wait**: 2-3 minutes for environment setup
4. **Verify**: Python, Docker, kubectl are available
   ```bash
   python3 --version
   docker --version
   kubectl version --client
   ```

### 3. Test GKE Access
```bash
# In Cloud Shell, create a test cluster
gcloud container clusters create-auto test-cluster \
  --location=us-central1 \
  --async

# Check cluster creation status
gcloud container clusters list
```

**Note**: Delete the test cluster after verification to avoid charges:
```bash
gcloud container clusters delete test-cluster --location=us-central1
```

---

## Troubleshooting

### Common Issues

#### "Project ID not found"
**Solution**:
```bash
gcloud projects list
gcloud config set project CORRECT_PROJECT_ID
```

#### "API not enabled" errors
**Solution**:
```bash
gcloud services enable REQUIRED_API.googleapis.com
```

#### Codespaces won't start
**Possible causes**:
- Insufficient GitHub Codespaces hours
- Repository not properly forked
- Internet connectivity issues

**Solutions**:
- Check Codespaces usage: Settings → Billing → Codespaces
- Re-fork repository
- Try different browser/network

#### Cloud Shell timeout
**Solution**: Cloud Shell sessions timeout after inactivity. Simply reopen and reconnect.

### Resource Limits

#### Free Tier Limitations
- **GKE**: No free tier for cluster management fee ($0.10/hour)
- **Compute**: 1 f1-micro instance free per month
- **Storage**: 30GB-months HDD free
- **Build Minutes**: 120 minutes per day free

#### Monitoring Usage
```bash
# Check current usage
gcloud billing budgets list
gcloud logging usage list
```

---

## Cost Management

### Setting Up Cost Alerts

#### Budget Creation
1. **Navigate**: Cloud Console → Billing → Budgets & alerts
2. **Create budget**: Set to $50, $100, $200
3. **Configure alerts**: Email notifications at 50%, 90%, 100%

#### Cost Optimization Commands
```bash
# List all resources
gcloud asset search-all-resources --scope=projects/$GOOGLE_CLOUD_PROJECT

# Stop all compute instances
gcloud compute instances stop --all

# Delete unused resources
gcloud container clusters list
gcloud compute disks list --filter="status:READY AND -users:*"
```

### Resource Cleanup Automation

#### Daily Cleanup Script
```bash
#!/bin/bash
# scripts/cleanup.sh

# Stop development clusters after hours
gcloud container clusters resize dev-cluster --num-nodes=0 --zone=us-central1

# Clean up old container images
gcloud container images list-tags gcr.io/$GOOGLE_CLOUD_PROJECT/app \
  --limit=10 --sort-by=~timestamp --format='value(digest)' | \
  tail -n +4 | xargs -I {} gcloud container images delete gcr.io/$GOOGLE_CLOUD_PROJECT/app@{} --quiet
```

### Free Credit Tracking

#### Monitor Usage
- **Dashboard**: Cloud Console → Billing → Overview
- **Alerts**: Set up at 25%, 50%, 75% of credit usage
- **Forecasting**: Use billing reports to predict consumption

---

## Next Steps

With your environment properly configured:

1. **Verify all systems** using the verification steps above
2. **Proceed to Exercise 1**: [Cloud Development Environment](exercises/exercise1/)
3. **Join the community**: Star the repository and watch for updates
4. **Set up cost monitoring**: Enable billing alerts before starting

## Security Notes

- **Never commit** service account keys to Git repositories
- **Use environment variables** for sensitive information
- **Enable two-factor authentication** on Google Cloud and GitHub accounts
- **Review permissions** regularly and apply principle of least privilege

---

**Environment setup complete!** You're now ready to begin your cloud-native Kubernetes SRE journey.