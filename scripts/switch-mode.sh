#!/usr/bin/env bash
# Usage: scripts/switch-mode.sh <1|2|3|4|5|dev|kubernetes|gitops|monitoring|complete> [--yes]
source "$(dirname "$0")/lib/common.sh"
need docker "Install Docker Desktop."; docker_up
case "${1:-}" in
  1|dev|development) MODE=1;; 2|kubernetes|k8s) MODE=2;; 3|gitops) MODE=3;;
  4|monitoring) MODE=4;; 5|complete|full) MODE=5;; *) die "Usage: $0 <1-5|dev|kubernetes|gitops|monitoring|complete>";; esac
info "Switching to MODE $MODE"
run_script check-resources.sh "$MODE"

ensure_cluster() {
  if ! cluster_exists; then run_script setup-kind.sh; elif ! cluster_running; then run_script resume-kind.sh; fi
  use_ctx
}
ensure_infra() { if ! ns_exists "$APP_NS" || ! ns_exists "$MON_NS"; then run_script apply-infra.sh "$@"; fi; }
stop_if_cluster() { if cluster_running 2>/dev/null; then use_ctx; "$@"; fi; }

case "$MODE" in
  1) # Docker + tests only: free all Kubernetes RAM
     stop_if_cluster run_script stop-monitoring.sh "$@"
     stop_if_cluster run_script stop-argocd.sh "$@"
     run_script pause-kind.sh
     (cd "$ROOT" && docker compose --profile monitoring down >/dev/null 2>&1 || true; docker compose up -d --build) || die "compose failed (is .env present? cp .env.example .env)"
     ok "MODE 1 ready: http://localhost:8000/docs   Tests: pytest";;
  2) (cd "$ROOT" && docker compose --profile monitoring down >/dev/null 2>&1 || true)
     ensure_cluster; ensure_infra "$@"
     run_script stop-monitoring.sh "$@"; run_script stop-argocd.sh "$@"
     run_script deploy-local.sh "$@";;
  3) (cd "$ROOT" && docker compose down >/dev/null 2>&1 || true)
     ensure_cluster; ensure_infra "$@"
     run_script stop-monitoring.sh "$@"
     if release_exists; then run_script destroy-local.sh "$@"; fi
     run_script setup-argocd.sh "$@";;
  4) (cd "$ROOT" && docker compose --profile monitoring down >/dev/null 2>&1 || true)
     ensure_cluster; ensure_infra "$@"
     run_script stop-argocd.sh "$@"
     run_script deploy-local.sh "$@"
     run_script start-monitoring.sh "$@";;
  5) (cd "$ROOT" && docker compose --profile monitoring down >/dev/null 2>&1 || true)
     ensure_cluster; ensure_infra "$@"
     if release_exists; then run_script destroy-local.sh "$@"; fi
     if ! argo_app_exists 2>/dev/null; then run_script setup-argocd.sh "$@"; fi
     run_script start-monitoring.sh "$@";;
esac
next "scripts/verify-platform.sh"
