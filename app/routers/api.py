"""Versioned API endpoints, including guarded fault-injection helpers for monitoring demos."""

import asyncio
import platform
from typing import Annotated, Literal

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, BeforeValidator

from app.config import Settings, get_settings
from app.exceptions import AppError
from app.services.fault_injection import SlowSlot, require_enabled

router = APIRouter(prefix="/api/v1", tags=["api"])
SettingsDep = Annotated[Settings, Depends(get_settings)]


class InfoResponse(BaseModel):
    name: str
    version: str
    environment: str
    python_version: str
    git_commit: str
    fault_injection_enabled: bool


class SlowResponse(BaseModel):
    delayed_ms: int


@router.get("/info", response_model=InfoResponse)
def info(settings: SettingsDep):
    return {
        "name": settings.app_name,
        "version": settings.app_version,
        "environment": settings.environment,
        "python_version": platform.python_version(),
        "git_commit": settings.git_commit,
        "fault_injection_enabled": settings.enable_fault_injection,
    }


@router.get("/simulate-error")
def simulate_error(
    settings: SettingsDep,
    status: Annotated[
        Literal[500, 502, 503],
        BeforeValidator(lambda v: int(v) if str(v).isdigit() else v),
        Query(),
    ] = 500,
):
    """Returns a controlled 5xx so alerts and dashboards can be demonstrated."""
    require_enabled(settings)
    raise AppError(status, "simulated_error", "Simulated error for monitoring demo.")


@router.get("/slow", response_model=SlowResponse)
async def slow(
    settings: SettingsDep,
    delay_ms: Annotated[int, Query(ge=0, le=10000)] = 500,
):
    """Sleeps for delay_ms (capped by CLOUDPILOT_MAX_SLOW_MS) to produce latency data."""
    require_enabled(settings)
    if delay_ms > settings.max_slow_ms:
        raise AppError(
            422, "delay_exceeds_max", f"delay_ms must be <= {settings.max_slow_ms} in this setup."
        )
    async with SlowSlot():
        await asyncio.sleep(delay_ms / 1000)
    return {"delayed_ms": delay_ms}
