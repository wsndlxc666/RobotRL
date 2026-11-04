#!/bin/bash
# Step 4: CFG Training (advantage-conditioned policy optimization)
set -e
source /root/autodl-tmp/recap/env.sh
cd $RECAP_REPO
source .venv/bin/activate
bash examples/offline_rl/policy_optimization/cfg_rl/run_cfg_rl.sh cfg_rl_openpi "$@"
