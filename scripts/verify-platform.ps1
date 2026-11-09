# Verifies whatever is currently deployed (mode-aware). Exits non-zero on any failed check.
. "$PSScriptRoot\lib\common.ps1"
Need kubectl 'Install kubectl.'
$script:Fails = 0
function Check($desc, [scriptblock]$block) {
    if (Test-Ok $block) { Write-Ok $desc } else { Write-Host "[FAIL] $desc" -ForegroundColor Red; $script:Fails++ }
}
$lbl = 'app.kubernetes.io/name=cloudpilot'
function Jp($path) { return (kubectl get deploy -n $AppNs -l $lbl -o "jsonpath=$path") }

if (-not ((Test-Ok { kubectl config use-context $KubeContext }) -and (Test-Ok { kubectl cluster-info }))) {
    Stop-Fail 'Cluster unreachable: scripts\resume-kind.ps1 or scripts\setup-kind.ps1'
}
Write-Ok "kubectl context $KubeContext reachable"
Check 'node Ready' { if ((kubectl get nodes --no-headers) -match ' Ready') { cmd /c exit 0 } else { cmd /c exit 1 } }
Check "namespace $AppNs exists" { kubectl get ns $AppNs }
Check 'ResourceQuota present (Terraform)' { if (kubectl get resourcequota -n $AppNs --no-headers) { cmd /c exit 0 } else { cmd /c exit 1 } }

if (kubectl get deploy -n $AppNs -l $lbl --no-headers 2>$null) {
    Check 'deployment Available' { kubectl wait --for=condition=Available deploy -l $lbl -n $AppNs --timeout=30s }
    Check 'pods Running' { if ((kubectl get pods -n $AppNs -l $lbl --no-headers) -match '\sRunning\s') { cmd /c exit 0 } else { cmd /c exit 1 } }
    Check 'service exists' { kubectl get svc -n $AppNs -l $lbl }
    Check 'memory limit set' { if (Jp '{.items[0].spec.template.spec.containers[0].resources.limits.memory}') { cmd /c exit 0 } else { cmd /c exit 1 } }
    Check 'runs as non-root' { if ((Jp '{.items[0].spec.template.spec.securityContext.runAsNonRoot}') -eq 'true') { cmd /c exit 0 } else { cmd /c exit 1 } }
    Check 'readiness+liveness probes set' { if ((Jp '{.items[0].spec.template.spec.containers[0].readinessProbe.httpGet.path}') -and (Jp '{.items[0].spec.template.spec.containers[0].livenessProbe.httpGet.path}')) { cmd /c exit 0 } else { cmd /c exit 1 } }
    foreach ($p in '/healthz', '/readyz') {
        Check "GET $p (localhost:8080)" { $r = Invoke-WebRequest -UseBasicParsing -TimeoutSec 5 "http://localhost:8080$p"; if ($r.StatusCode -eq 200) { cmd /c exit 0 } else { cmd /c exit 1 } }
    }
    Check 'GET /metrics exposes cloudpilot_app_info' { $r = Invoke-WebRequest -UseBasicParsing -TimeoutSec 5 'http://localhost:8080/metrics'; if ($r.Content -match 'cloudpilot_app_info') { cmd /c exit 0 } else { cmd /c exit 1 } }
} else {
    Write-Warn 'Application not deployed (fine for Mode 1). Deploy with scripts\deploy-local.ps1 or setup-argocd.ps1'
}

if ((Test-Ns $ArgoNs) -and (Test-ArgoApp)) {
    Check 'Argo CD app Synced'  { if ((kubectl get application $Release -n $ArgoNs -o 'jsonpath={.status.sync.status}') -eq 'Synced') { cmd /c exit 0 } else { cmd /c exit 1 } }
    Check 'Argo CD app Healthy' { if ((kubectl get application $Release -n $ArgoNs -o 'jsonpath={.status.health.status}') -eq 'Healthy') { cmd /c exit 0 } else { cmd /c exit 1 } }
}
if (Test-Ok { kubectl get deploy prometheus-server -n $MonNs }) {
    Check 'Prometheus Available' { kubectl wait --for=condition=Available deploy/prometheus-server -n $MonNs --timeout=30s }
    Check 'Grafana Available'    { kubectl wait --for=condition=Available deploy/grafana -n $MonNs --timeout=30s }
}
Write-Host ''
if ($script:Fails -eq 0) { Write-Ok 'All checks passed.' } else { Write-Host "[FAIL] $($script:Fails) check(s) failed. See docs\TROUBLESHOOTING.md" -ForegroundColor Red; exit 1 }
