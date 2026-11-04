#!/bin/bash
# Few-shot SFT baseline on LIBERO-10 Task0 (init from raw pi0.5 base)
set -e
source /root/autodl-tmp/recap/env.sh
cd $RECAP_REPO
source .venv/bin/activate
bash examples/sft/run_vla_sft.sh libero_task0_sft_openpi_pi05 "$@"
