import json
import logging
import time
import structlog

# Configure structlog for compatibility
structlog.configure()
import random
from datetime import datetime
from flask import Flask, jsonify, request
from prometheus_client import (
    Counter, Histogram, Gauge, generate_latest,
    CollectorRegistry, CONTENT_TYPE_LATEST
)
import psutil
from .config import Config

# Create Flask application with configuration
app = Flask(__name__)
app.config.from_object(Config)

# Configure structured logging
logging.basicConfig(
    level=getattr(logging, app.config['LOG_LEVEL']),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize Prometheus metrics
registry = CollectorRegistry()
REQUEST_COUNT = Counter(
    'http_requests_total',
    'Total number of HTTP requests',
    ['method', 'endpoint', 'status'],
    registry=registry
)

REQUEST_DURATION = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration in seconds',
    ['method', 'endpoint'],
    registry=registry
)

ACTIVE_CONNECTIONS = Gauge(
    'http_active_connections',
    'Number of active HTTP connections',
    registry=registry
)

SYSTEM_CPU_USAGE = Gauge(
    'system_cpu_usage_percent',
    'Current CPU usage percentage',
    registry=registry
)

SYSTEM_MEMORY_USAGE = Gauge(
    'system_memory_usage_bytes',
    'Current memory usage in bytes',
    registry=registry
)

APPLICATION_INFO = Gauge(
    'application_info',
    'Application information',
    ['version', 'environment'],
    registry=registry
)

# Set application info metric
APPLICATION_INFO.labels(
    version=app.config.get('VERSION', '1.0.0'),
    environment=app.config['ENVIRONMENT']
).set(1)


def log_request_info():
    """Log structured request information."""
    log_data = {
        'timestamp': datetime.utcnow().isoformat(),
        'method': request.method,
        'path': request.path,
        'remote_addr': request.remote_addr,
        'user_agent': request.headers.get('User-Agent', 'Unknown')
    }
    logger.info(f"Request: {json.dumps(log_data)}")


def update_system_metrics():
    """Update system-level metrics."""
    try:
        SYSTEM_CPU_USAGE.set(psutil.cpu_percent())
        SYSTEM_MEMORY_USAGE.set(psutil.virtual_memory().used)
    except Exception as e:
        logger.warning(f"Failed to update system metrics: {e}")


@app.before_request
def before_request():
    """Execute before each request."""
    log_request_info()
    update_system_metrics()
    request.start_time = time.time()
    ACTIVE_CONNECTIONS.inc()


@app.after_request
def after_request(response):
    """Execute after each request."""
    ACTIVE_CONNECTIONS.dec()

    # Record metrics
    duration = time.time() - request.start_time
    REQUEST_DURATION.labels(
        method=request.method,
        endpoint=request.endpoint or 'unknown'
    ).observe(duration)

    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.endpoint or 'unknown',
        status=response.status_code
    ).inc()

    # Log response info
    log_data = {
        'timestamp': datetime.utcnow().isoformat(),
        'method': request.method,
        'path': request.path,
        'status_code': response.status_code,
        'duration_ms': round(duration * 1000, 2)
    }
    logger.info(f"Response: {json.dumps(log_data)}")

    return response


@app.route('/')
def index():
    """Main application endpoint."""
    return jsonify({
        'message': 'Welcome to sre-demo-app!',
        'version': '1.0.0',
        'environment': app.config['ENVIRONMENT'],
        'status': 'healthy',
        'timestamp': time.time()
    })


@app.route('/stores')
def get_stores():
    """Get list of stores with simulated processing time."""
    start_time = time.time()

    # Simulate database query with random delay
    processing_delay = random.uniform(0.1, 0.5)
    time.sleep(processing_delay)

    stores_data = [
        {
            'id': 1,
            'name': 'Cloud SRE Store',
            'location': 'us-central1',
            'items': [
                {
                    'id': 1,
                    'name': 'Kubernetes Cluster',
                    'price': 299.99,
                    'stock': 5
                },
                {
                    'id': 2,
                    'name': 'Prometheus Monitoring',
                    'price': 149.99,
                    'stock': 12
                }
            ]
        },
        {
            'id': 2,
            'name': 'DevOps Marketplace',
            'location': 'us-east1',
            'items': [
                {
                    'id': 3,
                    'name': 'CI/CD Pipeline',
                    'price': 199.99,
                    'stock': 8
                },
                {
                    'id': 4,
                    'name': 'Container Registry',
                    'price': 99.99,
                    'stock': 15
                }
            ]
        }
    ]

    processing_time = time.time() - start_time

    return jsonify({
        'stores': stores_data,
        'total_stores': len(stores_data),
        'processing_time': round(processing_time, 3)
    })


@app.route('/health')
@app.route("/ready")
def ready_check():
    """Readiness probe endpoint for Kubernetes."""
    return jsonify({
        "status": "ready",
        "timestamp": time.time()
    })


def health_check():
    """Health check endpoint for container orchestration."""
    health_status = {
        'status': 'healthy',
        'timestamp': time.time(),
        'version': '1.0.0',
        'checks': {}
    }

    # Check application status
    try:
        health_status['checks']['application'] = 'ok'
    except Exception as e:
        health_status['checks']['application'] = f'error: {str(e)}'
        health_status['status'] = 'unhealthy'

    # Check memory usage
    try:
        memory = psutil.virtual_memory()
        if memory.percent < 90:
            health_status['checks']['memory'] = 'ok'
        else:
            health_status['checks']['memory'] = f'high: {memory.percent}%'
            health_status['status'] = 'degraded'
    except Exception as e:
        health_status['checks']['memory'] = f'error: {str(e)}'

    # Check disk usage
    try:
        disk = psutil.disk_usage('/')
        if disk.percent < 90:
            health_status['checks']['disk'] = 'ok'
        else:
            health_status['checks']['disk'] = f'high: {disk.percent}%'
            health_status['status'] = 'degraded'
    except Exception as e:
        health_status['checks']['disk'] = f'error: {str(e)}'

    status_code = 200
    if health_status['status'] == 'unhealthy':
        status_code = 503
    elif health_status['status'] == 'degraded':
        status_code = 200

    return jsonify(health_status), status_code


@app.route('/metrics')
def metrics():
    """Prometheus metrics endpoint."""
    return generate_latest(registry), 200, {'Content-Type': CONTENT_TYPE_LATEST}


@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors with JSON response."""
    return jsonify({
        'error': 'Not Found',
        'message': 'The requested resource was not found',
        'status_code': 404,
        'timestamp': time.time()
    }), 404


@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors with JSON response."""
    logger.error(f"Internal server error: {error}")
    return jsonify({
        'error': 'Internal Server Error',
        'message': 'An unexpected error occurred',
        'status_code': 500,
        'timestamp': time.time()
    }), 500


def main():
    """Main application entry point."""
    logger.info(
        f"Starting SRE Demo Application on "
        f"{app.config['HOST']}:{app.config['PORT']}"
    )
    logger.info(f"Environment: {app.config['ENVIRONMENT']}")
    logger.info(f"Debug mode: {app.config['DEBUG']}")

    app.run(
        host=app.config['HOST'],
        port=app.config['PORT'],
        debug=app.config['DEBUG']
    )


if __name__ == '__main__':
    main()
