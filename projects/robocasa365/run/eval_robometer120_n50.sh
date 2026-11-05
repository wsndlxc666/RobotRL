#!/bin/bash
set -u
REPO=/root/autodl-tmp/code/RLinf
OUT=/root/autodl-tmp/projects/robocasa365/eval_rb120
B=/root/autodl-tmp/projects/robocasa365/logs/robocasa365_flowsde_opendrawer_pi05_robometer120/checkpoints
cd "$REPO"; source .venv-robocasa365/bin/activate
export MUJOCO_GL=egl PYOPENGL_PLATFORM=egl NUMBA_DISABLE_JIT=1
export REPO_PATH="$REPO" EVALUATIONS_PATH="$REPO/evaluations" EMBODIED_PATH="$REPO/examples/embodiment"
export ROBOCASA_PATH=/root/autodl-tmp/code/robocasa365 ROBOCASA_ASSETS_PATH=/autodl-fs/data/artifacts/robocasa365/data/assets
mkdir -p "$OUT"
for s in 40 80 120; do
  m="$B/global_step_$s/actor"; log="$OUT/rb120_$s.log"
  echo "===== START rb120_$s $(date -Iseconds) model=$m" | tee -a "$OUT/sweep.log"
  bash evaluations/run_eval.sh robocasa365 robocasa365_eval_pi05 \
    env.eval.total_num_envs=25 env.eval.rollout_epoch=2 \
    'env.eval.task_filter=["OpenDrawer"]' \
    env.eval.episode_horizon_source=task_horizon env.eval.max_steps_per_rollout_epoch=1500 \
    rollout.model.model_path="$m" > "$log" 2>&1
  echo "===== END rb120_$s rc=$? $(date -Iseconds)" | tee -a "$OUT/sweep.log"
  python - "$log" "$OUT/rb120_$s.json" "rb120_$s" "$m" <<'PY'
import json,re,sys
log,out,tag,model=sys.argv[1:5]; txt=open(log,errors='ignore').read()
def g(k):
    m=re.findall(rf'{k}=([0-9.]+)',txt); return float(m[-1]) if m else None
json.dump(dict(tag=tag,model_path=model,num_trajectories=g('num_trajectories'),success_once=g('success_once'),episode_len=g('episode_len'),return_=g('return')),open(out,'w'),indent=1)
PY
done
echo "ALL DONE $(date -Iseconds)" | tee -a "$OUT/sweep.log"
