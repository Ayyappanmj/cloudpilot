# MODE 4: Prometheus + Grafana in Kind (low-spec). Start only when you need dashboards.
param([switch]$Yes)
. "$PSScriptRoot\lib\common.ps1"
Need kubectl 'Install kubectl.'; Need helm 'Install Helm.'
Use-Context
if (-not (Test-Ns $MonNs)) { Stop-Fail "Namespace '$MonNs' missing. Run scripts\apply-infra.ps1 first." }
if (Get-Command docker -ErrorAction SilentlyContinue) {
    if (docker ps -q --filter name=cloudpilot-prometheus 2>$null) { Stop-Fail 'Compose monitoring is running. Stop it first: docker compose --profile monitoring down' }
}
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts | Out-Null
helm repo add grafana https://grafana.github.io/helm-charts | Out-Null
Invoke-Checked { helm repo update } 'helm repo update (internet?)'

Write-Info "Installing Prometheus chart $PromChartVer"
$alerts = "$Root\monitoring\alerts\cloudpilot-alerts.yml"
Invoke-Checked { helm upgrade --install prometheus prometheus-community/prometheus -n $MonNs --version $PromChartVer -f "$Root\monitoring\prometheus\values-lowspec.yaml" --set-file "serverFiles.alerting_rules\.yml=$alerts" --wait --timeout 5m } 'Prometheus install (unknown chart version? run: helm search repo prometheus-community/prometheus --versions, then set $env:PROM_CHART_VERSION)'

Write-Info 'Provisioning dashboard ConfigMap'
$dash = "$Root\monitoring\grafana\dashboards\cloudpilot-dashboard.json"
kubectl create configmap cloudpilot-dashboard -n $MonNs "--from-file=cloudpilot-dashboard.json=$dash" --dry-run=client -o yaml | kubectl apply -f -
if ($LASTEXITCODE -ne 0) { Stop-Fail 'Dashboard ConfigMap failed' }

Write-Info "Installing Grafana chart $GrafanaChartVer"
Invoke-Checked { helm upgrade --install grafana grafana/grafana -n $MonNs --version $GrafanaChartVer -f "$Root\monitoring\grafana\values-lowspec.yaml" --wait --timeout 5m } 'Grafana install (check: helm search repo grafana/grafana --versions)'

Write-Ok 'Monitoring is up.'
Write-Host "Prometheus: kubectl port-forward -n $MonNs svc/prometheus-server 9090:80     -> http://localhost:9090"
Write-Host "Grafana:    kubectl port-forward -n $MonNs svc/grafana 3000:80               -> http://localhost:3000"
Write-Host 'Grafana user: admin   password (PowerShell):'
Write-Host "  [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String((kubectl get secret grafana -n $MonNs -o jsonpath='{.data.admin-password}')))"
Write-Next 'Generate traffic: curl.exe http://localhost:8080/ ; curl.exe http://localhost:8080/api/v1/simulate-error'
