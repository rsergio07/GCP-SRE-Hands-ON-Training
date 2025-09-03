import os


class Config:
    """Base configuration class with common settings."""
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key'

    HOST = os.environ.get('HOST') or '0.0.0.0'

    PORT = int(os.environ.get('PORT', 8080))

    DEBUG = os.environ.get('FLASK_DEBUG', 'False').lower() == 'true'

    ENVIRONMENT = os.environ.get('ENVIRONMENT', 'production')

    LOG_LEVEL = os.environ.get('LOG_LEVEL', 'INFO').upper()

    # Database configuration (for future exercises)
    DATABASE_URL = os.environ.get('DATABASE_URL')

    # Metrics configuration
    METRICS_PORT = int(os.environ.get('METRICS_PORT', 8080))

    # Health check configuration
    HEALTH_CHECK_PATH = os.environ.get('HEALTH_CHECK_PATH', '/health')
