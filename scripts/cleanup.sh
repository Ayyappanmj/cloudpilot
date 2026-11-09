#!/usr/bin/env bash
# Safely stop optional services. Nothing is deleted without confirmation (or --yes).
# Flags: --monitoring --argocd --compose --pause-cluster --docker-prune --all
source "$(dirname "$0")/lib/common.sh"
need docker "Install Docker Desktop."; docker_up
DO_MON=0; DO_ARGO=0; DO_COMPOSE=0; DO_PAUSE=0; DO_PRUNE=0
for a in "$@"; do case "$a" in
  --monitoring) DO_MON=1;; --argocd) DO_ARGO=1;; --compose) DO_COMPOSE=1;; --pause-cluster) DO_PAUSE=1;; --docker-prune) DO_PRUNE=1;;
  --all) DO_MON=1; DO_ARGO=1; DO_COMPOSE=1; DO_PRUNE=1;; --yes|-y) ;; *) die "Unknown flag $a";; esac; done
if [[ $((DO_MON+DO_ARGO+DO_COMPOSE+DO_PAUSE+DO_PRUNE)) -eq 0 ]]; then
  echo "Usage: $0 [--monitoring] [--argocd] [--compose] [--pause-cluster] [--docker-prune] [--all] [--yes]"
  echo "Currently running containers:"; docker ps --format '  {{.Names}}\t{{.Status}}'; exit 0
fi
if [[ $DO_MON -eq 1 ]]; then run_script stop-monitoring.sh "$@"; fi
if [[ $DO_ARGO -eq 1 ]]; then run_script stop-argocd.sh "$@"; fi
if [[ $DO_COMPOSE -eq 1 ]]; then (cd "$ROOT" && docker compose --profile monitoring down) || warn "compose down failed"; fi
if [[ $DO_PAUSE -eq 1 ]]; then run_script pause-kind.sh; fi
if [[ $DO_PRUNE -eq 1 ]]; then
  confirm "Remove dangling images and build cache older than 24h (named images are kept)?" && {
    docker image prune -f; docker builder prune -f --filter until=24h; }
fi
ok "Cleanup finished."
