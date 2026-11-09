# Usage: scripts\rollback.ps1 git               revert the last GitOps image-tag commit (preferred under Argo CD)
#        scripts\rollback.ps1 helm [-Revision N] helm rollback (Mode 2/4, when Helm owns the release)
#        scripts\rollback.ps1 argocd            print the Argo CD rollback steps
param([Parameter(Mandatory = $true, Position = 0)][ValidateSet('git', 'helm', 'argocd')][string]$Method, [int]$Revision = 0, [switch]$Yes)
. "$PSScriptRoot\lib\common.ps1"
if ($Yes) { $env:CLOUDPILOT_ASSUME_YES = '1' }
switch ($Method) {
    'git' {
        Need git 'Install Git.'
        $f = 'gitops/environments/local/values.yaml'
        $sha = git -C $Root log -1 --format=%H -- $f
        if (-not $sha) { Stop-Fail "No commit touches $f" }
        git -C $Root log -1 --format='Last GitOps commit: %h %s (%cr)' $sha
        if (-not (Confirm-Action 'git revert this commit (creates a NEW commit; history is preserved)?')) { Write-Info 'Cancelled.'; exit 0 }
        Invoke-Checked { git -C $Root revert --no-edit $sha } 'git revert (conflict? resolve manually: git status)'
        if (Confirm-Action 'Push the revert to origin so Argo CD deploys it?') { Invoke-Checked { git -C $Root push origin HEAD } 'git push' } else { Write-Info 'Not pushed. Push when ready: git push' }
        Write-Next 'Wait for Argo CD (<=3 min) or Refresh in the UI, then scripts\verify-platform.ps1'
    }
    'helm' {
        Need helm 'Install Helm.'; Need kubectl 'Install kubectl.'; Use-Context
        if (-not (Test-Release)) { Stop-Fail "No Helm release '$Release'. (If Argo CD manages it, use: rollback.ps1 git)" }
        helm history $Release -n $AppNs
        $label = if ($Revision -gt 0) { "revision $Revision" } else { 'the previous revision' }
        if (-not (Confirm-Action "Roll back release '$Release' to $label?")) { Write-Info 'Cancelled.'; exit 0 }
        if ($Revision -gt 0) { Invoke-Checked { helm rollback $Release $Revision -n $AppNs --wait --timeout 3m } 'helm rollback' }
        else { Invoke-Checked { helm rollback $Release -n $AppNs --wait --timeout 3m } 'helm rollback' }
        Write-Ok 'Rolled back.'; Write-Next 'scripts\verify-platform.ps1'
    }
    'argocd' {
        Write-Host 'Argo CD rollback (UI or CLI) only works if auto-sync is OFF, otherwise self-heal re-applies Git:'
        Write-Host "  kubectl patch application $Release -n $ArgoNs --type merge -p '{`"spec`":{`"syncPolicy`":{`"automated`":null}}}'"
        Write-Host "  UI: Application -> History and Rollback -> pick revision -> Rollback   (or: argocd app rollback $Release <ID>)"
        Write-Host 'Then FIX GIT (preferred): scripts\rollback.ps1 git  - and re-enable auto-sync by re-applying gitops\argocd\application.yaml'
    }
}
