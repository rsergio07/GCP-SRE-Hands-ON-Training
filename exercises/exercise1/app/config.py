import os
from typing import Dict, Any

class Config:
    """Application configuration class."""
    
    # Flask settings
    FLASK_ENV = os.environ.get('FLASK_ENV', 'development')
    DEBUG = FLASK_ENV == 'development'
    
    # Application settings
    APP_NAME = os.environ.get('APP_NAME', 'sre-demo-app')
    APP_VERSION = os.environ.get('APP_VERSION', '1.0.0')
    
    # Server settings
    HOST = os.environ.get('HOST', '0.0.0.0')
    PORT = int(os.environ.get('PORT', 8080))
    
    # Logging configuration
    LOG_LEVEL = os.environ.get('LOG_LEVEL', 'INFO')
    LOG_FORMAT = 'json' if FLASK_ENV == 'production' else 'console'
    
    @classmethod
    def get_config_dict(cls) -> Dict[str, Any]:
        """Return configuration as dictionary for logging."""
        return {
            'app_name': cls.APP_NAME,
            'app_version': cls.APP_VERSION,
            'flask_env': cls.FLASK_ENV,
            'log_level': cls.LOG_LEVEL
        }