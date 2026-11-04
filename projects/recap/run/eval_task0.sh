#!/bin/bash
# Evaluate a bare-OpenPI model on LIBERO-10 Task 0.
# Usage: bash eval_task0.sh <model_dir> [num_envs] [extra hydra overrides...]
set -e
source /root/autodl-tmp/recap/env.sh
cd $RECAP_REPO
source .venv/bin/activate
MODEL="$1"; NENV="${2:-50}"; shift 2 2>/dev/null || shift $#
bash evaluations/run_eval.sh libero libero_10_task0_openpi_pi05_eval \
  rollout.model.model_path="$MODEL" \
  env.eval.total_num_envs="$NENV" "$@"
