# Usage: scripts\switch-mode.ps1 <1|2|3|4|5|dev|kubernetes|gitops|monitoring|complete> [-Yes]
param([Parameter(Mandatory = $true, Position = 0)][string]$ModeName, [switch]$Yes)
. "$PSScriptRoot\lib\common.ps1"
if ($Yes) { $env:CLOUDPILOT_ASSUME_YES = '1' }
Need docker 'Install Docker Desktop.'; Assert-Docker
switch -Regex ($ModeName) {
    '^(1|dev|development)$'    { $Mode = 1 }
    '^(2|kubernetes|k8s)$'     { $Mode = 2 }
    '^3$|^gitops$'             { $Mode = 3 }
    '^(4|monitoring)$'         { $Mode = 4 }
    '^(5|complete|full)$'      { $Mode = 5 }
    default { Stop-Fail 'Usage: switch-mode.ps1 <1-5|dev|kubernetes|gitops|monitoring|complete>' }
}
Write-Info "Switching to MODE $Mode"
& "$ScriptsDir\check-resources.ps1" -Mode $Mode
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

function Ensure-Cluster {
    if (-not (Test-ClusterExists)) { Invoke-Sibling 'setup-kind.ps1' } elseif (-not (Test-ClusterRunning)) { Invoke-Sibling 'resume-kind.ps1' }
    Use-Context
}
function Ensure-Infra { if (-not ((Test-Ns $AppNs) -and (Test-Ns $MonNs))) { Invoke-Sibling 'apply-infra.ps1' } }
function Stop-ComposeAll { Push-Location $Root; docker compose --profile monitoring down *> $null; Pop-Location }

switch ($Mode) {
    1 {
        if (Test-ClusterRunning) { Use-Context; Invoke-Sibling 'stop-monitoring.ps1'; Invoke-Sibling 'stop-argocd.ps1' }
        Invoke-Sibling 'pause-kind.ps1'
        Push-Location $Root
        docker compose --profile monitoring down *> $null
        docker compose up -d --build
        $rc = $LASTEXITCODE; Pop-Location
        if ($rc -ne 0) { Stop-Fail 'compose failed (is .env present? copy .env.example .env)' }
        Write-Ok 'MODE 1 ready: http://localhost:8000/docs   Tests: pytest'
    }
    2 { Stop-ComposeAll; Ensure-Cluster; Ensure-Infra; Invoke-Sibling 'stop-monitoring.ps1'; Invoke-Sibling 'stop-argocd.ps1'; Invoke-Sibling 'deploy-local.ps1' }
    3 { Push-Location $Root; docker compose down *> $null; Pop-Location
        Ensure-Cluster; Ensure-Infra; Invoke-Sibling 'stop-monitoring.ps1'
        if (Test-Release) { Invoke-Sibling 'destroy-local.ps1' }
        Invoke-Sibling 'setup-argocd.ps1' }
    4 { Stop-ComposeAll; Ensure-Cluster; Ensure-Infra; Invoke-Sibling 'stop-argocd.ps1'; Invoke-Sibling 'deploy-local.ps1'; Invoke-Sibling 'start-monitoring.ps1' }
    5 { Stop-ComposeAll; Ensure-Cluster; Ensure-Infra
        if (Test-Release) { Invoke-Sibling 'destroy-local.ps1' }
        if (-not (Test-ArgoApp)) { Invoke-Sibling 'setup-argocd.ps1' }
        Invoke-Sibling 'start-monitoring.ps1' }
}
Write-Next 'scripts\verify-platform.ps1'
