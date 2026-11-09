#!/usr/bin/env bash
# MODE 4: Prometheus + Grafana in Kind (low-spec). Start only when you need dashboards.
source "$(dirname "$0")/lib/common.sh"
need kubectl "Install kubectl."; need helm "Install Helm."
use_ctx
ns_exists "$MON_NS" || die "Namespace '$MON_NS' missing. Run scripts/apply-infra.sh first."
if command -v docker >/dev/null 2>&1 && [[ -n "$(docker ps -q --filter name=cloudpilot-prometheus 2>/dev/null || true)" ]]; then
  die "Compose monitoring is running. Stop it first: docker compose --profile monitoring down"
fi
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null
helm repo add grafana https://grafana.github.io/helm-charts >/dev/null
helm repo update >/dev/null || die "helm repo update failed (internet?)"

info "Installing Prometheus chart ${PROM_CHART_VERSION}"
helm upgrade --install prometheus prometheus-community/prometheus -n "$MON_NS" --version "$PROM_CHART_VERSION" \
  -f "$ROOT/monitoring/prometheus/values-lowspec.yaml" \
  --set-file 'serverFiles.alerting_rules\.yml'="$ROOT/monitoring/alerts/cloudpilot-alerts.yml" \
  --wait --timeout 5m \
  || die "Prometheus install failed. If the chart version is unknown: helm search repo prometheus-community/prometheus --versions | head ; then PROM_CHART_VERSION=<x> $0"

info "Provisioning dashboard ConfigMap"
kubectl create configmap cloudpilot-dashboard -n "$MON_NS" \
  --from-file=cloudpilot-dashboard.json="$ROOT/monitoring/grafana/dashboards/cloudpilot-dashboard.json" \
  --dry-run=client -o yaml | kubectl apply -f - || die "Dashboard ConfigMap failed"

info "Installing Grafana chart ${GRAFANA_CHART_VERSION}"
helm upgrade --install grafana grafana/grafana -n "$MON_NS" --version "$GRAFANA_CHART_VERSION" \
  -f "$ROOT/monitoring/grafana/values-lowspec.yaml" --wait --timeout 5m \
  || die "Grafana install failed. Check: helm search repo grafana/grafana --versions | head"

ok "Monitoring is up."
echo "Prometheus: kubectl port-forward -n $MON_NS svc/prometheus-server 9090:80     -> http://localhost:9090"
echo "Grafana:    kubectl port-forward -n $MON_NS svc/grafana 3000:80               -> http://localhost:3000"
echo "Grafana user: admin   password: kubectl get secret grafana -n $MON_NS -o jsonpath='{.data.admin-password}' | base64 -d"
next "Generate traffic: curl http://localhost:8080/ ; curl http://localhost:8080/api/v1/simulate-error"
