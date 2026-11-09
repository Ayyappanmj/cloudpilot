# Removes Prometheus + Grafana (frees ~0.5-0.8 GB). The 'monitoring' namespace stays (Terraform owns it).
param([switch]$Yes)
. "$PSScriptRoot\lib\common.ps1"
Need kubectl 'Install kubectl.'; Need helm 'Install Helm.'
if (-not ((Test-ClusterExists) -and (Test-ClusterRunning))) { Write-Info 'Cluster not running. Nothing to stop.'; exit 0 }
Use-Context
if (-not (Test-Ns $MonNs)) { Write-Info 'No monitoring namespace.'; exit 0 }
foreach ($r in 'grafana', 'prometheus') {
    if (Test-Ok { helm status $r -n $MonNs }) { Invoke-Checked { helm uninstall $r -n $MonNs } "uninstall $r" }
}
kubectl delete configmap cloudpilot-dashboard -n $MonNs --ignore-not-found
Write-Ok 'Monitoring stopped.'
