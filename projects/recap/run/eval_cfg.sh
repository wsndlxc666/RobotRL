#!/bin/bash
# Evaluate a RECAP CFG checkpoint with positive-advantage conditioning on LIBERO-10 Task 0.
# Usage: bash eval_cfg.sh <cfg_global_step_dir> [num_envs] [extra overrides]
set -e
source /root/autodl-tmp/recap/env.sh
cd $RECAP_REPO
source .venv/bin/activate
MODEL="$1"; NENV="${2:-20}"; shift 2 2>/dev/null || shift $#
mkdir -p "$MODEL/physical-intelligence/libero"
cp -n "$NORM_STATS" "$MODEL/physical-intelligence/libero/norm_stats.json" 2>/dev/null || true
# CFG builder looks for <dir>/actor/model_state_dict/full_weights.pt or <dir>/model.safetensors
bash evaluations/run_eval.sh libero libero_10_task0_cfg_pi05_eval \
  rollout.model.model_path="$MODEL" \
  env.eval.total_num_envs="$NENV" "$@"
