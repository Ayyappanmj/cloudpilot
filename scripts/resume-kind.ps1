param([switch]$Yes)
. "$PSScriptRoot\lib\common.ps1"
Need docker 'Install Docker Desktop.'; Need kubectl 'Install kubectl.'; Assert-Docker
if (-not (Test-ClusterExists)) { Stop-Fail 'Cluster does not exist. Run scripts\setup-kind.ps1' }
if (-not (Test-ClusterRunning)) { Invoke-Checked { docker start "$ClusterName-control-plane" } 'docker start' }
Use-Context
Invoke-Checked { kubectl wait --for=condition=Ready node --all --timeout=180s } 'Node Ready (if persistent: delete-kind then setup-kind)'
Write-Ok 'Cluster running.'
