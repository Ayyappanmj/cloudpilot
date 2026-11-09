# syntax=docker/dockerfile:1
# Build from the repository root:  docker build -f docker/Dockerfile -t cloudpilot-sample:local .

FROM python:3.11-slim-bookworm AS builder
ENV PIP_NO_CACHE_DIR=1 PIP_DISABLE_PIP_VERSION_CHECK=1
WORKDIR /build
COPY requirements.txt .
RUN pip install --prefix=/install -r requirements.txt

FROM python:3.11-slim-bookworm AS runtime
ARG APP_VERSION=0.1.0
ARG GIT_COMMIT=unknown
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    CLOUDPILOT_APP_VERSION=${APP_VERSION} \
    CLOUDPILOT_GIT_COMMIT=${GIT_COMMIT}
# Numeric UID/GID so Kubernetes can verify runAsNonRoot.
RUN groupadd --system --gid 10001 app \
 && useradd --system --uid 10001 --gid 10001 --no-create-home --shell /usr/sbin/nologin app
WORKDIR /srv
COPY --from=builder /install /usr/local
COPY app ./app
USER 10001:10001
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD ["python", "-c", "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/healthz', timeout=2).status == 200 else 1)"]
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--no-access-log"]
