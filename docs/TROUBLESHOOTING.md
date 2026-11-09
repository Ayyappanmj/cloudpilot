# Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `docker info` fails | Docker Desktop not started | Start it; wait for "Engine running" |
| Kind create hangs/fails | Too little memory, port 8080 busy | Raise WSL2 memory (docs/HARDWARE_REQUIREMENTS.md); free 8080; `kind export logs ./kind-logs --name cloudpilot` |
| Everything slow / Docker killed | WSL2 out of memory | Use a lighter mode: `scripts\switch-mode.ps1 1`; `scripts\cleanup.ps1 -All` |
| `kubectl` talks to the wrong cluster | Wrong context | `kubectl config use-context kind-cloudpilot` |
| Cluster unreachable after reboot | Kind container stopped / IP changed | `scripts\resume-kind.ps1`; if still broken `delete-kind` + `setup-kind` + `apply-infra` (delete tfstate too) |
| Terraform "namespace already exists" | Created outside Terraform | `terraform import 'kubernetes_namespace_v1.this["cloudpilot"]' cloudpilot` or delete the namespace |
| `deploy-local` "namespace missing" | Terraform not applied | `scripts\apply-infra.ps1` |
| `ErrImageNeverPull` | Image not loaded into Kind | Re-run `scripts\deploy-local.ps1` (it runs `kind load docker-image`) |
| `ImagePullBackOff` (GitOps) | GHCR package private / wrong owner in values | Make public or add pull secret; check `image.repository` |
| App not on localhost:8080 | Service not NodePort, or Argo values differ | `kubectl get svc -n cloudpilot`; else `kubectl port-forward -n cloudpilot svc/cloudpilot 8080:8000` |
| Pod `0/1` | Readiness failing | `kubectl describe pod -n cloudpilot`; `curl localhost:8080/readyz` |
| Helm/Argo conflict "already exists / not owned" | Two owners for one app | Remove one (`destroy-local` or `stop-argocd`) |
| Argo app `OutOfSync` forever | Placeholder repo URL, repo private, bad path | `kubectl describe application cloudpilot -n argocd`; run `configure-repo`, push |
| Helm chart version not found | Pinned version unavailable | `helm search repo prometheus-community/prometheus --versions`; set `$env:PROM_CHART_VERSION` |
| Prometheus pod Pending / OOMKilled | Quota or memory | `kubectl describe pod -n monitoring`; raise `monitoring_quota` in Terraform or stop other components |
| Grafana dashboard empty | No traffic, or target down | Send requests; check Prometheus Targets |
| Compose monitoring + K8s monitoring clash | Both running | `docker compose --profile monitoring down` |
| PowerShell "running scripts is disabled" | Execution policy | `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` |
| `winget`/tool not found after install | PATH not refreshed | Open a new terminal |
Useful: `kubectl get events -n cloudpilot --sort-by=.lastTimestamp`, `kubectl logs deploy/cloudpilot -n cloudpilot`, `scripts\verify-platform.ps1`.
