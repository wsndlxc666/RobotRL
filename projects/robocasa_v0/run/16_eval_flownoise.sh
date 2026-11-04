#!/bin/bash
# Flow-Noise evaluation chain:
#   1. eval step 30 (20 seeds)
#   2. eval step 60 (50 seeds)
#   3. resume training 60 -> 90 with a safe 8-env / batch-480 config
#   4. eval step 90 (50 seeds)
# Sequential on purpose: one GPU and a 120 GiB memory cap.
set -e
source /root/autodl-tmp/robocasa_rl/env.sh

EXP=flow_noise_closedrawer_pi05
CK30=$(ls -d "$RCAS_LOGS"/*/"$EXP"/checkpoints/global_step_30/actor | head -1)
CK60=$(ls -d "$RCAS_LOGS"/*/"$EXP"/checkpoints/global_step_60/actor | head -1)

echo "[fn-eval] step30: $CK30 $(date)"
bash /root/autodl-tmp/robocasa_rl/run/20_eval_ckpt.sh "$CK30" CloseDrawer 20 \
  "$RCAS_LOGS/eval_fn30_n20.json" --task CloseDrawer

echo "[fn-eval] step60: $CK60 $(date)"
bash /root/autodl-tmp/robocasa_rl/run/20_eval_ckpt.sh "$CK60" CloseDrawer 50 \
  "$RCAS_LOGS/eval_fn60_n50.json" --task CloseDrawer

echo "[fn-eval] done, resuming training 60 -> 90 with 8 envs $(date)"
START=60 TRAIN_ENVS=8 MICRO=24 TOTAL=90 \
  bash /root/autodl-tmp/robocasa_rl/run/13_train_flownoise.sh

CK90=$(ls -dt "$RCAS_LOGS"/*/"$EXP"/checkpoints/global_step_90/actor 2>/dev/null | head -1)
if [ -z "$CK90" ]; then
  echo "[fn-eval] ERROR: no step90 checkpoint"
  exit 1
fi
echo "[fn-eval] step90: $CK90 $(date)"
bash /root/autodl-tmp/robocasa_rl/run/20_eval_ckpt.sh "$CK90" CloseDrawer 50 \
  "$RCAS_LOGS/eval_fn90_n50.json" --task CloseDrawer

echo "FN_EVAL_ALL_DONE $(date)"
