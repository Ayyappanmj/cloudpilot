#!/usr/bin/env bash
# Removes Prometheus + Grafana (frees ~0.5-0.8 GB). The 'monitoring' namespace stays (Terraform owns it).
source "$(dirname "$0")/lib/common.sh"
need kubectl "Install kubectl."; need helm "Install Helm."
if ! cluster_running 2>/dev/null; then info "Cluster not running. Nothing to stop."; exit 0; fi
use_ctx
if ! ns_exists "$MON_NS"; then info "No monitoring namespace."; exit 0; fi
for r in grafana prometheus; do
  if helm status "$r" -n "$MON_NS" >/dev/null 2>&1; then
    helm uninstall "$r" -n "$MON_NS" || die "Could not uninstall $r"
  fi
done
kubectl delete configmap cloudpilot-dashboard -n "$MON_NS" --ignore-not-found
ok "Monitoring stopped."
