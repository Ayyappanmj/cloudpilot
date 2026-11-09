# Interview questions (with fresher-level answers)

## Linux
1. **How do you see running processes?** `ps aux`, `top`/`htop`; `kill <pid>` sends SIGTERM (graceful), `kill -9` SIGKILL (forced).
2. **Explain `chmod 640 file`.** Owner read/write, group read, others nothing. Permissions are owner/group/other with r=4, w=2, x=1.
3. **How do you check which process uses port 8080?** `ss -ltnp | grep 8080` (Linux) or `Get-NetTCPConnection -LocalPort 8080` (PowerShell).
4. **Where do you look at logs?** `journalctl -u <service>`, `/var/log/`, `tail -f`; in containers `docker logs` / `kubectl logs`.
5. **Why `set -euo pipefail` in shell scripts?** Exit on error, on unset variables, and on failures inside pipes - so failures are not silently ignored (our scripts do this).

## Docker
6. **Image vs container?** Image = read-only template; container = running instance with a writable layer.
7. **Why multi-stage builds?** Build tools stay in the first stage; the final image is smaller with fewer vulnerabilities.
8. **How is our Dockerfile hardened?** Slim base, non-root numeric UID, no extra packages, pinned deps, health check, no secrets.
9. **How do containers talk to each other?** Same user-defined network (Compose) resolves service names via DNS; ports are published to the host only when needed.
10. **CMD vs ENTRYPOINT?** ENTRYPOINT is the fixed executable, CMD the default arguments (overridable).

## Kubernetes
11. **Pod?** Smallest deployable unit: one or more containers sharing network and storage.
12. **Deployment vs ReplicaSet?** Deployment manages ReplicaSets to provide rolling updates and rollbacks.
13. **Service types?** ClusterIP (internal), NodePort (port on each node - used with Kind), LoadBalancer (cloud).
14. **ConfigMap vs Secret?** Both inject config; Secrets are base64-encoded (not encrypted by default) and need RBAC/encryption-at-rest protection.
15. **Three probes?** Startup (slow starts), liveness (restart if dead), readiness (receive traffic or not). `/healthz` vs `/readyz` here.
16. **What does HPA need?** metrics-server and CPU/memory requests; scales replicas on utilisation.
17. **Requests vs limits?** Request = scheduler guarantee; limit = ceiling (CPU throttled, memory OOMKilled).
18. **CrashLoopBackOff?** Container keeps exiting; check `kubectl logs --previous` and `describe pod`. Example: invalid env fails startup validation.
19. **ImagePullBackOff?** Wrong image/tag, registry auth missing, or private package.
20. **What is a PodDisruptionBudget?** Limits voluntary disruptions; with 1 replica `minAvailable: 1` blocks drains, so we use `maxUnavailable`.
21. **What does the quota do in our namespace?** Caps total requests/limits/pods so one namespace can't starve the laptop.

## Terraform
22. **Provider/resource?** Provider talks to an API (Kubernetes); resource is an object it manages (namespace).
23. **What is state?** Terraform's record of what it created; mapping config to real objects. Never commit it; use a remote backend with locking in teams.
24. **plan vs apply?** plan previews changes; apply performs them. Always review the plan.
25. **Drift?** Real infra differs from state/config; `plan` reveals it, `apply` reconciles.
26. **Variables vs outputs vs modules?** Inputs, exposed results, reusable bundles of resources.
27. **Why not let Terraform manage the Deployment too?** Argo CD already owns it; two controllers would fight. Clear ownership boundaries.

## CI/CD
28. **CI vs CD?** CI: merge often, build/test automatically. CD: automatically deliver/deploy validated artifacts.
29. **Why immutable commit-SHA tags?** Exactly traceable, rollback-safe; `latest` can change under you.
30. **Why not publish from pull requests?** Untrusted code could abuse write tokens; PR runs get read-only permissions.
31. **How do you avoid pipeline loops?** `[skip ci]`, `paths-ignore`, and `GITHUB_TOKEN` commits not retriggering workflows.
32. **How do you roll back?** Revert the Git commit that changed the image tag; the pipeline/Argo redeploys the old version.
33. **What are artifacts?** Build outputs kept by the pipeline (JUnit reports; container images in GHCR).

## GitOps
34. **GitOps principles?** Declarative desired state in Git, versioned and auditable, automatically pulled and continuously reconciled.
35. **Argo CD role?** Compares Git with the cluster and syncs differences.
36. **Self-heal vs prune?** Self-heal reverts manual cluster changes; prune deletes resources removed from Git.
37. **Push vs pull deployment?** Push: CI holds cluster credentials. Pull: an in-cluster agent fetches; no cluster credentials in CI - safer.
38. **Why does Argo CD rollback conflict with auto-sync?** Git still describes the new version, so Argo re-applies it; fix Git instead.

## Monitoring
39. **Prometheus model?** Pull-based time-series database scraping `/metrics` with labels.
40. **Counter vs gauge vs histogram?** Counter only increases (requests), gauge goes up/down (in-progress), histogram buckets observations (latency).
41. **Why `rate()` on counters?** Counters are cumulative; `rate` gives per-second change.
42. **How is p95 latency computed?** `histogram_quantile(0.95, sum by (le) (rate(..._bucket[5m])))`.
43. **Why avoid high-cardinality labels?** Each label combination is a series that costs memory; we label by route template, not raw URL.
44. **Alert design?** Alert on symptoms (errors, latency, down) with a `for:` duration to avoid flapping.

## Security
45. **What does Trivy do?** Scans images, filesystems and IaC for known CVEs, secrets and misconfiguration.
46. **Why non-root and read-only FS?** An exploited process has fewer powers and can't persist changes.
47. **Least privilege here?** Per-job workflow permissions, no service-account token, dropped capabilities, quotas.
48. **Kubernetes RBAC?** Roles grant verbs on resources to subjects via bindings; our app needs none.
49. **Do we block every vulnerability?** We block fixable CRITICAL/HIGH; unfixable ones remain visible in SARIF and are tracked - not hidden.
50. **Why is a green scan not "secure"?** Scanners find known CVEs only.
