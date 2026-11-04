#!/bin/bash
# Finish line for the Flow-Noise arm:
#   1. wait for the step-90 evaluation produced by 16_eval_flownoise.sh
#   2. extend training 90 -> 120 (8 envs / batch 480 / micro 24)
#   3. evaluate step 120 (50 seeds)
#   4. regenerate fig_flownoise.png and fig_compare.png (overwrites)
#   5. shut the machine down, but only if the figures were actually produced
#
# Set NO_SHUTDOWN=1 to stop after step 4 instead of powering off.
set -e
source /root/autodl-tmp/robocasa_rl/env.sh
RC=/root/autodl-tmp/robocasa_rl
EXP=flow_noise_closedrawer_pi05
FN90_JSON="$RCAS_LOGS/eval_fn90_n50.json"
FN120_JSON="$RCAS_LOGS/eval_fn120_n50.json"

echo "[finish] waiting for step90 evaluation ..."
while [ ! -f "$FN90_JSON" ]; do
  if ! pgrep -f "16_eval_flownoise.sh" >/dev/null 2>&1; then
    echo "[finish] ABORT: 16_eval_flownoise.sh is gone and $FN90_JSON does not exist"
    exit 1
  fi
  sleep 30
done
echo "[finish] step90 eval found $(date)"

echo "[finish] extending training 90 -> 120"
START=90 TRAIN_ENVS=8 MICRO=24 TOTAL=120 \
  bash "$RC/run/13_train_flownoise.sh"

CK120=$(ls -dt "$RCAS_LOGS"/*/"$EXP"/checkpoints/global_step_120/actor 2>/dev/null | head -1)
if [ -z "$CK120" ]; then
  echo "[finish] ABORT: no step120 checkpoint"
  exit 1
fi
echo "[finish] step120 checkpoint: $CK120"

if [ ! -f "$FN120_JSON" ]; then
  echo "[finish] evaluating step120 (50 seeds) $(date)"
  bash "$RC/run/20_eval_ckpt.sh" "$CK120" CloseDrawer 50 "$FN120_JSON" --task CloseDrawer
fi

echo "[finish] regenerating figures $(date)"
/root/autodl-tmp/RLinf/.venv-robocasa/bin/python "$RC/report/make_compare_figures.py" \
  > "$RC/logs/make_figures.log" 2>&1
cat "$RC/logs/make_figures.log"

FN_PNG="$RC/report/fig_flownoise.png"
CMP_PNG="$RC/report/fig_compare.png"
if [ ! -f "$FN_PNG" ] || [ ! -f "$CMP_PNG" ]; then
  echo "[finish] ABORT: figures missing, not shutting down"
  exit 1
fi
if [ "$FN_PNG" -ot "$FN120_JSON" ] || [ "$CMP_PNG" -ot "$FN120_JSON" ]; then
  echo "[finish] ABORT: figures are older than the step120 evaluation, not shutting down"
  exit 1
fi
echo "[finish] figures updated: $FN_PNG $CMP_PNG"

sync
if [ "${NO_SHUTDOWN:-0}" = "1" ]; then
  echo "[finish] NO_SHUTDOWN=1, leaving the machine up"
  exit 0
fi

echo "[finish] shutting down $(date)"
sleep 20
shutdown -h now || poweroff || halt
