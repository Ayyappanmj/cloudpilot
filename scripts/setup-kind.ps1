param([switch]$Yes)
. "$PSScriptRoot\lib\common.ps1"
Need docker 'Install Docker Desktop: https://docs.docker.com/desktop/'
Need kind 'Install: winget install Kubernetes.kind'
Need kubectl 'Install: winget install Kubernetes.kubectl'
Assert-Docker

if (Test-ClusterExists) {
    Write-Warn "Kind cluster '$ClusterName' already exists - leaving it untouched (no overwrite)."
    if (-not (Test-ClusterRunning)) { Write-Warn 'It is stopped. Start it with scripts\resume-kind.ps1'; exit 0 }
} else {
    if (Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue) {
        Stop-Fail 'Host port 8080 is already in use. Free it or edit hostPort in kind\kind-config.yaml.'
    }
    Write-Info "Creating single-node Kind cluster '$ClusterName' (first run downloads the node image, ~1 GB)..."
    kind create cluster --config "$Root\kind\kind-config.yaml" --wait 180s
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'Troubleshooting: 1) docker info  2) give Docker Desktop >= 4 GB RAM (docs\HARDWARE_REQUIREMENTS.md)'
        Write-Host "                 3) kind export logs .\kind-logs --name $ClusterName"
        Stop-Fail 'Cluster creation failed.'
    }
}
Invoke-Checked { kubectl config use-context $KubeContext } 'kubectl use-context'
Invoke-Checked { kubectl wait --for=condition=Ready node --all --timeout=120s } 'Waiting for node Ready'
kubectl get nodes -o wide
Write-Ok "Cluster ready (context: $KubeContext)"
Write-Next 'scripts\apply-infra.ps1 (Terraform namespaces/quotas), then scripts\deploy-local.ps1'
