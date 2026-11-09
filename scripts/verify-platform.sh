#!/usr/bin/env bash
# Verifies whatever is currently deployed (mode-aware). Exits non-zero on any failed check.
source "$(dirname "$0")/lib/common.sh"
need kubectl "Install kubectl."
set +e
FAILS=0
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$d"; else echo "[FAIL] $d" >&2; FAILS=$((FAILS+1)); fi; }
LBL="app.kubernetes.io/name=cloudpilot"

check "kubectl context $KUBE_CONTEXT reachable" bash -c "kubectl config use-context $KUBE_CONTEXT && kubectl cluster-info"
[[ $FAILS -eq 0 ]] || { echo "Cluster unreachable: scripts/resume-kind.sh or scripts/setup-kind.sh" >&2; exit 1; }
check "node Ready" bash -c "kubectl get nodes --no-headers | grep -q ' Ready'"
check "namespace $APP_NS exists" kubectl get ns "$APP_NS"
check "ResourceQuota present (Terraform)" bash -c "kubectl get resourcequota -n $APP_NS --no-headers | grep -q ."

if kubectl get deploy -n "$APP_NS" -l "$LBL" --no-headers 2>/dev/null | grep -q .; then
  check "deployment Available" kubectl wait --for=condition=Available deploy -l "$LBL" -n "$APP_NS" --timeout=30s
  check "pods Running" bash -c "kubectl get pods -n $APP_NS -l $LBL --no-headers | awk '{print \$3}' | grep -qx Running"
  check "service exists" kubectl get svc -n "$APP_NS" -l "$LBL"
  check "memory/cpu limits set" bash -c "kubectl get deploy -n $APP_NS -l $LBL -o jsonpath='{.items[0].spec.template.spec.containers[0].resources.limits.memory}' | grep -q ."
  check "runs as non-root" bash -c "kubectl get deploy -n $APP_NS -l $LBL -o jsonpath='{.items[0].spec.template.spec.securityContext.runAsNonRoot}' | grep -q true"
  check "readiness+liveness probes set" bash -c "kubectl get deploy -n $APP_NS -l $LBL -o jsonpath='{.items[0].spec.template.spec.containers[0].readinessProbe.httpGet.path}{.items[0].spec.template.spec.containers[0].livenessProbe.httpGet.path}' | grep -q healthz"
  if command -v curl >/dev/null 2>&1; then
    check "GET /healthz (localhost:8080)" curl -fsS --max-time 5 http://localhost:8080/healthz
    check "GET /readyz" curl -fsS --max-time 5 http://localhost:8080/readyz
    check "GET /metrics has http_requests_total or app_info" bash -c "curl -fsS --max-time 5 http://localhost:8080/metrics | grep -q cloudpilot_app_info"
  else warn "curl not found - skipping HTTP checks"; fi
else
  warn "Application not deployed (fine for Mode 1). Deploy with scripts/deploy-local.sh or setup-argocd.sh"
fi

if ns_exists "$ARGO_NS" && argo_app_exists; then
  check "Argo CD app Synced" bash -c "[[ \$(kubectl get application $RELEASE -n $ARGO_NS -o jsonpath='{.status.sync.status}') == Synced ]]"
  check "Argo CD app Healthy" bash -c "[[ \$(kubectl get application $RELEASE -n $ARGO_NS -o jsonpath='{.status.health.status}') == Healthy ]]"
fi
if kubectl get deploy prometheus-server -n "$MON_NS" >/dev/null 2>&1; then
  check "Prometheus Available" kubectl wait --for=condition=Available deploy/prometheus-server -n "$MON_NS" --timeout=30s
  check "Grafana Available"    kubectl wait --for=condition=Available deploy/grafana -n "$MON_NS" --timeout=30s
fi
echo
if [[ $FAILS -eq 0 ]]; then ok "All checks passed."; else echo "[FAIL] $FAILS check(s) failed. See docs/TROUBLESHOOTING.md" >&2; exit 1; fi
