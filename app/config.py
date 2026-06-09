import os


class Config:
    SECRET_KEY = os.environ.get("FLASK_SECRET_KEY", "change-me-in-production")
    DEBUG = os.environ.get("FLASK_ENV") == "development"
    PORT = int(os.environ.get("PORT", 5000))
    API_KEY = os.environ.get("API_KEY")


class TestingConfig(Config):
    TESTING = True
    DEBUG = False
