def test_root(client):
    r = client.get("/")
    assert r.status_code == 200
    body = r.json()
    assert body["name"] == "CloudPilot Sample Service"
    assert body["status"] == "running"
    assert {"pod", "namespace", "git_commit"} <= body["deployment"].keys()


def test_healthz(client):
    r = client.get("/healthz")
    assert r.status_code == 200
    assert r.json() == {"status": "alive"}


def test_readyz_ready(client):
    r = client.get("/readyz")
    assert r.status_code == 200
    assert r.json()["status"] == "ready"


def test_readyz_not_ready_when_forced(make_client):
    c = make_client(simulate_not_ready=True)
    r = c.get("/readyz")
    assert r.status_code == 503
    assert r.json()["checks"]["not_forced_unready"] is False
    assert c.get("/healthz").status_code == 200  # liveness unaffected


def test_correlation_id_generated_and_echoed(client):
    assert len(client.get("/healthz").headers["x-request-id"]) > 0
    r = client.get("/", headers={"X-Request-ID": "abc-123"})
    assert r.headers["x-request-id"] == "abc-123"


def test_unsafe_correlation_id_is_replaced(client):
    r = client.get("/", headers={"X-Request-ID": "bad id with spaces"})
    assert r.headers["x-request-id"] != "bad id with spaces"
