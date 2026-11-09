#!/usr/bin/env bash
# MODE 3: install Argo CD (trimmed) and create the Application.
source "$(dirname "$0")/lib/common.sh"
need kubectl "Install kubectl."; need helm "Install Helm (used to detect conflicting releases)."
use_ctx
APP_FILE="$ROOT/gitops/argocd/application.yaml"
if grep -q "YOUR_GITHUB_USERNAME" "$APP_FILE" "$ROOT/gitops/environments/local/values.yaml"; then
  die "Placeholders not replaced. Run: scripts/configure-repo.sh <github-user>  then commit and push."
fi
ns_exists "$APP_NS" || die "Namespace '$APP_NS' missing. Run scripts/apply-infra.sh first."
if release_exists; then die "Helm release '$RELEASE' exists. Run scripts/destroy-local.sh first (one owner per app)."; fi

info "Installing Argo CD ${ARGOCD_VERSION} (needs internet)"
kubectl get ns "$ARGO_NS" >/dev/null 2>&1 || kubectl create namespace "$ARGO_NS"
kubectl apply -n "$ARGO_NS" --server-side --force-conflicts \
  -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml" \
  || die "Could not apply Argo CD manifests (internet? valid ARGOCD_VERSION?)"
info "Scaling down components this demo does not need (saves RAM): dex, notifications, applicationset"
kubectl scale deployment argocd-dex-server argocd-notifications-controller argocd-applicationset-controller \
  -n "$ARGO_NS" --replicas=0 || warn "Could not scale down optional components"
kubectl rollout status deployment/argocd-server deployment/argocd-repo-server -n "$ARGO_NS" --timeout=300s 2>/dev/null \
  || { kubectl rollout status deployment/argocd-server -n "$ARGO_NS" --timeout=300s && kubectl rollout status deployment/argocd-repo-server -n "$ARGO_NS" --timeout=300s; } \
  || die "Argo CD server did not become ready"
kubectl rollout status statefulset/argocd-application-controller -n "$ARGO_NS" --timeout=300s || die "Application controller not ready"
kubectl wait --for condition=established crd/applications.argoproj.io --timeout=60s || die "CRD not established"
kubectl apply -f "$APP_FILE" || die "Could not apply the Application"
ok "Argo CD installed and Application created."
echo "UI:        kubectl port-forward svc/argocd-server -n $ARGO_NS 8081:443   ->  https://localhost:8081"
echo "Username:  admin"
echo "Password:  kubectl -n $ARGO_NS get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo "Status:    kubectl get application $RELEASE -n $ARGO_NS"
next "scripts/verify-platform.sh   (Argo polls Git about every 3 minutes; use Refresh in the UI to speed up)"
