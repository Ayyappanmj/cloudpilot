# MODE 2: build the image locally, load it into Kind, install the Helm chart. No registry needed.
param([switch]$Yes)
. "$PSScriptRoot\lib\common.ps1"
Need docker 'Install Docker Desktop.'; Need kind 'Install Kind.'; Need kubectl 'Install kubectl.'; Need helm 'Install: winget install Helm.Helm'
Assert-Docker; Use-Context
if (-not (Test-Ns $AppNs)) { Stop-Fail "Namespace '$AppNs' missing. Run scripts\apply-infra.ps1 first (Terraform owns namespaces)." }
if ((Test-Ok { kubectl get crd applications.argoproj.io }) -and (Test-ArgoApp)) {
    Stop-Fail "Argo CD currently manages '$Release'. Run scripts\stop-argocd.ps1 first (one owner per app)."
}
$Tag = 'local-' + (Get-Date -Format 'yyyyMMddHHmmss')
$Sha = git -C $Root rev-parse --short HEAD 2>$null; if ($LASTEXITCODE -ne 0 -or -not $Sha) { $Sha = 'local' }
Write-Info "Building ${ImageRepo}:$Tag"
Invoke-Checked { docker build -f "$Root\docker\Dockerfile" --build-arg "GIT_COMMIT=$Sha" -t "${ImageRepo}:$Tag" $Root } 'docker build'
Write-Info 'Loading image into Kind'
Invoke-Checked { kind load docker-image "${ImageRepo}:$Tag" --name $ClusterName } 'kind load'
Write-Info 'helm upgrade --install'
Invoke-Checked { helm upgrade --install $Release "$Root\deploy\helm\cloudpilot" -n $AppNs -f "$Root\deploy\helm\cloudpilot\values-local.yaml" --set "image.tag=$Tag" --wait --timeout 3m } "helm (debug: kubectl get pods -n $AppNs ; kubectl describe pod -n $AppNs)"
kubectl get pods -n $AppNs
Write-Ok 'Deployed. Open http://localhost:8080  (docs: http://localhost:8080/docs)'
Write-Next 'scripts\verify-platform.ps1'
