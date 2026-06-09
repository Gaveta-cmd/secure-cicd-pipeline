from flask import Flask, jsonify
from .config import Config


def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    from .routes import main
    app.register_blueprint(main)

    @app.errorhandler(400)
    @app.errorhandler(404)
    @app.errorhandler(405)
    def handle_error(error):
        return jsonify({"error": str(error.description)}), error.code

    return app
