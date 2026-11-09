"""Guard rails for the monitoring-demo endpoints."""

from app.config import Settings
from app.exceptions import AppError

MAX_CONCURRENT_SLOW = 20
_inflight = 0


def require_enabled(settings: Settings) -> None:
    if not settings.enable_fault_injection:
        raise AppError(403, "fault_injection_disabled", "Fault injection is disabled.")


class SlowSlot:
    """Async context manager limiting concurrent slow requests (prevents resource exhaustion)."""

    async def __aenter__(self):
        global _inflight
        if _inflight >= MAX_CONCURRENT_SLOW:
            raise AppError(429, "too_many_slow_requests", "Too many concurrent slow requests.")
        _inflight += 1

    async def __aexit__(self, *exc):
        global _inflight
        _inflight -= 1
