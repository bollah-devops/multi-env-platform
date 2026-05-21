import os
from flask import Flask, jsonify

app = Flask(__name__)

ENV_NAME = os.getenv("ENV_NAME", "staging")
VERSION = os.getenv("VERSION", "1.0.0")


@app.route("/")
def home():
    return f"""
    <html>
        <body>
            <h1>Welcome </h1>
            <p>Environment: {ENV_NAME}</p>
        </body>
    </html>
    """


@app.route("/about")
def about():
    return "<h1>About Page</h1>"


@app.route("/api/status")
def status():
    return jsonify({"status": "ok", "environment": ENV_NAME, "version": VERSION})


@app.route("/health")
def health():
    return jsonify({"healthy": True, "environment": ENV_NAME})


if __name__ == "__main__":
    debug_mode = ENV_NAME != "production"
    app.run(host="0.0.0.0", port=5000, debug=debug_mode)
