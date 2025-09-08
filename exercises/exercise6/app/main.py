import time
import random
import structlog
from flask import Flask, jsonify, request
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
from app.config import Config

# Configure structured logging
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer() if Config.LOG_FORMAT == 'json'
        else structlog.dev.ConsoleRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()

# Initialize Flask application
app = Flask(__name__)
app.config.from_object(Config)

# Prometheus metrics for SRE monitoring
REQUEST_COUNT = Counter(
    'http_requests_total',
    'Total number of HTTP requests',
    ['method', 'endpoint', 'status_code']
)

REQUEST_DURATION = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration in seconds',
    ['method', 'endpoint']
)

ACTIVE_CONNECTIONS = Gauge(
    'active_connections_current',
    'Current number of active connections'
)

BUSINESS_METRICS = Counter(
    'business_operations_total',
    'Total business operations',
    ['operation_type', 'status']
)

APPLICATION_INFO = Gauge(
    'application_info',
    'Application information',
    ['app_name', 'version', 'environment', 'deployment_method']
)

# Deployment-specific metrics for GitOps monitoring
DEPLOYMENT_INFO = Gauge(
    'deployment_info',
    'Deployment information',
    ['deployment_id', 'git_commit', 'deployment_strategy']
)

# Set application info metric with GitOps information
APPLICATION_INFO.labels(
    app_name=Config.APP_NAME,
    version=Config.APP_VERSION,
    environment=Config.FLASK_ENV,
    deployment_method='gitops'
).set(1)

# Set deployment info (would be populated by CI/CD pipeline)
DEPLOYMENT_INFO.labels(
    deployment_id='gitops-' + str(int(time.time())),
    git_commit='latest',
    deployment_strategy='rolling'
).set(1)

# Sample business data
stores = [
    {
        "id": 1,
        "name": "Cloud SRE Store",
        "location": "us-central1",
        "items": [
            {"id": 1, "name": "Kubernetes Cluster", "price": 299.99, "stock": 5},
            {"id": 2, "name": "Prometheus Monitoring", "price": 49.99, "stock": 15},
            {"id": 3, "name": "GitOps Pipeline", "price": 199.99, "stock": 8}
        ]
    },
    {
        "id": 2,
        "name": "DevOps Essentials",
        "location": "europe-west1",
        "items": [
            {"id": 4, "name": "CI/CD Pipeline", "price": 199.99, "stock": 3},
            {"id": 5, "name": "Infrastructure as Code", "price": 149.99, "stock": 7},
            {"id": 6, "name": "ArgoCD Deployment", "price": 99.99, "stock": 12}
        ]
    }
]

@app.before_request
def before_request():
    """Log request start and update connection metrics."""
    ACTIVE_CONNECTIONS.inc()
    request.start_time = time.time()

    logger.info(
        "Request started",
        method=request.method,
        path=request.path,
        remote_addr=request.remote_addr,
        user_agent=request.user_agent.string[:100] if request.user_agent else None,
        deployment_method="gitops"
    )

@app.after_request
def after_request(response):
    """Log request completion and update metrics."""
    ACTIVE_CONNECTIONS.dec()

    duration = time.time() - request.start_time
    endpoint = request.endpoint or 'unknown'

    # Update Prometheus metrics
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=endpoint,
        status_code=response.status_code
    ).inc()

    REQUEST_DURATION.labels(
        method=request.method,
        endpoint=endpoint
    ).observe(duration)

    # Log request completion
    logger.info(
        "Request completed",
        method=request.method,
        endpoint=endpoint,
        status_code=response.status_code,
        duration_seconds=round(duration, 3),
        deployment_method="gitops"
    )

    return response

@app.route('/')
def home():
    """Home endpoint with GitOps deployment info."""
    BUSINESS_METRICS.labels(operation_type='health_check', status='success').inc()

    return jsonify({
        "message": f"Welcome to {Config.APP_NAME}!",
        "status": "healthy",
        "version": Config.APP_VERSION,
        "environment": Config.FLASK_ENV,
        "deployment_method": "GitOps with ArgoCD",
        "timestamp": time.time(),
        "features": [
            "Automated deployments",
            "SLO-based rollbacks",
            "Blue-green deployment ready",
            "Continuous monitoring"
        ]
    })

