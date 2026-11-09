#!/usr/bin/env bash
# Removes Argo CD AND the Application (which deletes the resources it deployed, via its finalizer).
source "$(dirname "$0")/lib/common.sh"
need kubectl "Install kubectl."
if ! cluster_running 2>/dev/null; then info "Cluster not running. Nothing to stop."; exit 0; fi
use_ctx
if ! ns_exists "$ARGO_NS"; then info "Argo CD is not installed."; exit 0; fi
confirm "Remove Argo CD and the '$RELEASE' Application (this also removes the app it deployed)?" || { info "Cancelled."; exit 0; }
kubectl delete application "$RELEASE" -n "$ARGO_NS" --ignore-not-found --timeout=120s || warn "Application delete timed out"
kubectl delete namespace "$ARGO_NS" --timeout=180s || die "Could not delete namespace $ARGO_NS"
kubectl delete crd applications.argoproj.io applicationsets.argoproj.io appprojects.argoproj.io --ignore-not-found
ok "Argo CD removed."
next "scripts/deploy-local.sh to run the app without GitOps"
