# Stops the Kind node container to free ~0.7-1 GB RAM. Cluster state is kept.
param([switch]$Yes)
. "$PSScriptRoot\lib\common.ps1"
Need docker 'Install Docker Desktop.'; Assert-Docker
if (-not (Test-ClusterExists)) { Write-Info 'No cluster to pause.'; exit 0 }
if (-not (Test-ClusterRunning)) { Write-Info 'Already paused.'; exit 0 }
Invoke-Checked { docker stop "$ClusterName-control-plane" } 'docker stop'
Write-Ok 'Cluster paused.'
Write-Next 'scripts\resume-kind.ps1 when you need Kubernetes again'
