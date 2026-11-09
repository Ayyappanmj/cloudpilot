# BUILD_STATUS

Generated in a sandbox with **no Docker, Kind, kubectl, Helm, Terraform, PowerShell, internet access or pip package access**.
Therefore nothing that needs those tools was executed. Nothing below is marked "passed" unless it was actually run.

## Completed components (files written)
FastAPI app + 28 tests - Dockerfile, .dockerignore, Compose (app + optional monitoring profile) - Kind single-node config - Terraform (6 resources) -
plain manifests + Helm chart - Argo CD Application + GitOps values - GitHub Actions workflow - Prometheus (low-spec values, rules), Grafana (values, provisioning, 10-panel dashboard) -
17 Bash + 17 PowerShell scripts (incl. mode switching, pause/resume, start/stop monitoring/Argo CD, resource check, cleanup) - 15 docs incl. hardware requirements and operating modes.
All 5 operating modes: see docs/OPERATING_MODES.md.

## Checks actually executed (and passed)
| Check | Result |
|---|---|
| `python -m py_compile` on app, tests, dashboard generator | passed |
| Lines <= 100 chars in app/tests (proxy for Ruff E501) | passed |
| YAML parse of all `.yaml/.yml` (excluding Helm templates) and JSON parse of dashboard | passed (24 files) |
| Dashboard generator run; 10 panels written | passed |
| Helm template `{{ }}` / `end` block balance (text check only) | passed |
| Terraform bracket balance (text check only) | passed |
| `bash -n` syntax check of all `.sh` scripts | passed |
| Bash scripts fail with non-zero exit + clear message when Docker/kubectl/terraform are missing (setup-kind, deploy-local, setup-argocd, apply-infra) | passed |
| `configure-repo.sh` replaced placeholders in a temp copy; `rollback.sh` usage/argocd paths | passed |
| PowerShell bracket balance with strings stripped (text check only) | passed |
| Markdown relative links resolve | passed |
| Metric names used in alerts/dashboard exist in `app/metrics.py` | checked by grep |

## Not executed (unknown result)
`pytest` (FastAPI/pytest/httpx could not be installed offline) - `ruff check` - Docker build/run/non-root check - Kind creation - `terraform fmt/init/validate/plan/apply` -
`helm lint/template/install` - kubectl manifest validation - Argo CD install/sync - GitHub Actions run, Trivy, GHCR push - Prometheus/Grafana startup, PromQL/alert rule evaluation -
every PowerShell script (never executed, only bracket-checked) - Bash scripts beyond the failure paths above - memory estimates (not measured).
**Expect to fix small issues on first run** (for example Ruff findings or a Helm/Terraform validation error); CI's `validate-config` and `test` jobs will surface them.

## Failed
None observed. (One internal text-check false positive on a PowerShell file was investigated and was a checker limitation.)

## External setup still required
GitHub repo + push; `scripts/configure-repo`; make GHCR package public; branch-protection allowance for the bot commit; Docker Desktop/WSL2 memory limits (`.wslconfig`);
install tools (docs/WINDOWS_SETUP.md); copy `.env.example` to `.env`; real screenshots.

## Known limitations / risks
- Pinned versions from memory, not verified offline: Argo CD v2.13.2, prometheus chart 27.5.1, grafana chart 8.9.0, Python dependency pins, kindest/node v1.31.2, action versions. Scripts print how to pick valid ones.
- Ruff selects E,F,B,UP only (no import-sort/format check) to avoid unverifiable formatting failures.
- NetworkPolicy may not be enforced by Kind's default CNI. No Alertmanager notifications. Canary/blue-green are documented, not implemented.
- Argo CD polling is ~3 minutes. Local Terraform state only.
- Modes 3 and 5 require a GitHub repo and a pulled GHCR image; they cannot run fully offline.
