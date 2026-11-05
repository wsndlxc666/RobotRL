#!/bin/bash
set -u
REPO=/root/autodl-tmp/code/RLinf
OUT=/root/autodl-tmp/projects/robocasa365/eval_rb
B=/root/autodl-tmp/projects/robocasa365/logs/robocasa365_flowsde_opendrawer_pi05_robometer40/checkpoints
declare -A MODELS=([rb20]="$B/global_step_20/actor" [rb40]="$B/global_step_40/actor")
cd "$REPO"; source .venv-robocasa365/bin/activate
export MUJOCO_GL=egl PYOPENGL_PLATFORM=egl NUMBA_DISABLE_JIT=1
export REPO_PATH="$REPO" EVALUATIONS_PATH="$REPO/evaluations" EMBODIED_PATH="$REPO/examples/embodiment"
export ROBOCASA_PATH=/root/autodl-tmp/code/robocasa365 ROBOCASA_ASSETS_PATH=/autodl-fs/data/artifacts/robocasa365/data/assets
mkdir -p "$OUT"
for tag in rb20 rb40; do
  m="${MODELS[$tag]}"; log="$OUT/${tag}.log"
  echo "===== START $tag $(date -Iseconds) model=$m" | tee -a "$OUT/sweep.log"
  bash evaluations/run_eval.sh robocasa365 robocasa365_eval_pi05 \
    env.eval.total_num_envs=25 env.eval.rollout_epoch=2 \
    'env.eval.task_filter=["OpenDrawer"]' \
    env.eval.episode_horizon_source=task_horizon env.eval.max_steps_per_rollout_epoch=1500 \
    rollout.model.model_path="$m" > "$log" 2>&1
  echo "===== END $tag rc=$? $(date -Iseconds)" | tee -a "$OUT/sweep.log"
  python - "$log" "$OUT/${tag}.json" "$tag" "$m" <<'PY'
import json,re,sys
log,out,tag,model=sys.argv[1:5]; txt=open(log,errors='ignore').read()
def g(k):
    m=re.findall(rf'{k}=([0-9.]+)',txt); return float(m[-1]) if m else None
json.dump(dict(tag=tag,model_path=model,num_trajectories=g('num_trajectories'),success_once=g('success_once'),episode_len=g('episode_len'),return_=g('return')),open(out,'w'),indent=1)
PY
done
echo "ALL DONE $(date -Iseconds)" | tee -a "$OUT/sweep.log"
