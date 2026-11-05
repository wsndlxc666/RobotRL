# RECAP repro — shared paths (source this in every run script)
export RECAP_REPO=/root/autodl-tmp/code/RLinf
export REPO_PATH=/root/autodl-tmp/code/RLinf
export DS=/root/autodl-tmp/recap_data/RECAP-Libero10-Task0-48succ-Data
export SFT=$DS/libero10_task0_sft
export ROLL=$DS/libero10_task0_train
export EVAL=$DS/libero10_task0_eval
export MODELS=/root/autodl-fs/recap/models
export SIGLIP=$MODELS/siglip2-so400m-patch14-224
export GEMMA=$MODELS/gemma-3-270m
export BASE_OPENPI=$MODELS/pi05_base_openpi
export BASE_PT=$MODELS/pi05_base_pytorch/staged
export NORM_STATS=$MODELS/RLinf-Pi05-LIBERO-SFT-normstats/physical-intelligence/libero/norm_stats.json
export LOGS=/root/autodl-tmp/recap/logs
export RETURNS_TAG=fail300
export ADV_TAG=fail300_N10_q30
# dataset list used consistently across steps 1-4 (sft-only first; add $ROLL item later)
export TRAIN_PATHS_SFT="[{dataset_path:$SFT,type:sft,weight:1.0,robot_type:libero,model_type:pi05}]"
export TRAIN_PATHS_RETURNS="[{dataset_path:$SFT,type:sft}]"
export EVAL_PATHS="[{dataset_path:$EVAL,max_samples:10000,robot_type:libero,model_type:pi05}]"
export HF_HOME=/root/autodl-tmp/hf
export MUJOCO_GL=egl PYOPENGL_PLATFORM=egl
export CUDA_VISIBLE_DEVICES=0
# RLinf's libero must use the venv's own package assets (~/.libero), not openpi's config
unset LIBERO_CONFIG_PATH
