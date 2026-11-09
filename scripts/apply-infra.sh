#!/usr/bin/env bash
source "$(dirname "$0")/lib/common.sh"
need terraform "Install: winget install Hashicorp.Terraform"; need kubectl "Install kubectl."
use_ctx
cd "$ROOT/infrastructure/terraform"
terraform fmt -check -recursive || die "Run 'terraform fmt -recursive' first."
terraform init -input=false || die "terraform init failed (needs internet for the provider download)."
terraform validate || die "terraform validate failed."
terraform plan -input=false -out=tfplan || die "terraform plan failed."
confirm "Apply this plan to context $KUBE_CONTEXT?" || { info "Cancelled."; rm -f tfplan; exit 0; }
terraform apply -input=false tfplan || die "terraform apply failed."
rm -f tfplan
kubectl get ns "$APP_NS" "$MON_NS"
kubectl get resourcequota,limitrange -n "$APP_NS"
ok "Foundation applied."
next "scripts/deploy-local.sh"
