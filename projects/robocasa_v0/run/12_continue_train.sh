#!/bin/bash
# Continue FlowSDE PPO training from global_step_90 to TOTAL (default 150).
#
# - Waits for any running evaluation to exit first (GPU/RAM contention).
# - Trains in chunks of CHUNK steps, restarting the process between chunks to
#   reset the RoboCasa env subprocess memory leak, resuming from the previous
#   chunk's checkpoint.
# - The step-90 checkpoint only kept full_weights.pt (its DCP optimizer state
#   was pruned), so this continuation restores model weights but starts a fresh
#   optimizer. Later chunks resume with full DCP state.
#
# Env/batch sizing: each env contributes max_steps_per_rollout_epoch /
# num_action_chunks = 300 / 5 = 60 transitions per iteration, so
# global_batch_size must equal TRAIN_ENVS * 60.
set -e
source /root/autodl-tmp/robocasa_rl/env.sh

CONFIG=robocasa_closedrawer_ppo_openpi_pi05
EXP=flow_sde_closedrawer_pi05
TOTAL=${TOTAL:-150}
CHUNK=${CHUNK:-30}
START=${START:-90}
TRAIN_ENVS=${TRAIN_ENVS:-8}
MICRO=${MICRO:-16}
GBS=$((TRAIN_ENVS * 60))

COMMON=(
  env.train.total_num_envs="$TRAIN_ENVS"
  env.train.rollout_epoch=1
  env.eval.total_num_envs=2
  env.eval.rollout_epoch=5
  actor.micro_batch_size="$MICRO"
  actor.global_batch_size="$GBS"
  runner.val_check_interval=10
  runner.save_interval="$CHUNK"
  runner.logger.experiment_name="$EXP"
)

if [ "${SKIP_WAIT:-0}" != "1" ]; then
  echo "[continue] waiting for evaluation to finish..."
  while pgrep -f "21_eval_all.sh|20_eval_ckpt.sh|robocasa_eval.py" >/dev/null 2>&1; do
    echo "[continue] eval still running, waiting... $(date)"
    sleep 30
  done
  echo "[continue] eval finished, starting training from step $START"
fi

LAST=$(ls -dt "$RCAS_LOGS"/*/"$EXP"/checkpoints/global_step_"$START" 2>/dev/null | head -1)
if [ -z "$LAST" ]; then
  echo "ERROR: checkpoint for step $START not found"
  exit 1
fi
echo "[continue] resume from: $LAST"
echo "[continue] train_envs=$TRAIN_ENVS micro_batch=$MICRO global_batch=$GBS total=$TOTAL"

while [ "$START" -lt "$TOTAL" ]; do
  NEXT=$((START + CHUNK))
  [ "$NEXT" -gt "$TOTAL" ] && NEXT=$TOTAL

  echo "================ CHUNK $START -> $NEXT resume=$LAST $(date) ================"
  bash /root/autodl-tmp/robocasa_rl/run/10_train.sh "$CONFIG" \
    "${COMMON[@]}" "runner.max_steps=$NEXT" "runner.resume_dir=$LAST"

  CK=$(ls -dt "$RCAS_LOGS"/*/"$EXP"/checkpoints/global_step_"$NEXT" 2>/dev/null | head -1)
  if [ -z "$CK" ]; then
    echo "ERROR: checkpoint for step $NEXT not found"
    exit 1
  fi
  echo "chunk done, checkpoint: $CK"

  # Old DCP no longer needed once the next chunk resumed from it.
  if [ -n "$LAST" ] && [ -d "$LAST/actor/dcp_checkpoint" ]; then
    rm -rf "$LAST/actor/dcp_checkpoint"
    echo "pruned old dcp: $LAST/actor/dcp_checkpoint"
  fi
  LAST="$CK"
  START=$NEXT
done

# Keep the last DCP? Prune it like the original script, keep full weights only.
if [ -n "$LAST" ] && [ -d "$LAST/actor/dcp_checkpoint" ]; then
  rm -rf "$LAST/actor/dcp_checkpoint"
fi
echo "CONTINUE TRAIN DONE $(date)"
