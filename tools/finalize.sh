#!/usr/bin/env bash
# finalize.sh — 收尾:迁移 → 体检 → 归档日志 → 提交推送
#
# 用法:
#   tools/finalize.sh --yes
#
# 不做的事(需要人或 agent 判断):
#   - 写实验报告(用 exp-report skill)
#   - 删除任何重复资产
#   - 关实例(见 shutdown_if_done.sh)
set -uo pipefail

LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ "${1:-}" == "--yes" ]] || { echo "usage: $0 --yes"; exit 2; }

say() { printf '\n\033[1m== %s ==\033[0m\n' "$*"; }
fail=0

say "0/5 前置检查"
if pgrep -f "train_embodied_agent.py" >/dev/null 2>&1; then
  echo "  ✗ 训练进程仍在运行,拒绝收尾"
  exit 3
fi
echo "  ✓ 无训练进程"
if [[ -n "$(git -C "$LAB_ROOT" status --porcelain)" ]]; then
  echo "  ! 仓库有未提交改动,将在最后提交"
fi

say "1/5 目录迁移"
bash "$LAB_ROOT/tools/migrate_layout.sh" --apply || fail=1

say "2/5 体检"
bash "$LAB_ROOT/tools/migrate_layout.sh" verify || fail=1
bash "$LAB_ROOT/tools/bootstrap.sh" all || fail=1

say "3/5 归档散落日志"
DEST="$LAB_ROOT/projects/robocasa365/runs/20261104_train_flowsde_opendrawer_pi05/raw"
mkdir -p "$DEST"
shopt -s nullglob
for f in /root/autodl-tmp/eval_*.log; do
  cp -a "$f" "$DEST/" && echo "  → $f"
done
shopt -u nullglob
echo "  (原始日志不进 git,.gitignore 已排除)"

say "4/5 检查大文件未入库"
big=$(find "$LAB_ROOT" -type f -size +50M -not -path '*/.git/*' 2>/dev/null)
if [[ -n "$big" ]]; then
  echo "  ✗ 发现 >50MB 文件,不应入库:"; echo "$big"; fail=1
else
  echo "  ✓ 无大文件"
fi

say "5/5 提交并推送"
cd "$LAB_ROOT"
git add -A
if git diff --cached --quiet; then
  echo "  没有变更"
else
  git commit -q -m "chore: 统一目录结构并归档 $(date +%F) 的训练产物" \
    && git push -q origin HEAD && echo "  已推送: $(git log -1 --oneline)"
fi

echo
if [[ $fail -eq 0 ]]; then
  echo -e "\033[32m收尾完成,可以关机。\033[0m"
else
  echo -e "\033[31m有失败项,先修再关机。\033[0m"
  exit 1
fi
