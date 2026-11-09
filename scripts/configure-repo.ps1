# Usage: scripts\configure-repo.ps1 <github-username>   - replaces the placeholder (lower-cased for GHCR)
param([Parameter(Position = 0)][string]$GitHubUser)
. "$PSScriptRoot\lib\common.ps1"
if (-not $GitHubUser) { Stop-Fail 'Usage: scripts\configure-repo.ps1 <github-username>' }
if ($GitHubUser -notmatch '^[A-Za-z0-9-]+$') { Stop-Fail 'Invalid GitHub username.' }
$lower = $GitHubUser.ToLower()
$app = "$Root\gitops\argocd\application.yaml"; $vals = "$Root\gitops\environments\local\values.yaml"
(Get-Content $app -Raw).Replace('github.com/YOUR_GITHUB_USERNAME/', "github.com/$GitHubUser/") | Set-Content $app -NoNewline
(Get-Content $vals -Raw).Replace('ghcr.io/YOUR_GITHUB_USERNAME/', "ghcr.io/$lower/") | Set-Content $vals -NoNewline
if (Get-ChildItem -Path "$Root\gitops" -Recurse -File | Select-String -Pattern 'YOUR_GITHUB_USERNAME' -Quiet) { Write-Warn 'Some placeholders remain in gitops\' } else { Write-Ok 'Updated gitops\ files.' }
Write-Next "git add gitops; git commit -m 'chore: configure repo'; git push  - then make the GHCR package public (docs\GITOPS.md)"
