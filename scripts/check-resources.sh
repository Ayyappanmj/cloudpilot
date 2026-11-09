#!/usr/bin/env bash
# Usage: scripts/check-resources.sh [1-5]   Exits non-zero if Docker has too little RAM for that mode.
source "$(dirname "$0")/lib/common.sh"
need docker "Install Docker Desktop."; docker_up
MODE="${1:-}"
MEM_GIB="$(docker info --format '{{.MemTotal}}' | awk '{printf "%.1f", $1/1073741824}')"
CPUS="$(docker info --format '{{.NCPU}}')"
DISK_GIB="$(df -Pk "$ROOT" | awk 'NR==2{printf "%.0f", $4/1048576}')"
echo "Docker memory: ${MEM_GIB} GiB | Docker CPUs: ${CPUS} | Free disk here: ${DISK_GIB} GiB"
declare -A NEED=([1]=1.5 [2]=3.0 [3]=3.5 [4]=3.5 [5]=4.5)
if [[ -z "$MODE" || "$MODE" == --* ]]; then
  for m in 1 2 3 4 5; do
    if awk "BEGIN{exit !(${MEM_GIB} >= ${NEED[$m]})}"; then echo "Mode $m (needs ~${NEED[$m]} GiB): OK"; else echo "Mode $m (needs ~${NEED[$m]} GiB): NOT ENOUGH"; fi
  done
  exit 0
fi
[[ -n "${NEED[$MODE]:-}" ]] || die "Mode must be 1-5"
awk "BEGIN{exit !(${MEM_GIB} >= ${NEED[$MODE]})}" || die "Mode $MODE needs about ${NEED[$MODE]} GiB for Docker; you have ${MEM_GIB}. Raise it in .wslconfig (docs/HARDWARE_REQUIREMENTS.md) or use a lighter mode."
if [[ "$DISK_GIB" -lt 10 ]]; then warn "Only ${DISK_GIB} GiB free disk; images and the Kind node need ~6-8 GiB."; fi
ok "Mode $MODE is feasible with current Docker settings."
