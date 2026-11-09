# Hardware requirements and low-spec tuning

**Target:** Windows 10/11, 8 GB RAM, 4 CPU cores, 20 GB free disk, Docker Desktop (WSL2 backend).

> The memory numbers below are **planning estimates** from typical component footprints, not measurements from this
> project. Measure your own machine: `docker stats --no-stream` and `kubectl top pods -A` (needs metrics-server).

## Estimated memory per component (inside the WSL2 VM)
| Component | Estimate | Notes |
|---|---|---|
| Kind control-plane node (etcd, apiserver, kubelet, containerd, CoreDNS, kindnet) | 0.7 - 1.0 GB | Single node only; no workers |
| CloudPilot app, 1 replica | ~50 - 100 MB | limit 192 Mi |
| Argo CD (server, repo-server, controller, redis; dex/notifications/applicationset scaled to 0) | 0.5 - 0.7 GB | Installed only in Modes 3 and 5 |
| Prometheus (2-day retention, 30 s scrape) + kube-state-metrics | 0.3 - 0.5 GB | No Alertmanager, no PV |
| Grafana | 0.1 - 0.2 GB | No persistence |

## Recommended WSL2 limit per mode
Docker Desktop with the WSL2 backend takes its memory from WSL2, so set limits in `%UserProfile%\.wslconfig`
(not in the Docker Desktop UI):
```ini
[wsl2]
memory=4GB        ; Mode 1: 3GB | Modes 2,3,4: 4GB | Mode 5: 5GB
processors=4
swap=2GB
```
Optional (Windows 11, recent WSL): add `[experimental]` with `autoMemoryReclaim=gradual` and `sparseVhd=true`.
Apply with PowerShell: `wsl --shutdown`, then restart Docker Desktop. Check with `scripts\check-resources.ps1`.

| Mode | WSL2 memory | `check-resources` minimum | Windows keeps |
|---|---|---|---|
| 1 Development | 3 GB | 1.5 GiB | ~5 GB |
| 2 Kubernetes | 4 GB | 3.0 GiB | ~4 GB |
| 3 GitOps | 4 GB | 3.5 GiB | ~4 GB |
| 4 Monitoring | 4 GB | 3.5 GiB | ~4 GB |
| 5 Complete | 5 GB | 4.5 GiB | ~3 GB - close browsers/IDE extensions |

## Docker Desktop settings that help
- Settings > General: untick "Start Docker Desktop when you sign in"; enable "Use Resource Saver" if offered.
- Settings > Kubernetes: **leave Docker Desktop's built-in Kubernetes OFF** (Kind is the cluster; never run both, and never Minikube + Kind).
- Don't run `docker compose --profile monitoring` at the same time as Kubernetes monitoring (the scripts enforce this).

## Disk (20 GB is enough)
Kind node image ~1 GB, Python base ~150 MB, app image ~150 MB, Argo CD/Prometheus/Grafana images ~1 GB total, plus WSL VHD growth.
Reclaim with `scripts\cleanup.ps1 -DockerPrune`. No PersistentVolumes are used (Prometheus and Grafana use emptyDir), so there is nothing else to clean.

## What was reduced, and what was NOT sacrificed
Reduced: one node, one replica, 30 s scrape, 2-day retention, no Alertmanager/node-exporter/Pushgateway, no PVs, Argo CD
extras scaled to zero, HPA/PDB off by default. Kept: CI/CD, image scanning, Terraform-managed namespaces and quotas, Helm,
Argo CD GitOps with auto-sync/self-heal/prune, Prometheus metrics + alert rules, provisioned Grafana dashboard, rollbacks.

## Updating pinned versions
| What | Where | Check for newer |
|---|---|---|
| Kind node image | `kind/kind-config.yaml` (`kindest/node:v1.31.2`) | Kind release notes list compatible images |
| Argo CD | `ARGOCD_VERSION` in `scripts/lib/common.*` or env var | github.com/argoproj/argo-cd/releases |
| Prometheus / Grafana charts | `PROM_CHART_VERSION`, `GRAFANA_CHART_VERSION` | `helm search repo prometheus-community/prometheus --versions` |
| Python deps | `requirements*.txt` | `pip list --outdated`; rerun tests; Trivy scans in CI |
| GitHub Actions | `.github/workflows/ci-cd.yml` | Pin to a full commit SHA for stricter supply-chain safety |

**The chart/Argo versions were chosen from memory and could not be verified offline when this project was generated.**
If a version is not found, the scripts print the `helm search` command to pick a valid one.
