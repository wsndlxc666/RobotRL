#!/bin/bash
R=/root/autodl-tmp/recap
bash $R/run/eval_task0.sh /root/autodl-tmp/recap_data/RLinf-Pi05-LIBERO-SFT 30 > $R/logs/eval_start30.log 2>&1
bash $R/run/eval_task0.sh /root/autodl-fs/recap/models/recap_fromsft_step1500 30 > $R/logs/eval_recap1500_30.log 2>&1
touch $R/logs/EVAL_BIG_DONE
