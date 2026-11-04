#!/bin/bash
# Step 1: Compute Returns -> writes meta/returns_fail300.parquet sidecar + merges stats
set -e
source /root/autodl-tmp/recap/env.sh
cd $RECAP_REPO
source .venv/bin/activate
bash examples/offline_rl/advantage_labeling/recap/process/run_compute_returns.sh recap_compute_returns "$@"
