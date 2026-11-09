#!/usr/bin/env bash
# Removes the Helm-installed app. Add --cluster to also delete the Kind cluster.
source "$(dirname "$0")/lib/common.sh"
need kubectl "Install kubectl."; need helm "Install Helm."
if cluster_running 2>/dev/null && kubectl config use-context "$KUBE_CONTEXT" >/dev/null 2>&1; then
  if release_exists; then
    confirm "Uninstall Helm release '$RELEASE' from namespace '$APP_NS'?" || { info "Cancelled."; exit 0; }
    helm uninstall "$RELEASE" -n "$APP_NS" || die "helm uninstall failed"
    ok "Release removed."
  else
    info "No Helm release '$RELEASE' found."
  fi
fi
for a in "$@"; do
  if [[ "$a" == "--cluster" ]]; then run_script delete-kind.sh "$@"; fi
done
next "scripts/cleanup.sh --all to stop optional services"
