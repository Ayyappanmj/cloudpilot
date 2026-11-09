#!/usr/bin/env bash
source "$(dirname "$0")/lib/common.sh"
need docker "Install Docker Desktop."; need kubectl "Install kubectl."; docker_up
cluster_exists || die "Cluster does not exist. Run scripts/setup-kind.sh"
if ! cluster_running; then docker start "${CLUSTER_NAME}-control-plane" >/dev/null || die "docker start failed"; fi
use_ctx
kubectl wait --for=condition=Ready node --all --timeout=180s || die "Node not Ready. If this persists: scripts/delete-kind.sh then setup-kind.sh"
ok "Cluster running."
