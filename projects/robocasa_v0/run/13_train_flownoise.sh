#!/bin/bash
# Flow-Noise arm: same base SFT checkpoint and env setup as the FlowSDE arm,
# but with the learnable exploration-noise network instead of the fixed SDE
# schedule. Trains in 30-step chunks (env-memory reset between chunks).
#
# Env/batch sizing: each env contributes 300 / 5 = 60 transitions per
# iteration, so global_batch_size = TRAIN_ENVS * 60.
set -e
source /root/autodl-tmp/robocasa_rl/env.sh

CONFIG=robocasa_closedrawer_ppo_openpi_pi05
EXP=flow_noise_closedrawer_pi05
TOTAL=${TOTAL:-90}
CHUNK=${CHUNK:-30}
START=${START:-0}
TRAIN_ENVS=${TRAIN_ENVS:-6}
MICRO=${MICRO:-12}
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
  actor.model.openpi.noise_method=flow_noise
  actor.model.openpi.joint_logprob=True
  +actor.model.openpi.noise_logvar_range=[0.08,0.16]
  algorithm.entropy_bonus=0.005
)

LAST=""
if [ "$START" -gt 0 ]; then
  LAST=$(ls -dt "$RCAS_LOGS"/*/"$EXP"/checkpoints/global_step_"$START" 2>/dev/null | head -1)
  if [ -z "$LAST" ]; then
    echo "ERROR: checkpoint for step $START not found"
    exit 1
  fi
  echo "[flownoise] resuming from $LAST"
fi
echo "[flownoise] train_envs=$TRAIN_ENVS micro_batch=$MICRO global_batch=$GBS total=$TOTAL"

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
    echo "ERROR: checkpoint for step $NEXT not found"
    exit 1
  fi
  echo "chunk done, checkpoint: $CK"

  if [ -n "$LAST" ] && [ -d "$LAST/actor/dcp_checkpoint" ]; then
    rm -rf "$LAST/actor/dcp_checkpoint"
  fi
  LAST="$CK"
  START=$NEXT
done

if [ -n "$LAST" ] && [ -d "$LAST/actor/dcp_checkpoint" ]; then
  rm -rf "$LAST/actor/dcp_checkpoint"
fi
echo "FLOWNOISE TRAIN DONE $(date)"
