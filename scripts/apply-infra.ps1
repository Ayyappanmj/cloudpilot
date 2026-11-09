param([switch]$Yes)
. "$PSScriptRoot\lib\common.ps1"
if ($Yes) { $env:CLOUDPILOT_ASSUME_YES = '1' }
Need terraform 'Install: winget install Hashicorp.Terraform'; Need kubectl 'Install kubectl.'
Use-Context
Push-Location "$Root\infrastructure\terraform"
try {
    Invoke-Checked { terraform fmt -check -recursive } "terraform fmt (run 'terraform fmt -recursive')"
    Invoke-Checked { terraform init -input=false } 'terraform init (needs internet for the provider download)'
    Invoke-Checked { terraform validate } 'terraform validate'
    Invoke-Checked { terraform plan -input=false -out=tfplan } 'terraform plan'
    if (-not (Confirm-Action "Apply this plan to context $KubeContext?")) { Write-Info 'Cancelled.'; Remove-Item tfplan -ErrorAction SilentlyContinue; exit 0 }
    Invoke-Checked { terraform apply -input=false tfplan } 'terraform apply'
    Remove-Item tfplan -ErrorAction SilentlyContinue
} finally { Pop-Location }
kubectl get ns $AppNs $MonNs
kubectl get resourcequota,limitrange -n $AppNs
Write-Ok 'Foundation applied.'
Write-Next 'scripts\deploy-local.ps1'
