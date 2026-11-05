#!/bin/bash
set -u
PID="${1:?usage: finalize_robometer120.sh <train_pid>}"
LOG=/root/autodl-tmp/projects/robocasa365/logs/finalize.log
CKPT=/root/autodl-tmp/projects/robocasa365/logs/robocasa365_flowsde_opendrawer_pi05_robometer120/checkpoints/global_step_120/actor/model_state_dict/full_weights.pt
echo "[$(date -Iseconds)] finalizer armed for pid=$PID" >> "$LOG"
while kill -0 "$PID" 2>/dev/null; do sleep 60; done
echo "[$(date -Iseconds)] training process exited" >> "$LOG"
if [[ ! -s "$CKPT" ]]; then
  echo "[$(date -Iseconds)] ERROR: step_120 missing/empty, abort (no shutdown)" >> "$LOG"
  touch /root/autodl-tmp/projects/robocasa365/FINALIZE_FAILED
  exit 1
fi
echo "[$(date -Iseconds)] step_120 ok, starting evals" >> "$LOG"
bash /root/autodl-tmp/projects/robocasa365/run/eval_robometer120_n50.sh >> "$LOG" 2>&1
echo "[$(date -Iseconds)] evals done, building report" >> "$LOG"
/root/miniconda3/bin/python /root/autodl-tmp/projects/robocasa365/run/finalize_robometer120.py >> "$LOG" 2>&1
if [[ $? -ne 0 ]]; then echo "[$(date -Iseconds)] ERROR report script failed" >> "$LOG"; exit 1; fi
echo "[$(date -Iseconds)] report done, pushing" >> "$LOG"
cd /autodl-fs/data/lab || exit 1
for i in 1 2 3; do
  if ./tools/lab sync "robocasa365: Robometer 120步训练+评测 A/B" >> "$LOG" 2>&1; then
    echo "[$(date -Iseconds)] push ok" >> "$LOG"; break
  fi
  echo "[$(date -Iseconds)] push attempt $i failed, retry" >> "$LOG"; sleep 30
done
sync
echo "[$(date -Iseconds)] shutting down" >> "$LOG"
shutdown -h now 2>>"$LOG" || poweroff 2>>"$LOG" || echo "shutdown command failed" >> "$LOG"
