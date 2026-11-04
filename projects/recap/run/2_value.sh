#!/bin/bash
# Step 2: Value Model SFT
set -e
source /root/autodl-tmp/recap/env.sh
cd $RECAP_REPO
source .venv/bin/activate
bash examples/offline_rl/advantage_labeling/recap/run_value_sft.sh recap_value_model_sft "$@"
