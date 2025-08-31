# Production-hardened multi-stage build
FROM python:3.11-slim as builder

# Security: Run as non-root during build
RUN groupadd -r builduser && useradd -r -g builduser builduser

# Install only necessary build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libc6-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

WORKDIR /build
USER builduser

# Copy and install Python dependencies
COPY --chown=builduser:builduser requirements.txt .
RUN pip install --user --no-warn-script-location --no-cache-dir -r requirements.txt

# Production stage - distroless for minimal attack surface
FROM gcr.io/distroless/python3-debian11:latest

# Security labels for container scanning
LABEL security.hardened="true" \
      security.scan="required" \
      maintainer="sre-team@company.com" \
      version="1.3.0-production"

# Production environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    FLASK_ENV=production \
    LOG_FORMAT=json \
    PORT=8080 \
    APP_VERSION=1.3.0 \
    SECURITY_HARDENED=true

# Create application directory
WORKDIR /app

# Copy Python packages from builder
COPY --from=builder /home/builduser/.local /home/appuser/.local

# Copy application with correct ownership
COPY --chown=1001:1001 app/ ./app/
COPY --chown=1001:1001 requirements.txt .

# Use non-root user (distroless nonroot user)
USER 1001

# Set PATH for user-installed packages
ENV PATH=/home/appuser/.local/bin:$PATH

# Security: Expose only necessary port
EXPOSE 8080

# Health check for container orchestration
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')"

# Run application with security context
CMD ["python", "-m", "app.main"]