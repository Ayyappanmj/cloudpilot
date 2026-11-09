#!/usr/bin/env bash
# Usage: scripts/configure-repo.sh <github-username>   - replaces YOUR_GITHUB_USERNAME (lower-cased for GHCR)
source "$(dirname "$0")/lib/common.sh"
USER_IN="${1:-}"; [[ -n "$USER_IN" && "$USER_IN" != --* ]] || die "Usage: $0 <github-username>"
[[ "$USER_IN" =~ ^[A-Za-z0-9-]+$ ]] || die "Invalid GitHub username."
LOWER="$(echo "$USER_IN" | tr '[:upper:]' '[:lower:]')"
sed -i "s|github.com/YOUR_GITHUB_USERNAME/|github.com/${USER_IN}/|g" "$ROOT/gitops/argocd/application.yaml"
sed -i "s|ghcr.io/YOUR_GITHUB_USERNAME/|ghcr.io/${LOWER}/|g" "$ROOT/gitops/environments/local/values.yaml"
if grep -rq "YOUR_GITHUB_USERNAME" "$ROOT/gitops"; then warn "Some placeholders remain in gitops/"; else ok "Updated gitops/ files."; fi
next "git add gitops && git commit -m 'chore: configure repo' && git push, then make the GHCR package public (docs/GITOPS.md)"