@app.route('/stores')
def get_stores():
    """Get all stores with simulated processing time and error rate."""

    # Simulate processing time
    processing_time = random.uniform(0.1, 0.8)
    time.sleep(processing_time)

    # Simulate occasional errors for SRE testing (5% error rate)
    if random.random() < 0.05:
        BUSINESS_METRICS.labels(operation_type='store_fetch', status='error').inc()
        logger.error(
            "Store service temporarily unavailable",
            processing_time=processing_time,
            error_type='service_unavailable',
            deployment_method="gitops"
        )
        return jsonify({
            "error": "Store service temporarily unavailable",
            "retry_after": 30,
            "deployment_info": {
                "method": "gitops",
                "version": Config.APP_VERSION
            }
        }), 503

    # Successful response
    BUSINESS_METRICS.labels(operation_type='store_fetch', status='success').inc()
    logger.info(
        "Stores retrieved successfully",
        store_count=len(stores),
        processing_time=processing_time,
        deployment_method="gitops"
    )

    return jsonify({
        "stores": stores,
        "total_stores": len(stores),
        "processing_time": round(processing_time, 3),
        "deployment_info": {
            "method": "gitops",
            "version": Config.APP_VERSION,
            "environment": Config.FLASK_ENV
        }
    })

@app.route('/stores/<int:store_id>')
def get_store(store_id):
    """Get specific store by ID."""

    store = next((s for s in stores if s['id'] == store_id), None)

    if not store:
        BUSINESS_METRICS.labels(operation_type='store_lookup', status='not_found').inc()
        logger.warning("Store not found", store_id=store_id, deployment_method="gitops")
        return jsonify({
            "error": f"Store {store_id} not found",
            "deployment_info": {
                "method": "gitops",
                "version": Config.APP_VERSION
            }
        }), 404

    BUSINESS_METRICS.labels(operation_type='store_lookup', status='success').inc()
    logger.info("Store retrieved", store_id=store_id, store_name=store['name'], deployment_method="gitops")

    return jsonify({
        **store,
        "deployment_info": {
            "method": "gitops",
            "version": Config.APP_VERSION,
            "environment": Config.FLASK_ENV
        }
    })

@app.route('/health')
def health():
    """Kubernetes liveness probe endpoint with deployment info."""

    # Perform basic health checks
    health_status = {
        "status": "healthy",
        "timestamp": time.time(),
        "version": Config.APP_VERSION,
        "deployment_method": "gitops",
        "checks": {
            "application": "ok",
            "memory": "ok",
            "disk": "ok",
            "gitops_sync": "ok"
        }
    }

    logger.info("Health check performed", **health_status)
    return jsonify(health_status)

@app.route('/ready')
def ready():
    """Kubernetes readiness probe endpoint with GitOps awareness."""

    # Simulate readiness checks (database connections, external services, etc.)
    is_ready = random.random() > 0.05  # 95% ready rate

    readiness_status = {
        "status": "ready" if is_ready else "not ready",
        "timestamp": time.time(),
        "deployment_method": "gitops",
        "checks": {
            "database": "ok" if is_ready else "connecting",
            "cache": "ok",
            "external_api": "ok" if is_ready else "timeout",
            "argocd_sync": "ok"
        }
    }

    status_code = 200 if is_ready else 503

    logger.info(
        "Readiness check performed",
        ready=is_ready,
        deployment_method="gitops",
        **readiness_status
    )

    return jsonify(readiness_status), status_code

@app.route('/metrics')
def metrics():
    """Prometheus metrics endpoint with GitOps deployment metrics."""
    logger.debug("Metrics endpoint accessed", deployment_method="gitops")
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

@app.route('/deployment')
def deployment_info():
    """Deployment information endpoint for GitOps visibility."""
    BUSINESS_METRICS.labels(operation_type='deployment_info', status='success').inc()

    deployment_data = {
        "deployment_method": "gitops",
        "version": Config.APP_VERSION,
        "environment": Config.FLASK_ENV,
        "app_name": Config.APP_NAME,
        "deployment_timestamp": time.time(),
        "features": {
            "automated_rollback": True,
            "slo_validation": True,
            "blue_green_ready": True,
            "monitoring_integration": True
        },
        "health": {
            "status": "healthy",
            "uptime_seconds": time.time() - (time.time() % 86400)  # Simplified uptime
        }
    }

    logger.info("Deployment info requested", **deployment_data)
    return jsonify(deployment_data)

@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors."""
    BUSINESS_METRICS.labels(operation_type='request', status='not_found').inc()
    logger.warning("Resource not found", path=request.path, deployment_method="gitops")
    return jsonify({
        "error": "Resource not found",
        "deployment_info": {
            "method": "gitops",
            "version": Config.APP_VERSION
        }
    }), 404

@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors."""
    BUSINESS_METRICS.labels(operation_type='request', status='server_error').inc()
    logger.error("Internal server error", error=str(error), deployment_method="gitops")
    return jsonify({
        "error": "Internal server error",
        "deployment_info": {
            "method": "gitops",
            "version": Config.APP_VERSION
        }
    }), 500

if __name__ == '__main__':
    # Log application startup
    logger.info(
        "Starting GitOps-deployed application",
        **Config.get_config_dict(),
        host=Config.HOST,
        port=Config.PORT,
        deployment_method="gitops"
    )

    # Run the Flask development server
    app.run(
        host=Config.HOST,
        port=Config.PORT,
        debug=Config.DEBUG
    )

