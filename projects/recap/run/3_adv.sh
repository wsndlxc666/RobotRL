#!/bin/bash
# Step 3: Compute Advantages -> writes meta/advantages_<tag>.parquet
# Usage: bash 3_adv.sh [VALUE_CHECKPOINT_DIR]  (defaults to newest global_step under REPO logs)
set -e
source /root/autodl-tmp/recap/env.sh
cd $RECAP_REPO
source .venv/bin/activate

VALUE_CKPT="${1:-}"
if [ -z "$VALUE_CKPT" ]; then
  VALUE_CKPT=$(find $RECAP_REPO/logs/value_sft -type d -name 'global_step_*' 2>/dev/null | sort -V | tail -1)
fi
echo "[step3] value_checkpoint=$VALUE_CKPT"
[ -z "$VALUE_CKPT" ] && { echo "No value checkpoint found; run Step 2 first." >&2; exit 1; }

bash examples/offline_rl/advantage_labeling/recap/process/run_compute_advantages.sh recap_compute_advantages --nproc 1 \
  "advantage.value_checkpoint=$VALUE_CKPT"
