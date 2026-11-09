# Removes the Helm-installed app. Add -Cluster to also delete the Kind cluster.
param([switch]$Yes, [switch]$Cluster)
. "$PSScriptRoot\lib\common.ps1"
if ($Yes) { $env:CLOUDPILOT_ASSUME_YES = '1' }
Need kubectl 'Install kubectl.'; Need helm 'Install Helm.'
if ((Test-ClusterExists) -and (Test-ClusterRunning) -and (Test-Ok { kubectl config use-context $KubeContext })) {
    if (Test-Release) {
        if (-not (Confirm-Action "Uninstall Helm release '$Release' from namespace '$AppNs'?")) { Write-Info 'Cancelled.'; exit 0 }
        Invoke-Checked { helm uninstall $Release -n $AppNs } 'helm uninstall'
        Write-Ok 'Release removed.'
    } else { Write-Info "No Helm release '$Release' found." }
}
if ($Cluster) { Invoke-Sibling 'delete-kind.ps1' }
Write-Next 'scripts\cleanup.ps1 -All to stop optional services'
