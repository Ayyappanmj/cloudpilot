#!/usr/bin/env bash
# Usage: scripts/rollback.sh git               revert the last GitOps image-tag commit (preferred under Argo CD)
#        scripts/rollback.sh helm [REVISION]   helm rollback (Mode 2/4, when Helm owns the release)
#        scripts/rollback.sh argocd            print the Argo CD rollback steps
source "$(dirname "$0")/lib/common.sh"
METHOD="${1:-}"
case "$METHOD" in
  git)
    need git "Install Git."
    F="gitops/environments/local/values.yaml"
    SHA="$(git -C "$ROOT" log -1 --format=%H -- "$F")"; [[ -n "$SHA" ]] || die "No commit touches $F"
    git -C "$ROOT" log -1 --format='Last GitOps commit: %h %s (%cr)' "$SHA"
    confirm "git revert this commit (creates a NEW commit; history is preserved)?" || { info "Cancelled."; exit 0; }
    git -C "$ROOT" revert --no-edit "$SHA" || die "Revert failed (conflict?). Resolve manually: git status"
    confirm "Push the revert to origin so Argo CD deploys it?" && git -C "$ROOT" push origin HEAD || info "Not pushed. Push when ready: git push"
    next "Wait for Argo CD (<=3 min) or Refresh in the UI, then scripts/verify-platform.sh";;
  helm)
    need helm "Install Helm."; need kubectl "Install kubectl."; use_ctx
    release_exists || die "No Helm release '$RELEASE'. (If Argo CD manages it, use: $0 git)"
    helm history "$RELEASE" -n "$APP_NS"
    REV="${2:-}"; [[ "$REV" != --* ]] || REV=""
    confirm "Roll back release '$RELEASE' to ${REV:-the previous revision}?" || { info "Cancelled."; exit 0; }
    helm rollback "$RELEASE" ${REV:+"$REV"} -n "$APP_NS" --wait --timeout 3m || die "helm rollback failed"
    ok "Rolled back."; next "scripts/verify-platform.sh";;
  argocd)
    cat <<TXT
Argo CD rollback (UI or CLI) only works if auto-sync is OFF, otherwise self-heal re-applies Git:
  kubectl patch application $RELEASE -n $ARGO_NS --type merge -p '{"spec":{"syncPolicy":{"automated":null}}}'
  UI: Application -> History and Rollback -> pick revision -> Rollback     (or: argocd app rollback $RELEASE <ID>)
Then FIX GIT (preferred): scripts/rollback.sh git   - and re-enable auto-sync by re-applying gitops/argocd/application.yaml
TXT
    ;;
  *) die "Usage: $0 git | helm [REVISION] | argocd";;
esac
