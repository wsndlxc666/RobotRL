#!/bin/bash
# Keep only full_weights.pt in checkpoints: drop the large dcp state once
# full weights are written.
while true; do
  for fw in $(find /root/autodl-tmp/robocasa_rl/logs -path "*/flow_sde_closedrawer_pi05/checkpoints/global_step_*/actor/model_state_dict/full_weights.pt" 2>/dev/null); do
    d=$(dirname "$(dirname "$fw")")/dcp_checkpoint
    [ -d "$d" ] && rm -rf "$d" && echo "[$(date +%H:%M:%S)] pruned $d"
  done
  sleep 180
done
