#!/usr/bin/env bash
# shutdown_if_done.sh — 收尾成功才关实例
#
# 用法:
#   tools/shutdown_if_done.sh --yes
#
# 行为:
#   1. 跑 finalize.sh
#   2. 只有 finalize 成功、且这次会话的产物都已推送到 GitHub,才执行 shutdown
#   3. 任何一步失败 → 不关机,退出码非 0
#
# 注意:关机会立刻断掉所有进程和当前会话,不可撤销。
set -uo pipefail

LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ "${1:-}" == "--yes" ]] || {
  echo "usage: $0 --yes   (会真的关机)"; exit 2;
}

echo "=== 收尾 ==="
if ! bash "$LAB_ROOT/tools/finalize.sh" --yes; then
  echo "!! finalize 失败,不关机"
  exit 1
fi

echo
echo "=== 关机前最后确认 ==="
# 1. 本地无未推送提交
cd "$LAB_ROOT"
if [[ -n "$(git log origin/main..HEAD --oneline 2>/dev/null)" ]]; then
  echo "!! 有未推送的提交,不关机"
  git log origin/main..HEAD --oneline
  exit 1
fi
echo "  ✓ 仓库已同步到 origin"

# 2. fs 上的关键目录存在
for p in /autodl-fs/data/lab /autodl-fs/data/artifacts; do
  [[ -d "$p" ]] || { echo "!! 缺 $p,不关机"; exit 1; }
  echo "  ✓ $p"
done

# 3. 没有仍在跑的训练
training_running() {
  local pid
  for pid in $(pgrep -f "train_embodied_agent.py" 2>/dev/null); do
    [[ "$(cat /proc/$pid/comm 2>/dev/null)" == "python"* ]] && return 0
  done
  return 1
}
if training_running; then
  echo "!! 训练仍在运行,不关机"; exit 1
fi
echo "  ✓ 无训练进程"

echo
echo "5 秒后关机(Ctrl-C 可取消)..."
sleep 5
echo "执行 shutdown"
/usr/bin/shutdown
