def test_simulate_error_disabled_by_default(client):
    r = client.get("/api/v1/simulate-error")
    assert r.status_code == 403
    assert r.json()["error"]["code"] == "fault_injection_disabled"


def test_simulate_error_enabled(make_client):
    c = make_client(enable_fault_injection=True)
    r = c.get("/api/v1/simulate-error")
    assert r.status_code == 500
    assert r.json()["error"]["code"] == "simulated_error"
    assert c.get("/api/v1/simulate-error?status=503").status_code == 503


def test_simulate_error_rejects_other_codes(make_client):
    c = make_client(enable_fault_injection=True)
    assert c.get("/api/v1/simulate-error?status=418").status_code == 422


def test_not_found_uses_error_envelope(client):
    r = client.get("/does-not-exist")
    assert r.status_code == 404
    assert r.json()["error"]["code"] == "http_404"
    assert r.json()["error"]["request_id"]


def test_validation_error_hides_input(make_client):
    c = make_client(enable_fault_injection=True)
    r = c.get("/api/v1/slow?delay_ms=secret-text")
    body = r.json()["error"]
    assert body["code"] == "validation_error"
    assert "secret-text" not in r.text


def test_unhandled_exception_returns_generic_500(client):
    def boom():
        raise RuntimeError("internal secret detail")

    client.app.add_api_route("/boom", boom)
    r = client.get("/boom")
    assert r.status_code == 500
    assert r.json()["error"]["code"] == "internal_error"
    assert "internal secret detail" not in r.text
