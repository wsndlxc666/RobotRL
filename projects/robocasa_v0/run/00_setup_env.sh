#!/bin/bash
set -e
export UV_DEFAULT_INDEX=http://mirrors.aliyun.com/pypi/simple
VENV=/root/autodl-tmp/RLinf/.venv
NEW=/root/autodl-tmp/RLinf/.venv-robocasa
echo "[$(date)] cloning venv..."
if [ ! -x "$NEW/bin/python" ]; then
  cp -a --reflink=auto "$VENV" "$NEW"
fi
echo "[$(date)] venv clone done: $($NEW/bin/python -V 2>&1)"
echo "[$(date)] cloning RLinf robocasa fork..."
if [ ! -d "$NEW/robocasa/.git" ]; then
  git clone --depth 1 https://github.com/RLinf/robocasa.git "$NEW/robocasa"
fi
echo "[$(date)] installing robocasa (editable) ..."
"$NEW/bin/python" -m pip install -e "$NEW/robocasa" 2>&1 | tail -30
echo "[$(date)] setup_macros..."
cd "$NEW/robocasa" && "$NEW/bin/python" -m robocasa.scripts.setup_macros
echo "[$(date)] DONE"
