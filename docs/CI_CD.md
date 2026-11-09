# CI/CD (GitHub Actions)

File: `.github/workflows/ci-cd.yml`. Runs on GitHub-hosted runners - nothing to host locally.

| Job | When | Does | Permissions |
|---|---|---|---|
| `test` | PR + push | `ruff check`, `pytest` (JUnit artifact) | `contents: read` |
| `validate-config` | PR + push | `helm lint`, `helm template`, `terraform fmt -check/init -backend=false/validate` | `contents: read` |
| `image` | PR + push | Trivy fs scan, `docker build`, Trivy image SARIF (informational), gate on fixable CRITICAL/HIGH; **on push to main only**: GHCR login + push | `packages: write`, `security-events: write` |
| `gitops-update` | push to main | rewrite `image.tag`, commit `[skip ci]`, rebase+push | `contents: write` |

Safeguards: PRs never push images (login/push steps are conditional); `concurrency` serialises runs; `paths-ignore: gitops/**` and
`[skip ci]` prevent loops (commits made with `GITHUB_TOKEN` also don't trigger workflows); image tag is the commit SHA (immutable).
Actions are pinned to version tags; for stricter supply-chain safety pin to full commit SHAs.

## One-time GitHub setup
1. Create a **public** repo named `cloudpilot` (public keeps GHCR pulls anonymous and Actions minutes free), push this project.
2. Settings > Actions > General: allow Actions. Workflow permissions can stay "Read repository contents" - jobs request what they need.
3. Branch protection on `main`: if you require PRs, allow `github-actions[bot]` to bypass, otherwise `gitops-update` cannot push
   (alternative: a dedicated `gitops` branch/repo with a fine-scoped PAT stored as a secret).
4. After the first successful run: Profile > Packages > `cloudpilot` > Package settings > Change visibility > **Public**.
5. Security tab > Code scanning shows Trivy results (free for public repos).

## Troubleshooting
| Symptom | Cause / fix |
|---|---|
| `denied: permission_denied: write_package` | Package linked to another repo or token lacks `packages: write`; check package settings > Manage Actions access |
| `gitops-update` push rejected (protected branch) | See setup step 3 |
| Trivy gate fails | Real finding: read the table; bump base image/dependency and re-run (docs/SECURITY.md). Do not add ignores just to go green |
| `terraform init` fails in CI | Provider download blocked/outage; re-run |
| SARIF upload 403 on a fork PR | Expected: forks have read-only tokens; step is skipped for PRs |
| Pull fails in cluster (`ImagePullBackOff`) | Package still private - make it public or create an imagePullSecret (docs/GITOPS.md) |

## What can't be tested locally
The workflow itself, GHCR push, SARIF upload and the bot commit need a real GitHub repo. Only YAML syntax was validated offline.
