#!/usr/bin/env bash
# run_with_report.sh — 跑一个实验,自动把可复现信息落到 runs/<id>/raw/
#
# 用法:
#   tools/run_with_report.sh <proj> <stage> <tag> -- <命令...>
#
# 例:
#   tools/run_with_report.sh robocasa365 eval opendrawer_n48 -- \
#     bash projects/robocasa365/run/run_task_eval.sh OpenDrawer 48
#
# 跑完后会在 run 目录留下:
#   raw/run.log        完整 stdout/stderr
#   raw/meta.json      时间/主机/命令/代码 commit
#   config.yaml        实参快照(从 meta 生成)
# 并写入 .REPORT_PENDING 标记,提示 agent 生成 REPORT.md
set -uo pipefail

LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ $# -ge 4 && "$4" == "--" ]] || {
  echo "usage: $0 <proj> <stage> <tag> -- <command...>" >&2; exit 2;
}
PROJ="$1"; STAGE="$2"; TAG="$3"; shift 4

RUN_DIR="$("$LAB_ROOT/tools/lab" run-new "$PROJ" "$STAGE" "$TAG")"
ID="$(basename "$RUN_DIR")"
LOG="$RUN_DIR/raw/run.log"

code_commit() {
  local p="$1"
  [[ -d "$p/.git" ]] && git -C "$p" rev-parse HEAD 2>/dev/null || echo "n/a"
}

{
  echo "=== run: $ID ==="
  echo "start: $(date -Iseconds)"
  echo "cmd: $*"
} | tee -a "$LOG"

START=$(date +%s)
"$@" 2>&1 | tee -a "$LOG"
RC=${PIPESTATUS[0]}
END=$(date +%s)

cat > "$RUN_DIR/raw/meta.json" <<EOF
{
  "run_id": "$ID",
  "project": "$PROJ",
  "stage": "$STAGE",
  "tag": "$TAG",
  "start": "$(date -Iseconds -d @$START)",
  "end": "$(date -Iseconds -d @$END)",
  "duration_sec": $((END-START)),
  "exit_code": $RC,
  "host": "$(hostname)",
  "command": $(printf '%s' "$*" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
  "cwd": "$(pwd)",
  "code": {
    "RLinf": "$(code_commit /root/autodl-tmp/RLinf)",
    "robocasa365": "$(code_commit /root/autodl-tmp/robocasa365)",
    "robosuite": "$(code_commit /root/autodl-tmp/robosuite_master)"
  }
}
EOF

python3 - "$RUN_DIR" <<'PY'
import json, sys, pathlib
d = pathlib.Path(sys.argv[1])
meta = json.loads((d/"raw/meta.json").read_text())
(d/"config.yaml").write_text(
    f"run_id: {meta['run_id']}\n"
    f"project: {meta['project']}\n"
    f"stage: {meta['stage']}\n"
    f"tag: {meta['tag']}\n"
    f"command: {json.dumps(meta['command'])}\n"
    f"code:\n" + "".join(f"  {k}: {v}\n" for k,v in meta['code'].items())
)
PY

echo "REPORT_PENDING $RUN_DIR"
echo "exit_code=$RC"
exit "$RC"
