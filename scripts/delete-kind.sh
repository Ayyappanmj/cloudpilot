#!/usr/bin/env bash
source "$(dirname "$0")/lib/common.sh"
need kind "Install Kind first."
if ! cluster_exists; then info "Cluster '$CLUSTER_NAME' does not exist. Nothing to do."; exit 0; fi
confirm "Delete Kind cluster '$CLUSTER_NAME' and everything in it?" || { info "Cancelled."; exit 0; }
kind delete cluster --name "$CLUSTER_NAME" || die "Could not delete cluster."
ok "Deleted. If you used Terraform, also delete infrastructure/terraform/terraform.tfstate*"
next "scripts/setup-kind.sh to recreate it"
