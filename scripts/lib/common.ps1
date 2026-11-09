# Shared helpers. Dot-sourced by every scripts\*.ps1 file:  . "$PSScriptRoot\lib\common.ps1"
# 'Continue' on purpose: native tools (kubectl, helm...) write to stderr normally; we check $LASTEXITCODE explicitly.
$ErrorActionPreference = 'Continue'

$Root          = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$ScriptsDir    = Split-Path $PSScriptRoot -Parent
$ClusterName   = if ($env:CLOUDPILOT_CLUSTER) { $env:CLOUDPILOT_CLUSTER } else { 'cloudpilot' }
$KubeContext   = "kind-$ClusterName"
$AppNs = 'cloudpilot'; $MonNs = 'monitoring'; $ArgoNs = 'argocd'
$Release       = 'cloudpilot'
$ImageRepo     = 'cloudpilot-sample'
$ArgoCdVersion = if ($env:ARGOCD_VERSION)        { $env:ARGOCD_VERSION }        else { 'v2.13.2' }
$PromChartVer  = if ($env:PROM_CHART_VERSION)    { $env:PROM_CHART_VERSION }    else { '27.5.1' }
$GrafanaChartVer = if ($env:GRAFANA_CHART_VERSION) { $env:GRAFANA_CHART_VERSION } else { '8.9.0' }

function Write-Info($m) { Write-Host "[INFO] $m" }
function Write-Ok($m)   { Write-Host "[ OK ] $m" -ForegroundColor Green }
function Write-Warn($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Stop-Fail($m)  { Write-Host "[FAIL] $m" -ForegroundColor Red; exit 1 }
function Write-Next($m) { Write-Host ""; Write-Host "NEXT: $m" }

function Need($name, $hint) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) { Stop-Fail "'$name' is not installed or not on PATH. $hint" }
}
function Confirm-Action($prompt) {
    if ($env:CLOUDPILOT_ASSUME_YES -eq '1') { return $true }
    return ((Read-Host "$prompt [y/N]") -match '^[Yy]$')
}
# Runs a script block, returns $true when the native command exited 0. Output is hidden.
function Test-Ok([scriptblock]$Block) {
    try { $global:LASTEXITCODE = 0; & $Block *> $null; return ($LASTEXITCODE -eq 0) } catch { return $false }
}
# Runs a script block and aborts the script with a message if it fails.
function Invoke-Checked([scriptblock]$Block, $What) {
    $global:LASTEXITCODE = 0
    & $Block
    if ($LASTEXITCODE -ne 0) { Stop-Fail "$What failed (exit code $LASTEXITCODE)." }
}
function Assert-Docker {
    if (-not (Test-Ok { docker info })) { Stop-Fail "Docker is not running. Start Docker Desktop and wait until it says 'Engine running'." }
}
function Test-ClusterExists  { $c = kind get clusters 2>$null; return ($c -contains $ClusterName) }
function Test-ClusterRunning { $r = docker inspect -f '{{.State.Running}}' "$ClusterName-control-plane" 2>$null; return ($r -eq 'true') }
function Test-Ns($n)         { return (Test-Ok { kubectl get ns $n }) }
function Test-Release        { return (Test-Ok { helm status $Release -n $AppNs }) }
function Test-ArgoApp        { return (Test-Ok { kubectl get application $Release -n $ArgoNs }) }
function Use-Context {
    if (-not (Test-Ok { kubectl config use-context $KubeContext })) { Stop-Fail "kubectl context '$KubeContext' not found. Run scripts\setup-kind.ps1 first." }
    if (-not (Test-Ok { kubectl cluster-info })) { Stop-Fail "Cluster not reachable. If paused run scripts\resume-kind.ps1; otherwise check Docker Desktop." }
}
function Invoke-Sibling($name) {
    $global:LASTEXITCODE = 0
    & (Join-Path $ScriptsDir $name)
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
