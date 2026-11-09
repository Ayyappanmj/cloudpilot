# Terraform

See `infrastructure/terraform/README.md` for the command sequence and state handling.

- **Provider:** `hashicorp/kubernetes ~> 2.35`, using kubeconfig `~/.kube/config`, context `kind-cloudpilot`. No cloud account, no cost.
- **Resources (6 total):** 2 namespaces, 2 ResourceQuotas, 2 LimitRanges via `for_each` over `local.namespaces`.
- **Why quotas on a laptop?** They are a safety net: a runaway deployment cannot eat your RAM, and they teach real multi-tenant practice.
  App quota: 500m/512Mi requests, 1 CPU/1Gi limits, 10 pods. Monitoring quota: 1 CPU/1Gi requests, 2 CPU/2Gi limits.
- **Drift:** `terraform plan` shows manual changes (e.g. someone edits the quota with kubectl); `apply` restores them.
- **Not managed here:** anything in the app namespace except the above (Argo CD/Helm own it), Argo CD itself, Prometheus/Grafana (Helm).
- **Destroy:** deletes namespaces and everything in them - run `scripts\destroy-local.ps1` first.
- CI runs `fmt -check`, `init -backend=false` and `validate`; **no plan/apply happens in CI** (no cluster there).
