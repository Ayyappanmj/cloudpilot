"""Records Prometheus request metrics for every request except /metrics itself."""

import time

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

from app.metrics import IN_PROGRESS, KNOWN_METHODS, LATENCY, REQUESTS


def _endpoint(request: Request) -> str:
    route = request.scope.get("route")
    return getattr(route, "path", "unmatched")


class MetricsMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        if request.url.path == "/metrics":
            return await call_next(request)
        method = request.method if request.method in KNOWN_METHODS else "OTHER"
        IN_PROGRESS.labels(method).inc()
        start = time.perf_counter()
        status = 500
        try:
            response = await call_next(request)
            status = response.status_code
            return response
        finally:
            endpoint = _endpoint(request)
            LATENCY.labels(method, endpoint).observe(time.perf_counter() - start)
            REQUESTS.labels(method, endpoint, str(status)).inc()
            IN_PROGRESS.labels(method).dec()
