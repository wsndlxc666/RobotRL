#!/bin/bash
set -e
source /root/autodl-tmp/robocasa_rl/env.sh
declare -A CK
CK[30]=$(ls -d $RCAS_LOGS/*/flow_sde_closedrawer_pi05/checkpoints/global_step_30/actor | head -1)
CK[60]=$(ls -d $RCAS_LOGS/*/flow_sde_closedrawer_pi05/checkpoints/global_step_60/actor | head -1)
CK[90]=$(ls -d $RCAS_LOGS/*/flow_sde_closedrawer_pi05/checkpoints/global_step_90/actor | head -1)
for step in 30 60 90; do
  if [ "$step" = "90" ]; then N=50; elif [ "$step" = "60" ]; then N=30; else N=20; fi
  echo "===== eval step $step ($N trials): ${CK[$step]} ====="
  bash /root/autodl-tmp/robocasa_rl/run/20_eval_ckpt.sh "${CK[$step]}" CloseDrawer $N \
    "$RCAS_LOGS/eval_step${step}_n${N}.json" --task CloseDrawer
done
echo ALL_EVAL_DONE
