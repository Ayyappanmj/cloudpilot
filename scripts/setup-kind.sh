#!/usr/bin/env bash
source "$(dirname "$0")/lib/common.sh"
need docker "Install Docker Desktop: https://docs.docker.com/desktop/"
need kind   "Install: winget install Kubernetes.kind (or see docs/WINDOWS_SETUP.md)"
need kubectl "Install: winget install Kubernetes.kubectl"
docker_up

if cluster_exists; then
  warn "Kind cluster '$CLUSTER_NAME' already exists - leaving it untouched (no overwrite)."
  if ! cluster_running; then warn "It is stopped. Start it with scripts/resume-kind.sh"; exit 0; fi
else
  if (echo >/dev/tcp/127.0.0.1/8080) 2>/dev/null; then
    die "Host port 8080 is already in use. Free it or edit hostPort in kind/kind-config.yaml."
  fi
  info "Creating single-node Kind cluster '$CLUSTER_NAME' (first run downloads the node image, ~1 GB)..."
  if ! kind create cluster --config "$ROOT/kind/kind-config.yaml" --wait 180s; then
    echo "Troubleshooting: 1) docker info  2) give Docker Desktop >= 4 GB RAM (docs/HARDWARE_REQUIREMENTS.md)" >&2
    echo "                 3) kind export logs ./kind-logs --name $CLUSTER_NAME" >&2
    die "Cluster creation failed."
  fi
fi
kubectl config use-context "$KUBE_CONTEXT" >/dev/null
kubectl wait --for=condition=Ready node --all --timeout=120s || die "Node did not become Ready."
kubectl get nodes -o wide
ok "Cluster ready (context: $KUBE_CONTEXT)"
next "scripts/apply-infra.sh   (Terraform namespaces/quotas), then scripts/deploy-local.sh"
