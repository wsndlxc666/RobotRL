#!/bin/bash
# Evaluate RECAP intermediate checkpoints on Task0 (20 trials each), then a video run.
source /root/autodl-tmp/recap/env.sh
R=/root/autodl-tmp/recap
run () { # model nenv logfile [extra]
  local m=$1 n=$2 l=$3; shift 3
  bash $R/run/eval_task0.sh "$m" "$n" "$@" > "$l" 2>&1
  echo "$(basename $m): $(grep -ac 'success=True' $l)/$n" >> $R/logs/eval_series_summary.txt
}
: > /root/autodl-tmp/recap/logs/eval_series_summary.txt
run /root/autodl-fs/recap/models/recap_fromsft_step900  20 /root/autodl-tmp/recap/logs/eval_recap_fromsft900.log
run /root/autodl-fs/recap/models/recap_fromsft_step1200 20 /root/autodl-tmp/recap/logs/eval_recap_fromsft1200.log
run /root/autodl-fs/recap/models/recap_fromsft_step1500 10 /root/autodl-tmp/recap/logs/eval_video1500.log env.eval.video_cfg.save_video=True
touch /root/autodl-tmp/recap/logs/EVAL_SERIES_DONE
