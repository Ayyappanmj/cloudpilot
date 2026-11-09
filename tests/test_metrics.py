from tests.conftest import metric_value


def _scrape(client) -> str:
    r = client.get("/metrics")
    assert r.status_code == 200
    assert r.headers["content-type"].startswith("text/plain")
    return r.text


def test_metrics_expose_expected_series(client):
    client.get("/")
    text = _scrape(client)
    for name in (
        "http_requests_total",
        "http_request_duration_seconds_bucket",
        "http_requests_in_progress",
        "cloudpilot_app_info",
    ):
        assert name in text


def test_request_counter_increments_with_labels(client):
    labels = {"method": "GET", "endpoint": "/", "status": "200"}
    before = metric_value(_scrape(client), "http_requests_total", **labels)
    client.get("/")
    client.get("/")
    after = metric_value(_scrape(client), "http_requests_total", **labels)
    assert after - before == 2


def test_unknown_paths_use_bounded_label(client):
    client.get("/random-path-1")
    client.get("/random-path-2")
    text = _scrape(client)
    assert "random-path" not in text
    assert metric_value(text, "http_requests_total", endpoint="unmatched", status="404") >= 2


def test_5xx_is_counted(make_client):
    c = make_client(enable_fault_injection=True)
    before = metric_value(_scrape(c), "http_requests_total", status="500")
    c.get("/api/v1/simulate-error")
    assert metric_value(_scrape(c), "http_requests_total", status="500") - before == 1


def test_unhandled_exception_is_counted_as_500(client):
    def boom():
        raise RuntimeError("x")

    client.app.add_api_route("/boom", boom)
    client.get("/boom")
    assert metric_value(_scrape(client), "http_requests_total", endpoint="/boom", status="500") >= 1


def test_metrics_endpoint_does_not_count_itself(client):
    _scrape(client)
    assert metric_value(_scrape(client), "http_requests_total", endpoint="/metrics") == 0


def test_app_info_has_version_but_no_secrets(client):
    text = _scrape(client)
    line = next(ln for ln in text.splitlines() if ln.startswith("cloudpilot_app_info{"))
    assert 'version="0.1.0"' in line
    assert "password" not in text.lower() and "token" not in text.lower()
