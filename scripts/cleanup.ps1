# Safely stop optional services. Nothing is deleted without confirmation (or -Yes).
param([switch]$Monitoring, [switch]$Argocd, [switch]$Compose, [switch]$PauseCluster, [switch]$DockerPrune, [switch]$All, [switch]$Yes)
. "$PSScriptRoot\lib\common.ps1"
if ($Yes) { $env:CLOUDPILOT_ASSUME_YES = '1' }
Need docker 'Install Docker Desktop.'; Assert-Docker
if ($All) { $Monitoring = $true; $Argocd = $true; $Compose = $true; $DockerPrune = $true }
if (-not ($Monitoring -or $Argocd -or $Compose -or $PauseCluster -or $DockerPrune)) {
    Write-Host 'Usage: scripts\cleanup.ps1 [-Monitoring] [-Argocd] [-Compose] [-PauseCluster] [-DockerPrune] [-All] [-Yes]'
    Write-Host 'Currently running containers:'; docker ps --format '  {{.Names}}  {{.Status}}'; exit 0
}
if ($Monitoring) { Invoke-Sibling 'stop-monitoring.ps1' }
if ($Argocd)     { Invoke-Sibling 'stop-argocd.ps1' }
if ($Compose)    { Push-Location $Root; docker compose --profile monitoring down; if ($LASTEXITCODE -ne 0) { Write-Warn 'compose down failed' }; Pop-Location }
if ($PauseCluster) { Invoke-Sibling 'pause-kind.ps1' }
if ($DockerPrune) {
    if (Confirm-Action 'Remove dangling images and build cache older than 24h (named images are kept)?') {
        docker image prune -f; docker builder prune -f --filter until=24h
    }
}
Write-Ok 'Cleanup finished.'
