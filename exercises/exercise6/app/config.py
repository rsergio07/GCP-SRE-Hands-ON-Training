import os
from typing import Dict, Any

class Config:
    """Application configuration class with GitOps deployment support."""
    
    # Flask settings
    FLASK_ENV = os.environ.get('FLASK_ENV', 'development')
    DEBUG = FLASK_ENV == 'development'
    
    # Application settings
    APP_NAME = os.environ.get('APP_NAME', 'sre-demo-app')
    APP_VERSION = os.environ.get('APP_VERSION', '1.2.0')
    
    # Server settings
    HOST = os.environ.get('HOST', '0.0.0.0')
    PORT = int(os.environ.get('PORT', 8080))
    
    # Logging configuration
    LOG_LEVEL = os.environ.get('LOG_LEVEL', 'INFO')
    LOG_FORMAT = 'json' if FLASK_ENV == 'production' else 'console'
    
    # GitOps specific configuration
    DEPLOYMENT_METHOD = os.environ.get('DEPLOYMENT_METHOD', 'gitops')
    GIT_COMMIT = os.environ.get('GIT_COMMIT', 'unknown')
    DEPLOYMENT_ID = os.environ.get('DEPLOYMENT_ID', 'manual')
    
    @classmethod
    def get_config_dict(cls) -> Dict[str, Any]:
        """Return configuration as dictionary for logging."""
        return {
            'app_name': cls.APP_NAME,
            'app_version': cls.APP_VERSION,
            'flask_env': cls.FLASK_ENV,
            'log_level': cls.LOG_LEVEL,
            'deployment_method': cls.DEPLOYMENT_METHOD,
            'git_commit': cls.GIT_COMMIT,
            'deployment_id': cls.DEPLOYMENT_ID
        }# GitOps deployment test - Mon Sep  8 15:27:35 UTC 2025
