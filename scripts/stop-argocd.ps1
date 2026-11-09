# Removes Argo CD AND the Application (which deletes the resources it deployed, via its finalizer).
param([switch]$Yes)
. "$PSScriptRoot\lib\common.ps1"
if ($Yes) { $env:CLOUDPILOT_ASSUME_YES = '1' }
Need kubectl 'Install kubectl.'
if (-not ((Test-ClusterExists) -and (Test-ClusterRunning))) { Write-Info 'Cluster not running. Nothing to stop.'; exit 0 }
Use-Context
if (-not (Test-Ns $ArgoNs)) { Write-Info 'Argo CD is not installed.'; exit 0 }
if (-not (Confirm-Action "Remove Argo CD and the '$Release' Application (this also removes the app it deployed)?")) { Write-Info 'Cancelled.'; exit 0 }
kubectl delete application $Release -n $ArgoNs --ignore-not-found --timeout=120s
if ($LASTEXITCODE -ne 0) { Write-Warn 'Application delete timed out' }
Invoke-Checked { kubectl delete namespace $ArgoNs --timeout=180s } "delete namespace $ArgoNs"
kubectl delete crd applications.argoproj.io applicationsets.argoproj.io appprojects.argoproj.io --ignore-not-found
Write-Ok 'Argo CD removed.'
Write-Next 'scripts\deploy-local.ps1 to run the app without GitOps'
