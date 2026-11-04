#!/bin/bash
# Chunked FlowSDE PPO training: restart every CHUNK steps to reset the
# RoboCasa subprocess memory leak, resuming from the saved checkpoint.
set -e
source /root/autodl-tmp/robocasa_rl/env.sh

TOTAL=${TOTAL:-150}
CHUNK=${CHUNK:-30}
CONFIG=robocasa_closedrawer_ppo_openpi_pi05
EXP=flow_sde_closedrawer_pi05
COMMON=(
  env.train.total_num_envs=5
  env.train.rollout_epoch=1
  env.eval.total_num_envs=2
  env.eval.rollout_epoch=5
  actor.micro_batch_size=10
  actor.global_batch_size=300
  runner.val_check_interval=10
  runner.save_interval="$CHUNK"
  runner.logger.experiment_name="$EXP"
)

START=0
LAST=""
while [ "$START" -lt "$TOTAL" ]; do
  NEXT=$((START + CHUNK))
  [ "$NEXT" -gt "$TOTAL" ] && NEXT=$TOTAL
  RESUME=()
  if [ -n "$LAST" ]; then
    RESUME+=("runner.resume_dir=$LAST")
  fi
  echo "================ CHUNK $START -> $NEXT resume=${LAST:-none} $(date) ================"
  bash /root/autodl-tmp/robocasa_rl/run/10_train.sh "$CONFIG" \
    "${COMMON[@]}" "runner.max_steps=$NEXT" "${RESUME[@]}"
  CK=$(ls -dt "$RCAS_LOGS"/*/"$EXP"/checkpoints/global_step_"$NEXT" 2>/dev/null | head -1)
  if [ -z "$CK" ]; then
    echo "ERROR: checkpoint for step $NEXT not found"; exit 1
  fi
  echo "chunk done, checkpoint: $CK"
  # The previous checkpoint's dcp is no longer needed once the next chunk
  # resumed from it. Keep the current chunk's dcp for the next resume.
  if [ -n "$LAST" ] && [ -d "$LAST/actor/dcp_checkpoint" ]; then
    rm -rf "$LAST/actor/dcp_checkpoint"
    echo "pruned old dcp: $LAST/actor/dcp_checkpoint"
  fi
  LAST="$CK"
  START=$NEXT
done
# All chunks done: drop the last dcp, keep full weights.
if [ -n "$LAST" ] && [ -d "$LAST/actor/dcp_checkpoint" ]; then
  rm -rf "$LAST/actor/dcp_checkpoint"
fi
echo "ALL DONE $(date)"
