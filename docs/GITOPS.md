# GitOps with Argo CD

## Setup (once)
```powershell
scripts\configure-repo.ps1 <your-github-username>   # fills repoURL + GHCR path
git add gitops; git commit -m "chore: configure repo"; git push
# make the GHCR package public after the first CI run (docs/CI_CD.md)
scripts\setup-argocd.ps1                             # Mode 3: installs Argo CD (trimmed) + Application
```
Argo CD reads `deploy/helm/cloudpilot` with `gitops/environments/local/values.yaml` on top (relative `valueFiles` path - allowed
because it stays inside the same repo). `automated.prune` removes deleted resources; `selfHeal` reverts manual `kubectl` edits.
Argo polls Git about every 3 minutes; click **Refresh** for an immediate check.

## Normal flow
`git push` -> Actions builds `sha-<12>` image -> bot commits `image.tag` -> Argo syncs -> rolling update (`maxUnavailable: 0`).
Watch: `kubectl get application cloudpilot -n argocd -w` and `kubectl rollout status deploy/cloudpilot -n cloudpilot`.

## Rollback
1. **Preferred - Git revert:** `scripts\rollback.ps1 git` (reverts the last commit touching the values file, optionally pushes).
   Git stays the source of truth and the audit trail shows who reverted what.
2. **Argo CD rollback:** UI > History and Rollback, or `argocd app rollback`. With `automated` sync enabled Argo refuses/undoes it
   because Git no longer matches. Disable auto-sync first (`scripts\rollback.ps1 argocd` prints the command), then **fix Git**
   and re-enable auto-sync by re-applying `gitops/argocd/application.yaml`. Treat this as an emergency stop-gap only.
3. Helm rollback (`scripts\rollback.ps1 helm`) applies only when Helm - not Argo CD - owns the release (Modes 2/4).

## Private GHCR image (only if you keep the package private)
```powershell
kubectl create secret docker-registry ghcr-pull -n cloudpilot --docker-server=ghcr.io --docker-username=<user> --docker-password=<PAT with read:packages>
```
Then set `imagePullSecrets: [{name: ghcr-pull}]` in `gitops/environments/local/values.yaml`. Never commit the token; the secret lives only in the cluster.
Private *repo* for Argo: `argocd repo add https://github.com/<user>/cloudpilot.git --username <user> --password <PAT>` (read-only PAT).

## Ownership
Terraform creates namespaces, so the Application deliberately omits `CreateNamespace=true`.
