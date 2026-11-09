"""Environment-based configuration. Every variable is prefixed with CLOUDPILOT_."""

from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="CLOUDPILOT_", extra="ignore")

    app_name: str = "CloudPilot Sample Service"
    app_version: str = "0.1.0"
    environment: str = "local"
    log_level: str = "INFO"
    git_commit: str = "unknown"
    # Fault-injection endpoints (/api/v1/simulate-error, /api/v1/slow) are OFF unless enabled.
    enable_fault_injection: bool = False
    # Hard upper bound for /api/v1/slow, regardless of what the caller asks for.
    max_slow_ms: int = Field(default=3000, ge=0, le=10000)
    # Makes /readyz return 503. Used by the failure-simulation guide.
    simulate_not_ready: bool = False


@lru_cache
def get_settings() -> Settings:
    return Settings()
