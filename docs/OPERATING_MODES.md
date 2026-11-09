# Operating modes

| Mode | Name | Runs | Typical use |
|---|---|---|---|
| 1 | Development | FastAPI + Docker (+ optional Compose monitoring) + pytest. **Kind is paused.** | Coding, tests, image checks |
| 2 | Kubernetes | Kind + kubectl + Terraform foundation + Helm-installed app | Learn K8s, probes, rolling updates, Helm rollback |
| 3 | GitOps | Kind + Argo CD + app deployed from Git (GHCR image) | Demo GitHub Actions -> Argo CD |
| 4 | Monitoring | Kind + app (Helm) + Prometheus + Grafana | Dashboards, alerts, failure demos |
| 5 | Complete | Kind + Argo CD + app + Prometheus + Grafana | Full interview demo (needs ~5 GB for WSL2) |

GitHub Actions (CI) and Trivy-in-CI always run on GitHub, never locally. Trivy can also be run manually (docs/SECURITY.md).

## Switching
```powershell
# PowerShell (Windows)
scripts\check-resources.ps1             # which modes fit your Docker memory
scripts\switch-mode.ps1 1               # or: dev | kubernetes | gitops | monitoring | complete
scripts\switch-mode.ps1 4 -Yes          # skip confirmation prompts
```
```bash
# Bash (WSL2/Linux)
bash scripts/switch-mode.sh 4 --yes
```
`switch-mode` first runs `check-resources`, then stops what the target mode does not need, then starts what it needs.

## One owner per application
The app in namespace `cloudpilot` is owned by **either** Helm (`deploy-local`, Modes 2 and 4) **or** Argo CD (Modes 3 and 5).
Switching between them removes the previous owner's release first (with confirmation). Terraform owns only namespaces,
quotas and limit ranges and is unaffected by switching.

## Manual start/stop of optional pieces
| Action | PowerShell | Bash |
|---|---|---|
| Start monitoring | `scripts\start-monitoring.ps1` | `scripts/start-monitoring.sh` |
| Stop monitoring | `scripts\stop-monitoring.ps1` | `scripts/stop-monitoring.sh` |
| Install Argo CD + app | `scripts\setup-argocd.ps1` | `scripts/setup-argocd.sh` |
| Remove Argo CD | `scripts\stop-argocd.ps1` | `scripts/stop-argocd.sh` |
| Pause / resume Kind (frees ~1 GB) | `scripts\pause-kind.ps1` / `resume-kind.ps1` | `.sh` equivalents |
| Cleanup (safe, prompts) | `scripts\cleanup.ps1 -All` | `scripts/cleanup.sh --all` |
| Compose app (Mode 1) | `docker compose up -d --build` | same |
| Compose monitoring (Mode 1 only) | `docker compose --profile monitoring up -d` | same |

Compose monitoring and Kubernetes monitoring must never run together (port conflicts, double RAM); `start-monitoring` refuses to run if the Compose one is up.
