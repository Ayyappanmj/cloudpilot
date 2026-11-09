# Terraform - foundational Kubernetes configuration

**Owns:** namespaces (`cloudpilot`, `monitoring`), ResourceQuotas, LimitRanges, Pod Security labels.
**Does not own:** anything deployed into those namespaces (Argo CD / Helm do). No cloud account, no cost.

## Safe execution sequence
```bash
# 0. Cluster exists and kubectl points at it
kubectl config current-context          # expect: kind-cloudpilot
cd infrastructure/terraform
terraform fmt -check -recursive         # formatting
terraform init                          # downloads hashicorp/kubernetes (~15 MB, needs internet)
terraform validate                      # syntax + schema
terraform plan -out tfplan              # REVIEW: expect 6 resources to add
terraform apply tfplan                  # create
kubectl get ns cloudpilot monitoring
kubectl describe resourcequota -n cloudpilot
```
Or run `scripts/apply-infra.sh` / `scripts/apply-infra.ps1` (same steps, with a confirmation prompt).

## State handling
State is a local `terraform.tfstate` in this folder (fine for a single-developer local lab). It can contain
data about your cluster, so it is **git-ignored - never commit it**. Delete the Kind cluster and you must also
delete the state (`terraform state list` will show stale entries otherwise). For teams you would use a remote
backend with locking (e.g. S3+DynamoDB, or Terraform Cloud) - documented, not implemented here.

## Variables
See `variables.tf`; override via `terraform.tfvars` (copy from `terraform.tfvars.example`).

## Destroy
`terraform destroy` deletes the namespaces **and everything inside them**. Uninstall the app first.
