FROM python:3.12-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Create a fixed non-root UID/GID.
RUN addgroup --system --gid 10001 appgroup \
    && adduser --system --uid 10001 --gid 10001 appuser

# Install Python dependencies
COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY app.py .
COPY templates ./templates
COPY static ./static

# Give application user ownership
RUN chown -R 10001:10001 /app

# IMPORTANT:
# Use numeric UID/GID so Kubernetes can verify this is non-root.
USER 10001:10001

EXPOSE 5000

# Docker-level health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:5000/health')"

# Production WSGI server
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:app"]