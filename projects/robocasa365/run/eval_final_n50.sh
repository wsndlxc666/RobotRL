#!/bin/bash
set -u
REPO=/root/autodl-tmp/code/RLinf
OUT=/root/autodl-tmp/projects/robocasa365/eval_final
OLD=/root/autodl-tmp/projects/robocasa365/logs/20261104-23:00:07-robocasa365_flowsde_opendrawer_pi05/robocasa365_flowsde_opendrawer_pi05/checkpoints
NEW=/root/autodl-tmp/projects/robocasa365/logs/robocasa365_flowsde_opendrawer_pi05_resume100/checkpoints
declare -A MODELS=([step100]="$OLD/global_step_100/actor" [step120]="$NEW/global_step_120/actor")
cd "$REPO"; source .venv-robocasa365/bin/activate
export MUJOCO_GL=egl PYOPENGL_PLATFORM=egl NUMBA_DISABLE_JIT=1
export REPO_PATH="$REPO" EVALUATIONS_PATH="$REPO/evaluations" EMBODIED_PATH="$REPO/examples/embodiment"
export ROBOCASA_PATH=/root/autodl-tmp/code/robocasa365 ROBOCASA_ASSETS_PATH=/autodl-fs/data/artifacts/robocasa365/data/assets
mkdir -p "$OUT"
for tag in step100 step120; do
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
