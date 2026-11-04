#!/bin/bash
# Evaluate an RLinf FSDP checkpoint (or a bare openpi checkpoint) on RoboCasa.
# usage: bash run/20_eval_ckpt.sh <ckpt_dir> <task> <trials> <out.json> [extra eval args]
set -e
source /root/autodl-tmp/robocasa_rl/env.sh
CK="$1"; TASK="${2:-CloseDrawer}"; N="${3:-20}"; OUT="$4"; shift 4 || true
NORM="$RCAS_MODELS/pi05_robocasa_100demos_s30000/30000/physical-intelligence/robocasa_100demos/norm_stats.json"
cd "$REPO_PATH"
MUJOCO_GL=egl PYOPENGL_PLATFORM=egl MUJOCO_EGL_DEVICE_ID=0 CUDA_VISIBLE_DEVICES=0 \
  PYTHONPATH="$REPO_PATH" OPENPI_DATA_HOME=/root/autodl-tmp/openpi_data \
  "$REPO_PATH/.venv-robocasa/bin/python" /root/autodl-tmp/robocasa_rl/run/robocasa_eval.py \
  --model-path "$CK" --norm-stats-path "$NORM" \
  --task "$TASK" --trials "$N" --out "$OUT" "$@"
