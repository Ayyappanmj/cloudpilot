"""Application factory."""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.config import get_settings
from app.exceptions import register_exception_handlers
from app.logging_config import configure_logging
from app.metrics import APP_INFO
from app.middleware.correlation import CorrelationIdMiddleware
from app.middleware.metrics import MetricsMiddleware
from app.routers import api, core
from app.services.readiness import ReadinessState


def create_app() -> FastAPI:
    settings = get_settings()
    configure_logging(settings.log_level)

    @asynccontextmanager
    async def lifespan(app: FastAPI):
        APP_INFO.clear()
        APP_INFO.labels(settings.app_version, settings.environment, settings.git_commit).set(1)
        app.state.readiness.started = True
        logging.getLogger("cloudpilot").info(
            "application started",
            extra={"extra_fields": {"version": settings.app_version, "env": settings.environment}},
        )
        yield
        app.state.readiness.started = False

    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description="Sample service deployed by the CloudPilot CI/CD + GitOps platform.",
        lifespan=lifespan,
    )
    app.state.readiness = ReadinessState()
    # Last added = outermost. Correlation wraps metrics so every request has an ID.
    app.add_middleware(MetricsMiddleware)
    app.add_middleware(CorrelationIdMiddleware)
    register_exception_handlers(app)
    app.include_router(core.router)
    app.include_router(api.router)
    return app


app = create_app()
