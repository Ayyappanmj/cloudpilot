param([switch]$Yes)
. "$PSScriptRoot\lib\common.ps1"
if ($Yes) { $env:CLOUDPILOT_ASSUME_YES = '1' }
Need kind 'Install Kind first.'
if (-not (Test-ClusterExists)) { Write-Info "Cluster '$ClusterName' does not exist. Nothing to do."; exit 0 }
if (-not (Confirm-Action "Delete Kind cluster '$ClusterName' and everything in it?")) { Write-Info 'Cancelled.'; exit 0 }
Invoke-Checked { kind delete cluster --name $ClusterName } 'kind delete'
Write-Ok 'Deleted. If you used Terraform, also delete infrastructure\terraform\terraform.tfstate*'
Write-Next 'scripts\setup-kind.ps1 to recreate it'
