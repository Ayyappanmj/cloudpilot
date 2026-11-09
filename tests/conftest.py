import re

import pytest
from fastapi.testclient import TestClient

from app.config import get_settings
from app.main import create_app


@pytest.fixture
def make_client(monkeypatch):
    """Factory: make_client(enable_fault_injection=True) builds an app with CLOUDPILOT_* env set."""
    opened = []

    def _make(**env):
        for key, value in env.items():
            monkeypatch.setenv(f"CLOUDPILOT_{key.upper()}", str(value).lower())
        get_settings.cache_clear()
        client = TestClient(create_app(), raise_server_exceptions=False)
        client.__enter__()  # runs lifespan startup
        opened.append(client)
        return client

    yield _make
    for client in opened:
        client.__exit__(None, None, None)
    get_settings.cache_clear()


@pytest.fixture
def client(make_client):
    return make_client()


def metric_value(text: str, name: str, **labels: str) -> float:
    """Sum of all samples of `name` whose labels include the given key/values."""
    total = 0.0
    for line in text.splitlines():
        if not line.startswith(name + "{") and not line.startswith(name + " "):
            continue
        if all(re.search(rf'{k}="{re.escape(v)}"', line) for k, v in labels.items()):
            total += float(line.rsplit(" ", 1)[1])
    return total
