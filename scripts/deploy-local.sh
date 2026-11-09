#!/usr/bin/env bash
# MODE 2: build the image locally, load it into Kind, install the Helm chart. No registry needed.
source "$(dirname "$0")/lib/common.sh"
need docker "Install Docker Desktop."; need kind "Install Kind."; need kubectl "Install kubectl."; need helm "Install: winget install Helm.Helm"
docker_up; use_ctx
ns_exists "$APP_NS" || die "Namespace '$APP_NS' missing. Run scripts/apply-infra.sh first (Terraform owns namespaces)."
if kubectl get crd applications.argoproj.io >/dev/null 2>&1 && argo_app_exists; then
  die "Argo CD currently manages '$RELEASE'. Run scripts/stop-argocd.sh first (one owner per app)."
fi
TAG="local-$(date +%Y%m%d%H%M%S)"
SHA="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo local)"
info "Building ${IMAGE_REPO}:${TAG}"
docker build -f "$ROOT/docker/Dockerfile" --build-arg GIT_COMMIT="$SHA" -t "${IMAGE_REPO}:${TAG}" "$ROOT" || die "docker build failed"
info "Loading image into Kind"
kind load docker-image "${IMAGE_REPO}:${TAG}" --name "$CLUSTER_NAME" || die "kind load failed"
info "helm upgrade --install"
helm upgrade --install "$RELEASE" "$ROOT/deploy/helm/cloudpilot" -n "$APP_NS" \
  -f "$ROOT/deploy/helm/cloudpilot/values-local.yaml" --set image.tag="$TAG" --wait --timeout 3m \
  || die "helm failed. Debug: kubectl get pods -n $APP_NS ; kubectl describe pod -n $APP_NS"
kubectl get pods -n "$APP_NS"
ok "Deployed. Open http://localhost:8080  (docs: http://localhost:8080/docs)"
next "scripts/verify-platform.sh"
