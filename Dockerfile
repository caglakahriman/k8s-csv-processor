FROM python:3.13-slim

# Environment configuration
ENV FLASK_APP=app.py \
    FLASK_ENV=production \
    PYTHONPATH=/app \
    AWS_DEFAULT_REGION=us-east-1

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    awscli \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app
COPY src/ .

RUN pip install --no-cache-dir -r requirements.txt

# Expose Flask port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# Start app
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
