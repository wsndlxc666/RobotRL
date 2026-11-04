#!/bin/bash
set -x
source /etc/network_turbo
unset HF_ENDPOINT
export HF_HUB_DISABLE_TELEMETRY=1
export HF_HUB_DISABLE_XET=1
export HF_HUB_ENABLE_HF_TRANSFER=0

cd /autodl-fs/data/robocasa365_assets/_downloads
hf download robocasa/robocasa-assets --repo-type dataset --include "*.zip" --local-dir . --max-workers 4

cd /autodl-fs/data/robocasa365_assets/_downloads_lw
hf download nvidia/PhysicalAI-Robotics-Manipulation-Objects-Kitchen-MJCF --repo-type dataset --include "fixtures_lightwheel/*.zip" --include "objects_lightwheel/*.zip" --local-dir . --max-workers 4

cd /autodl-fs/data/robocasa365/models
hf download robocasa/robocasa365_checkpoints --include "pi05_pretrain_human300/multitask_learning/75000/params/*" --local-dir . --max-workers 4
hf download robocasa/robocasa365_checkpoints --include "pi05_pretrain_human300/multitask_learning/75000/assets/*" --local-dir . --max-workers 4

echo ALL_DONE
