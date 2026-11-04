#!/bin/bash
# usage: run_task_eval.sh <task> <num_envs> <tag>
set -u
TASK="$1"; N="${2:-6}"; TAG="${3:-$TASK}"
cd /root/autodl-tmp/RLinf
source .venv-robocasa365/bin/activate
export MUJOCO_GL=egl PYOPENGL_PLATFORM=egl NUMBA_DISABLE_JIT=1
export REPO_PATH=/root/autodl-tmp/RLinf
export EVALUATIONS_PATH=/root/autodl-tmp/RLinf/evaluations
export EMBODIED_PATH=/root/autodl-tmp/RLinf/examples/embodiment
bash evaluations/run_eval.sh robocasa365 robocasa365_eval_pi05 \
  env.eval.total_num_envs="$N" \
  "env.eval.task_filter=[\"$TASK\"]" \
  env.eval.episode_horizon_source=task_horizon \
  env.eval.max_steps_per_rollout_epoch=1500 \
  > /root/autodl-tmp/eval_${TAG}_n${N}.log 2>&1
echo "DONE $TASK"
