"""Prometheus metrics. Labels are low-cardinality on purpose (route templates, not raw paths)."""

from prometheus_client import Counter, Gauge, Histogram, disable_created_metrics

disable_created_metrics()  # drops the *_created series: fewer series = less Prometheus memory

REQUESTS = Counter(
    "http_requests_total",
    "Total HTTP requests by method, route template and status code.",
    ["method", "endpoint", "status"],
)
LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency in seconds by method and route template.",
    ["method", "endpoint"],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0),
)
IN_PROGRESS = Gauge(
    "http_requests_in_progress",
    "HTTP requests currently being processed.",
    ["method"],
)
APP_INFO = Gauge(
    "cloudpilot_app_info",
    "Static application information (value is always 1).",
    ["version", "environment", "git_commit"],
)

KNOWN_METHODS = {"GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"}
