"""Regenerates dashboards/cloudpilot-dashboard.json. Run: python monitoring/grafana/generate_dashboard.py"""
import json
import pathlib

DS = {"type": "prometheus", "uid": "prometheus"}
APP = 'job="cloudpilot"'
NS = 'namespace="cloudpilot"'
panels = []


def panel(title, expr, kind="timeseries", unit="short", x=0, y=0, w=8, h=7, legend="", thresholds=None):
    p = {
        "id": len(panels) + 1,
        "title": title,
        "type": kind,
        "datasource": DS,
        "gridPos": {"x": x, "y": y, "w": w, "h": h},
        "targets": [{"refId": "A", "datasource": DS, "expr": expr, "legendFormat": legend}],
        "fieldConfig": {"defaults": {"unit": unit}, "overrides": []},
    }
    if thresholds:
        p["fieldConfig"]["defaults"]["thresholds"] = {"mode": "absolute", "steps": thresholds}
    if kind == "stat":
        p["options"] = {"reduceOptions": {"calcs": ["lastNotNull"]}, "colorMode": "value"}
    panels.append(p)


red_green = [{"color": "red", "value": None}, {"color": "green", "value": 1}]
panel("1. Application availability", f"sum(up{{{APP}}}) / count(up{{{APP}}})", "stat", "percentunit", 0, 0, 6, 5, thresholds=red_green)
panel("2. Total HTTP requests", f"sum(http_requests_total{{{APP}}})", "stat", "short", 6, 0, 6, 5)
panel("3. Requests per second", f"sum(rate(http_requests_total{{{APP}}}[5m]))", "timeseries", "reqps", 12, 0, 12, 5)
panel("4. HTTP 4xx per second", f'sum(rate(http_requests_total{{{APP},status=~"4.."}}[5m]))', "timeseries", "reqps", 0, 5, 8, 7)
panel("5. HTTP 5xx per second", f'sum(rate(http_requests_total{{{APP},status=~"5.."}}[5m]))', "timeseries", "reqps", 8, 5, 8, 7)
panel("6. Request latency p95 / p50", f"histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket{{{APP}}}[5m])))", "timeseries", "s", 16, 5, 8, 7, "p95")
panels[-1]["targets"].append({"refId": "B", "datasource": DS, "legendFormat": "p50",
    "expr": f"histogram_quantile(0.50, sum by (le) (rate(http_request_duration_seconds_bucket{{{APP}}}[5m])))"})
panel("7. CPU usage (cores) per pod", f'sum by (pod) (rate(container_cpu_usage_seconds_total{{{NS},container="cloudpilot"}}[5m]))', "timeseries", "short", 0, 12, 8, 7, "{{pod}}")
panel("8. Memory usage per pod", f'sum by (pod) (container_memory_working_set_bytes{{{NS},container="cloudpilot"}})', "timeseries", "bytes", 8, 12, 8, 7, "{{pod}}")
panel("9. Pod status (by phase)", f"sum by (phase) (kube_pod_status_phase{{{NS}}})", "timeseries", "short", 16, 12, 8, 7, "{{phase}}")
panel("10. Container restart count", f"sum by (pod) (kube_pod_container_status_restarts_total{{{NS}}})", "timeseries", "short", 0, 19, 24, 6, "{{pod}}")

dashboard = {
    "uid": "cloudpilot-overview",
    "title": "CloudPilot Overview",
    "tags": ["cloudpilot"],
    "timezone": "browser",
    "schemaVersion": 39,
    "version": 1,
    "refresh": "30s",
    "time": {"from": "now-1h", "to": "now"},
    "panels": panels,
    "templating": {"list": []},
    "annotations": {"list": []},
}
out = pathlib.Path(__file__).parent / "dashboards" / "cloudpilot-dashboard.json"
out.write_text(json.dumps(dashboard, indent=2) + "\n")
print(f"wrote {out} with {len(panels)} panels")
