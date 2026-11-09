"""Readiness state: ready after startup completes, not ready during shutdown."""

from app.config import Settings


class ReadinessState:
    def __init__(self) -> None:
        self.started = False

    def evaluate(self, settings: Settings) -> dict[str, bool]:
        return {
            "startup_complete": self.started,
            "not_forced_unready": not settings.simulate_not_ready,
        }
