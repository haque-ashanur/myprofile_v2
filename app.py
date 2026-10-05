from datetime import datetime
from time import perf_counter
from flask import Flask, g, render_template, request
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Gauge, Histogram, generate_latest

app = Flask(__name__)

APP_VERSION = "2.0.0"

HTTP_REQUESTS = Counter(
    "myprofile_http_requests_total",
    "Total HTTP requests handled by MyProfile",
    ["method", "status"],
)
HTTP_DURATION = Histogram(
    "myprofile_http_request_duration_seconds",
    "HTTP request duration in seconds",
    ["method"],
)
APP_INFO = Gauge(
    "myprofile_app_info",
    "MyProfile application information",
    ["version"],
)
APP_INFO.labels(version=APP_VERSION).set(1)

PROFILE = {
    "name": "Ashanur Haque",
    "short_name": "Ashanur",
    "title": "DevOps Engineer | Cloud & Automation",
    "summary": (
        "DevOps-focused IT professional building cloud-ready, containerized and automated solutions "
        "with AWS, GitHub Actions, Docker, Kubernetes, Terraform and observability tooling."
    ),
    "location": "India",
    "email": "your-email@example.com",
    "github": "https://github.com/haque-ashanur",
    "linkedin": "https://www.linkedin.com/",
}

SKILLS = [
    {"category": "Cloud", "items": "AWS • EC2 • CloudWatch"},
    {"category": "DevOps", "items": "Git • GitHub • GitHub Actions"},
    {"category": "Containers", "items": "Docker • Docker Hub"},
    {"category": "Kubernetes", "items": "Kubernetes • K3s • Helm"},
    {"category": "IaC", "items": "Terraform"},
    {"category": "Observability", "items": "Prometheus • Grafana"},
    {"category": "Programming", "items": "Python • Flask • Bash"},
    {"category": "Operations", "items": "Linux • Monitoring • CI/CD"},
    {"category": "Automation", "items": "Deployment • Health checks • Scripting"},
]

PROJECTS = [
    {
        "name": "Momentum-King Trading Bot",
        "tag": "DevOps + Automation",
        "description": (
            "Python trading automation platform containerized and prepared for cloud deployment, "
            "with CI/CD and Kubernetes-oriented operations."
        ),
        "stack": "Python • Streamlit • GitHub Actions • Docker • K3s • AWS • Terraform • Prometheus • Grafana",
    },
    {
        "name": "MyProfile Platform",
        "tag": "This Website",
        "description": (
            "A production-style portfolio demonstrating source control, automated testing, "
            "container delivery, Kubernetes deployment and observability."
        ),
        "stack": "Python • Flask • Git • GitHub Actions • Docker • Docker Hub • K3s • Prometheus • Grafana • CloudWatch",
    },
]

PIPELINE = [
    ("01", "Code", "Git"),
    ("02", "Source", "GitHub"),
    ("03", "CI/CD", "Actions"),
    ("04", "Image", "Docker"),
    ("05", "Registry", "Docker Hub"),
    ("06", "Runtime", "K3s / AWS"),
    ("07", "Observe", "Prometheus + Grafana"),
    ("08", "Cloud Ops", "CloudWatch"),
]

@app.before_request
def start_timer():
    g.request_start = perf_counter()

@app.after_request
def record_metrics(response):
    if request.path != "/metrics":
        duration = perf_counter() - g.get("request_start", perf_counter())
        HTTP_REQUESTS.labels(request.method, str(response.status_code)).inc()
        HTTP_DURATION.labels(request.method).observe(duration)
    return response

@app.route("/")
def home():
    return render_template(
        "index.html",
        profile=PROFILE,
        skills=SKILLS,
        projects=PROJECTS,
        pipeline=PIPELINE,
        app_version=APP_VERSION,
        current_year=datetime.now().year,
    )

@app.get("/health")
def health():
    return {"status": "healthy", "version": APP_VERSION}

@app.get("/metrics")
def metrics():
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
