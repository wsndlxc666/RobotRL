#!/bin/bash
# After the step120 evaluation finishes, wait for the next Flow-Noise chunk
# boundary (global_step_60), then restart the Flow-Noise run with more
# environments / larger batch so the remaining training uses the GPU and CPU
# more fully. Restarting at a checkpoint boundary loses no progress.
set -e
FN_LOG=/root/autodl-tmp/robocasa_rl/logs/switch_flownoise.log
EVAL_JSON=/root/autodl-tmp/robocasa_rl/logs/eval_step120_n50.json
FN_PGID=235588

echo "[upgrade] waiting for step120 eval to finish ..."
while [ ! -f "$EVAL_JSON" ]; do sleep 20; done
echo "[upgrade] eval done $(date)"

echo "[upgrade] waiting for Flow-Noise chunk boundary (global_step_60) ..."
while ! grep -q "chunk done, checkpoint: .*global_step_60" "$FN_LOG" 2>/dev/null; do
  if ! pgrep -f "13_train_flownoise.sh" >/dev/null 2>&1; then
    echo "[upgrade] Flow-Noise run exited early; aborting upgrade"
    exit 0
  fi
  sleep 15
done
echo "[upgrade] step60 saved, stopping Flow-Noise for reconfiguration $(date)"
sleep 5
kill -- -"$FN_PGID" 2>/dev/null || true
sleep 15
pkill -f "13_train_flownoise.sh" 2>/dev/null || true
pkill -f "train_embodied_agent.py" 2>/dev/null || true
for i in $(seq 1 24); do
  pgrep -f "train_embodied_agent.py" >/dev/null 2>&1 || break
  sleep 5
done
if pgrep -f "train_embodied_agent.py" >/dev/null 2>&1; then
  echo "[upgrade] forcing remaining workers down"
  pkill -9 -f "train_embodied_agent.py" 2>/dev/null || true
  sleep 10
fi
echo "[upgrade] GPU used before restart: $(nvidia-smi --query-gpu=memory.used --format=csv,noheader)"

echo "[upgrade] restarting Flow-Noise 60 -> 90 with 8 envs / batch 480 $(date)"
exec env START=60 TRAIN_ENVS=8 MICRO=16 TOTAL=90 bash /root/autodl-tmp/robocasa_rl/run/13_train_flownoise.sh
