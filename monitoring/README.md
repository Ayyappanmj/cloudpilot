# Monitoring files
- `prometheus/values-lowspec.yaml` - Helm values for Kubernetes (2-day retention, 30 s scrape, no PV, no Alertmanager)
- `prometheus/prometheus-compose.yml` - Compose-mode config (Mode 1 only)
- `alerts/cloudpilot-alerts.yml` - alert rules (single source of truth for both modes)
- `grafana/values-lowspec.yaml`, `grafana/provisioning/*`, `grafana/dashboards/cloudpilot-dashboard.json`
Start/stop: `scripts/start-monitoring.(sh|ps1)` / `scripts/stop-monitoring.(sh|ps1)`. See docs/MONITORING.md.
