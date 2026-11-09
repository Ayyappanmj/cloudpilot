# Demo guide (about 10 minutes)

Prepare: GitHub repo pushed, CI green once, package public, `scripts\configure-repo.ps1` done, WSL2 memory 5 GB, browsers closed.
1. **Show the repo and workflow** (1 min): `.github/workflows/ci-cd.yml`, Actions run, Security tab (Trivy).
2. **Mode 5:** `scripts\switch-mode.ps1 5` (prepare beforehand - first image pulls are slow).
3. **GitOps** (3 min): Argo UI (`kubectl port-forward svc/argocd-server -n argocd 8081:443`). Change the app (e.g. version string), push, watch Actions -> new `sha-` tag commit -> Argo sync -> `kubectl rollout status`.
4. **Monitoring** (2 min): Grafana dashboard; run `curl.exe http://localhost:8080/api/v1/simulate-error` a few dozen times; show the 5xx panel and the alert in Prometheus.
5. **Rollback** (2 min): `scripts\rollback.ps1 git`; show Argo returning to the previous tag.
6. **Failure drill** (optional): FAILURE_SIMULATION #3 or #4.
7. Wrap up: `scripts\switch-mode.ps1 1` to free memory.

## Recording checklist
Resolution 1080p; hide tokens/passwords (Grafana password, PATs); show terminal + browser; narrate the flow; keep under 10 minutes; disclose it is a local Kind demo.

## Two-minute interview explanation
"CloudPilot is a local-first DevOps platform I built to practise the full delivery lifecycle at zero cost. A FastAPI service with health checks and Prometheus
metrics is built by GitHub Actions: Ruff and pytest, Helm and Terraform validation, then a Docker build scanned by Trivy. If it passes, the image is pushed to GHCR
with an immutable commit-SHA tag, and a second job commits that tag into a GitOps values file. Argo CD, running in a single-node Kind cluster, detects the commit and
syncs the Helm chart with a zero-unavailable rolling update. Terraform owns the namespaces, quotas and limit ranges, so Terraform and Argo never fight over resources.
Prometheus scrapes the app and Grafana shows availability, latency, errors, CPU, memory and restarts; alert rules cover down, 5xx, latency, restarts, CPU and memory.
Rollback is a git revert. Because I developed on an 8 GB laptop, I built five operating modes so I can run only what I need, and I wrote ten failure simulations
- crash loops, bad images, failed syncs, quota rejections - with detection and recovery steps. It is a local lab, not a production deployment; the next steps
would be image signing, a remote Terraform backend, and a real ingress with Argo Rollouts canaries."
