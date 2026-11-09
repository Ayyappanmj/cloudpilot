"""Root, health and metrics endpoints."""

from typing import Annotated

from fastapi import APIRouter, Depends, Request
from fastapi.responses import JSONResponse, Response
from prometheus_client import CONTENT_TYPE_LATEST, generate_latest
from pydantic import BaseModel

from app.config import Settings, get_settings
from app.services.deployment_info import get_deployment_info

router = APIRouter()
SettingsDep = Annotated[Settings, Depends(get_settings)]


class DeploymentInfo(BaseModel):
    pod: str
    namespace: str
    git_commit: str


class RootResponse(BaseModel):
    name: str
    version: str
    environment: str
    status: str
    deployment: DeploymentInfo


@router.get("/", response_model=RootResponse, tags=["core"])
def root(settings: SettingsDep):
    return {
        "name": settings.app_name,
        "version": settings.app_version,
        "environment": settings.environment,
        "status": "running",
        "deployment": get_deployment_info(settings.git_commit),
    }


@router.get("/healthz", tags=["health"])
def healthz():
    """Liveness: the process is up. Deliberately does not check dependencies."""
    return {"status": "alive"}


@router.get("/readyz", tags=["health"])
def readyz(request: Request, settings: SettingsDep):
    """Readiness: should this instance receive traffic?"""
    checks = request.app.state.readiness.evaluate(settings)
    ready = all(checks.values())
    return JSONResponse(
        {"status": "ready" if ready else "not_ready", "checks": checks},
        status_code=200 if ready else 503,
    )


@router.get("/metrics", include_in_schema=False)
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
