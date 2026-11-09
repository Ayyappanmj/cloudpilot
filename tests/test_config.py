import pytest

from app.config import Settings


def test_defaults_are_safe():
    s = Settings()
    assert s.enable_fault_injection is False
    assert s.simulate_not_ready is False
    assert s.max_slow_ms == 3000


def test_env_override(monkeypatch):
    monkeypatch.setenv("CLOUDPILOT_ENVIRONMENT", "staging")
    monkeypatch.setenv("CLOUDPILOT_ENABLE_FAULT_INJECTION", "true")
    s = Settings()
    assert s.environment == "staging"
    assert s.enable_fault_injection is True


def test_max_slow_ms_is_bounded(monkeypatch):
    monkeypatch.setenv("CLOUDPILOT_MAX_SLOW_MS", "999999")
    with pytest.raises(ValueError):
        Settings()
