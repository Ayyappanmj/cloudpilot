#!/usr/bin/env bash
# Stops the Kind node container to free ~0.7-1 GB RAM. Cluster state is kept.
source "$(dirname "$0")/lib/common.sh"
need docker "Install Docker Desktop."; docker_up
if ! cluster_exists; then info "No cluster to pause."; exit 0; fi
if ! cluster_running; then info "Already paused."; exit 0; fi
docker stop "${CLUSTER_NAME}-control-plane" >/dev/null || die "docker stop failed"
ok "Cluster paused."
next "scripts/resume-kind.sh when you need Kubernetes again"
