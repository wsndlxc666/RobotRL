#!/bin/bash
# Wait for the FlowSDE continuation to save global_step_120, stop it there
# (150 adds little compared with starting the next algorithm), then hand the
# GPU over to the Flow-Noise arm.
set -e
LOG=/root/autodl-tmp/robocasa_rl/logs/continue_train3.log
FSDE_PGID=216736

echo "[switch] waiting for FlowSDE global_step_120 ..."
while ! grep -q "chunk done, checkpoint: .*global_step_120" "$LOG" 2>/dev/null; do
  if ! pgrep -f "12_continue_train.sh" >/dev/null 2>&1; then
    echo "[switch] FlowSDE run exited before step120; continuing anyway"
    break
  fi
  sleep 15
done
echo "[switch] step120 checkpoint saved, stopping FlowSDE run"
sleep 5
kill -- -"$FSDE_PGID" 2>/dev/null || true
sleep 15
pkill -f "12_continue_train.sh" 2>/dev/null || true
pkill -f "train_embodied_agent.py" 2>/dev/null || true

# Wait until the GPU/CPU workers have actually exited before loading the next arm.
for i in $(seq 1 24); do
  if ! pgrep -f "train_embodied_agent.py" >/dev/null 2>&1; then
    break
  fi
  sleep 5
done
if pgrep -f "train_embodied_agent.py" >/dev/null 2>&1; then
  echo "[switch] forcing remaining workers down"
  pkill -9 -f "train_embodied_agent.py" 2>/dev/null || true
  sleep 10
fi

FREE_MB=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits | head -1 | tr -d ' ')
echo "[switch] GPU memory used: ${FREE_MB} MiB"

echo "[switch] starting Flow-Noise arm $(date)"
exec bash /root/autodl-tmp/robocasa_rl/run/13_train_flownoise.sh
