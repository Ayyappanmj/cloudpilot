# Publishing to GitHub

```powershell
git init -b main
git add .
git commit -m "feat: initial CloudPilot platform"
# create an empty PUBLIC repo named cloudpilot on github.com, then:
git remote add origin https://github.com/<user>/cloudpilot.git
git push -u origin main
scripts\configure-repo.ps1 <user>; git add gitops; git commit -m "chore: configure repo"; git push
```
**Manual steps that cannot be automated:** (1) create the repo; (2) check the first Actions run; (3) set the GHCR package to Public;
(4) adjust branch protection so `github-actions[bot]` can push the GitOps commit; (5) optional: add repo description/topics; (6) capture real screenshots.

- **Description:** An end-to-end DevOps platform demonstrating automated CI/CD, Docker image security scanning, Terraform-managed Kubernetes infrastructure, Argo CD GitOps deployments, and Prometheus-Grafana observability.
- **Topics:** devops, cloud-engineering, kubernetes, kind, argocd, gitops, github-actions, terraform, helm, prometheus, grafana, trivy, fastapi, docker, ghcr, ci-cd
- **Resume entry (truthful, no invented metrics):**
  *CloudPilot - CI/CD & GitOps Platform (personal project).* Built a local Kubernetes (Kind) delivery pipeline: GitHub Actions (lint, tests, Trivy scans, GHCR publishing),
  Argo CD GitOps deployments of a Helm chart, Terraform-managed namespaces/quotas, and Prometheus/Grafana monitoring with alert rules. Added resource-aware operating modes for an
  8 GB laptop, Bash/PowerShell automation, and documented failure drills and rollback procedures.
- Do not claim cloud/AWS deployment, high availability, or production traffic - none of it exists here.
