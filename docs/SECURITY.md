# Security

## Trivy
| Scan | Where | Gate |
|---|---|---|
| Filesystem (dependencies, secrets, IaC misconfig) | CI `image` job | fails on CRITICAL/HIGH with a fix available |
| Image (OS packages + Python deps) -> SARIF, all severities | CI, uploaded to GitHub Security tab (push only) | informational |
| Image gate | CI | fails on fixable CRITICAL/HIGH |
Manual run (needs Docker; PowerShell):
```powershell
docker run --rm -v //var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity CRITICAL,HIGH cloudpilot-sample:local
docker run --rm -v ${PWD}:/src aquasec/trivy:latest fs --scanners vuln,secret,misconfig /src
```
A finished scan means "known issues were looked for", **not** "the image is secure" (zero-days, logic bugs and misconfiguration remain).

## Vulnerability policy
| Severity | Action |
|---|---|
| CRITICAL | Build blocked if fixable. Patch/rebase immediately; if unfixable, document risk and mitigation in an issue |
| HIGH | Build blocked if fixable. Fix within the sprint (days) |
| MEDIUM | Tracked; fix in routine dependency updates (weekly/monthly) |
| LOW/UNKNOWN | Informational |
`ignore-unfixed: true` is used for the *gate* because nothing can be done until upstream ships a fix; those findings stay visible in SARIF.
**False positives:** only suppress via `.trivyignore` with CVE id, justification, owner and an expiry date in a comment, reviewed in a PR.
No ignores exist today. Fix path: bump `requirements.txt` or the base image tag, rebuild (CI rebuilds on every push), re-scan.

## Controls implemented
Non-root image (UID 10001); multi-stage slim build; no secrets in image/Git (`.env` ignored, secret template only); least-privilege workflow
permissions per job; PR runs cannot publish; read-only root FS, dropped capabilities, seccomp, no privilege escalation; no host mounts;
resource limits; Pod Security `restricted` on the app namespace; no service-account token mounted (no RBAC needed by the app); fault-injection
endpoints disabled unless `CLOUDPILOT_ENABLE_FAULT_INJECTION=true` and bounded; errors never leak internals; log-injection-safe request IDs; low-cardinality metric labels.

## Known limitations
No image signing/SBOM/admission policy; Actions pinned by tag not SHA; NetworkPolicy enforcement depends on the CNI; local Terraform state;
Argo CD initial admin secret should be removed after changing the password; Grafana/Prometheus only reachable via port-forward (intentional).
