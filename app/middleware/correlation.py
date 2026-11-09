"""Request correlation ID + one structured access-log line per request."""

import logging
import re
import time
import uuid

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

from app.logging_config import request_id_ctx

HEADER = "X-Request-ID"
_SAFE_ID = re.compile(r"^[A-Za-z0-9._-]{1,64}$")  # rejects anything that could forge log lines
logger = logging.getLogger("cloudpilot.access")


class CorrelationIdMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        incoming = request.headers.get(HEADER, "")
        request_id = incoming if _SAFE_ID.match(incoming) else uuid.uuid4().hex
        request.state.request_id = request_id
        request_id_ctx.set(request_id)
        start = time.perf_counter()
        status = 500
        try:
            response = await call_next(request)
            status = response.status_code
            response.headers[HEADER] = request_id
            return response
        finally:
            if request.url.path not in ("/healthz", "/readyz", "/metrics"):
                logger.info(
                    "request completed",
                    extra={
                        "extra_fields": {
                            "method": request.method,
                            "path": request.url.path,
                            "status": status,
                            "duration_ms": round((time.perf_counter() - start) * 1000, 2),
                        }
                    },
                )
