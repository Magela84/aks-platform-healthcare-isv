# Placeholder PulseHealth service: appointments
# Replace with the real application. It only needs to serve "/" and
# "/health" on port 8080 for the Helm probes + pipeline test to pass.
import os
from flask import Flask

APP_NAME = os.environ.get("APP_NAME", "appointments")
app = Flask(__name__)

@app.route("/")
def index():
    return {"service": APP_NAME, "status": "running", "client": "PulseHealth Systems"}

@app.route("/health")
def health():
    return {"status": "healthy"}, 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
