#!/usr/bin/env bash
# Shared helpers. Sourced by every scripts/*.sh file.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLUSTER_NAME="${CLOUDPILOT_CLUSTER:-cloudpilot}"
KUBE_CONTEXT="kind-${CLUSTER_NAME}"
APP_NS="cloudpilot"; MON_NS="monitoring"; ARGO_NS="argocd"
RELEASE="cloudpilot"
IMAGE_REPO="cloudpilot-sample"
# Pinned versions - see docs/HARDWARE_REQUIREMENTS.md#updating-pinned-versions
ARGOCD_VERSION="${ARGOCD_VERSION:-v2.13.2}"
PROM_CHART_VERSION="${PROM_CHART_VERSION:-27.5.1}"
GRAFANA_CHART_VERSION="${GRAFANA_CHART_VERSION:-8.9.0}"

for _a in "$@"; do
  if [[ "$_a" == "--yes" || "$_a" == "-y" ]]; then export CLOUDPILOT_ASSUME_YES=1; fi
done

info() { echo "[INFO] $*"; }
ok()   { echo "[ OK ] $*"; }
warn() { echo "[WARN] $*" >&2; }
die()  { echo "[FAIL] $*" >&2; exit 1; }
next() { echo; echo "NEXT: $*"; }

need() { command -v "$1" >/dev/null 2>&1 || die "'$1' is not installed or not on PATH. $2"; }

confirm() {
  if [[ "${CLOUDPILOT_ASSUME_YES:-}" == "1" ]]; then return 0; fi
  local answer; read -r -p "$1 [y/N] " answer
  [[ "$answer" =~ ^[Yy]$ ]]
}

docker_up() {
  docker info >/dev/null 2>&1 || die "Docker is not running. Start Docker Desktop and wait until it says 'Engine running'."
}

cluster_exists()  { kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; }
cluster_running() { [[ "$(docker inspect -f '{{.State.Running}}' "${CLUSTER_NAME}-control-plane" 2>/dev/null || true)" == "true" ]]; }
ns_exists()       { kubectl get ns "$1" >/dev/null 2>&1; }
release_exists()  { helm status "$RELEASE" -n "$APP_NS" >/dev/null 2>&1; }
argo_app_exists() { kubectl get application "$RELEASE" -n "$ARGO_NS" >/dev/null 2>&1; }

use_ctx() {
  kubectl config use-context "$KUBE_CONTEXT" >/dev/null 2>&1 \
    || die "kubectl context '$KUBE_CONTEXT' not found. Run scripts/setup-kind.sh first."
  kubectl cluster-info >/dev/null 2>&1 \
    || die "Cluster not reachable. If it is paused run scripts/resume-kind.sh; otherwise check Docker Desktop."
}

run_script() { local s="$1"; shift; bash "$ROOT/scripts/$s" "$@"; }
