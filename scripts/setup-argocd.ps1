# MODE 3: install Argo CD (trimmed) and create the Application.
param([switch]$Yes)
. "$PSScriptRoot\lib\common.ps1"
Need kubectl 'Install kubectl.'; Need helm 'Install Helm (used to detect conflicting releases).'
Use-Context
$AppFile = "$Root\gitops\argocd\application.yaml"
if (Select-String -Path $AppFile, "$Root\gitops\environments\local\values.yaml" -Pattern 'YOUR_GITHUB_USERNAME' -Quiet) {
    Stop-Fail 'Placeholders not replaced. Run: scripts\configure-repo.ps1 <github-user>  then commit and push.'
}
if (-not (Test-Ns $AppNs)) { Stop-Fail "Namespace '$AppNs' missing. Run scripts\apply-infra.ps1 first." }
if (Test-Release) { Stop-Fail "Helm release '$Release' exists. Run scripts\destroy-local.ps1 first (one owner per app)." }

Write-Info "Installing Argo CD $ArgoCdVersion (needs internet)"
if (-not (Test-Ns $ArgoNs)) { Invoke-Checked { kubectl create namespace $ArgoNs } 'create namespace' }
Invoke-Checked { kubectl apply -n $ArgoNs --server-side --force-conflicts -f "https://raw.githubusercontent.com/argoproj/argo-cd/$ArgoCdVersion/manifests/install.yaml" } 'apply Argo CD manifests (internet? valid ARGOCD_VERSION?)'
Write-Info 'Scaling down components this demo does not need (saves RAM): dex, notifications, applicationset'
kubectl scale deployment argocd-dex-server argocd-notifications-controller argocd-applicationset-controller -n $ArgoNs --replicas=0
if ($LASTEXITCODE -ne 0) { Write-Warn 'Could not scale down optional components' }
Invoke-Checked { kubectl rollout status deployment/argocd-server -n $ArgoNs --timeout=300s } 'argocd-server ready'
Invoke-Checked { kubectl rollout status deployment/argocd-repo-server -n $ArgoNs --timeout=300s } 'argocd-repo-server ready'
Invoke-Checked { kubectl rollout status statefulset/argocd-application-controller -n $ArgoNs --timeout=300s } 'application-controller ready'
Invoke-Checked { kubectl wait --for condition=established crd/applications.argoproj.io --timeout=60s } 'Application CRD established'
Invoke-Checked { kubectl apply -f $AppFile } 'apply Application'
Write-Ok 'Argo CD installed and Application created.'
Write-Host "UI:        kubectl port-forward svc/argocd-server -n $ArgoNs 8081:443   ->  https://localhost:8081"
Write-Host 'Username:  admin'
Write-Host 'Password (PowerShell):'
Write-Host "  [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String((kubectl -n $ArgoNs get secret argocd-initial-admin-secret -o jsonpath='{.data.password}')))"
Write-Host "Status:    kubectl get application $Release -n $ArgoNs"
Write-Next 'scripts\verify-platform.ps1   (Argo polls Git about every 3 minutes; use Refresh in the UI to speed up)'
