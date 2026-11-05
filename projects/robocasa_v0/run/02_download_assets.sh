#!/bin/bash
source /etc/network_turbo >/dev/null 2>&1
unset HF_ENDPOINT
export HF_HOME=/root/autodl-tmp/hf
export HF_HUB_DISABLE_XET=1
export HF_HUB_ENABLE_HF_TRANSFER=0
HF=/root/autodl-tmp/code/RLinf/.venv/bin/hf
cd /root/autodl-tmp
echo "[$(date)] ckpt"
$HF download changyeon/pi05_robocasa_as50_filteredbc_pytorch --include "30000/*" --local-dir /root/autodl-fs/robocasa/models/pi05_robocasa_100demos_s30000
echo "[$(date)] assets"
$HF download robocasa/robocasa-assets --repo-type dataset --include textures.zip generative_textures.zip fixtures.zip objaverse.zip --local-dir /root/autodl-tmp/robocasa_rl/assets_dl
echo "[$(date)] DONE"
