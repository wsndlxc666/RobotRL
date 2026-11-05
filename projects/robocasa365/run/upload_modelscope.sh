#!/bin/bash
# Upload robocasa checkpoints to ModelScope. Weights-only for archived steps;
# step_120 is uploaded as a full checkpoint (weights + dcp).
set -u
MS=/root/miniconda3/bin/modelscope
REPO365=wsndlxc666/robocasa365-opendrawer-flowsde-pi05
REPO_V0=wsndlxc666/robocasa-v0-closedrawer-flowsde-pi05
ART365=/autodl-fs/data/artifacts/robocasa365
TMP365=/root/autodl-tmp/projects/robocasa365/logs/20261104-23:00:07-robocasa365_flowsde_opendrawer_pi05/robocasa365_flowsde_opendrawer_pi05/checkpoints
OUT=/root/autodl-tmp/projects/robocasa365/upload
mkdir -p "$OUT"

weights_path() {
  case "$1" in
    20) echo "$ART365/ckpt/global_step_20/actor/model_state_dict/full_weights.pt";;
    40) echo "$ART365/ckpt/global_step_40/actor/model_state_dict/full_weights.pt";;
    60) echo "$TMP365/global_step_60/actor/model_state_dict/full_weights.pt";;
    80) echo "$TMP365/global_step_80/actor/model_state_dict/full_weights.pt";;
    100) echo "$TMP365/global_step_100/actor/model_state_dict/full_weights.pt";;
    *) echo "unknown step $1" >&2; return 1;;
  esac
}

upload_weights() { # step
  local n="$1" src dest
  src=$(weights_path "$n") || return 1
  dest="global_step_${n}/actor/model_state_dict/full_weights.pt"
  if [[ ! -s "$src" ]]; then echo "MISSING $src"; return 1; fi
  echo "===== upload step_$n weights ($(stat -c%s "$src") bytes) $(date -Iseconds)"
  "$MS" upload --repo-type model --commit-message "add global_step_${n} full_weights" \
    "$REPO365" "$src" "$dest" 2>&1 | tail -4
  return ${PIPESTATUS[0]}
}

case "${1:-help}" in
  sweep)
    for n in 20 40 60 80; do upload_weights "$n" || exit 1; done
    ;;
  final)
    upload_weights 100 || exit 1
    echo "===== upload step_120 full checkpoint $(date -Iseconds)"
    "$MS" upload --repo-type model --commit-message "add global_step_120 full checkpoint (weights + dcp)" \
      "$REPO365" "$TMP365/global_step_120/actor" global_step_120/actor 2>&1 | tail -4
    ;;
  v0)
    src=/autodl-fs/data/artifacts/robocasa_v0/ckpt/flow_sde_step90/actor/model_state_dict/full_weights.pt
    "$MS" upload --repo-type model --commit-message "add flow_sde step90 full_weights" \
      "$REPO_V0" "$src" step90/actor/model_state_dict/full_weights.pt 2>&1 | tail -4
    ;;
  verify)
    /root/miniconda3/bin/python - "$REPO365" "$REPO_V0" <<'PY'
import sys
from modelscope.hub.api import HubApi
api=HubApi()
for repo in sys.argv[1:]:
    print('===',repo)
    try:
        fs=api.get_model_files(repo, revision='master', recursive=True)
        for f in fs:
            p=f.get('Path') or f.get('path'); sz=f.get('Size') or f.get('size')
            print(f'  {sz}\t{p}')
    except Exception as e:
        print('  ERR',type(e).__name__,str(e)[:200])
PY
    ;;
  *)
    echo "usage: $0 {sweep|final|v0|verify}"; exit 1;;
esac
