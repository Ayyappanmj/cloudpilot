def test_info(client):
    r = client.get("/api/v1/info")
    assert r.status_code == 200
    body = r.json()
    assert body["environment"] == "local"
    assert body["fault_injection_enabled"] is False


def test_openapi_docs_available(client):
    assert client.get("/openapi.json").status_code == 200
    assert client.get("/docs").status_code == 200


def test_slow_disabled_by_default(client):
    assert client.get("/api/v1/slow?delay_ms=10").status_code == 403


def test_slow_enabled(make_client):
    c = make_client(enable_fault_injection=True)
    r = c.get("/api/v1/slow?delay_ms=10")
    assert r.status_code == 200
    assert r.json() == {"delayed_ms": 10}


def test_slow_validation(make_client):
    c = make_client(enable_fault_injection=True)
    assert c.get("/api/v1/slow?delay_ms=abc").status_code == 422
    assert c.get("/api/v1/slow?delay_ms=-1").status_code == 422
    assert c.get("/api/v1/slow?delay_ms=10001").status_code == 422


def test_slow_respects_configured_maximum(make_client):
    c = make_client(enable_fault_injection=True, max_slow_ms=50)
    r = c.get("/api/v1/slow?delay_ms=100")
    assert r.status_code == 422
    assert r.json()["error"]["code"] == "delay_exceeds_max"
