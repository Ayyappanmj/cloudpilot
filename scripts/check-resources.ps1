# Usage: scripts\check-resources.ps1 [-Mode 1..5]   Exits non-zero if Docker has too little RAM for that mode.
param([ValidateRange(0, 5)][int]$Mode = 0)
. "$PSScriptRoot\lib\common.ps1"
Need docker 'Install Docker Desktop.'; Assert-Docker
$memGiB = [math]::Round([double](docker info --format '{{.MemTotal}}') / 1GB, 1)
$cpus   = [int](docker info --format '{{.NCPU}}')
$drive  = (Split-Path $Root -Qualifier).TrimEnd(':')
$diskGiB = [math]::Round((Get-PSDrive -Name $drive).Free / 1GB, 0)
Write-Host "Docker memory: $memGiB GiB | Docker CPUs: $cpus | Free disk on ${drive}: $diskGiB GiB"
$need = @{ 1 = 1.5; 2 = 3.0; 3 = 3.5; 4 = 3.5; 5 = 4.5 }
if ($Mode -eq 0) {
    foreach ($m in 1..5) { if ($memGiB -ge $need[$m]) { Write-Host "Mode $m (needs ~$($need[$m]) GiB): OK" } else { Write-Host "Mode $m (needs ~$($need[$m]) GiB): NOT ENOUGH" } }
    exit 0
}
if ($memGiB -lt $need[$Mode]) { Stop-Fail "Mode $Mode needs about $($need[$Mode]) GiB for Docker; you have $memGiB. Raise it in .wslconfig (docs\HARDWARE_REQUIREMENTS.md) or use a lighter mode." }
if ($diskGiB -lt 10) { Write-Warn "Only $diskGiB GiB free disk; images and the Kind node need ~6-8 GiB." }
Write-Ok "Mode $Mode is feasible with current Docker settings."
