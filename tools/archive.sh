#!/usr/bin/env bash
# archive.sh — 把一次实验的大产物从快盘归档到冷存储
#
# 用法:
#   tools/archive.sh <proj> <run_id> [文件或目录...]
#
# 不带路径时,归档 runs/<run_id>/raw/ 下所有 >50MB 的文件。
# 产物落到 /autodl-fs/data/artifacts/<proj>/runs/<run_id>/,并写入该 run 的 artifacts.yaml。
set -euo pipefail

LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJ="${1:?usage: archive.sh <proj> <run_id> [paths...]}"
ID="${2:?usage: archive.sh <proj> <run_id> [paths...]}"
shift 2 || true

RUN_DIR="$LAB_ROOT/projects/$PROJ/runs/$ID"
[[ -d "$RUN_DIR" ]] || { echo "no such run: $RUN_DIR" >&2; exit 1; }
DEST="/autodl-fs/data/artifacts/$PROJ/runs/$ID"
mkdir -p "$DEST"

mapfile -t FILES < <(
  if [[ $# -gt 0 ]]; then printf '%s\n' "$@"
  else find "$RUN_DIR" -type f -size +50M; fi
)

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "没有需要归档的大文件"
  exit 0
fi

for f in "${FILES[@]}"; do
  [[ -e "$f" ]] || { echo "skip missing: $f" >&2; continue; }
  local_base="$(basename "$f")"
  echo "归档 $f -> $DEST/$local_base"
  rsync -a --info=progress2 "$f" "$DEST/" 2>/dev/null || cp -a "$f" "$DEST/"
  size=$(du -h "$f" | cut -f1)
  sha=$(sha256sum "$f" | cut -d' ' -f1)
  cat >> "$RUN_DIR/artifacts.yaml" <<EOF
  - name: $local_base
    path: $DEST/$local_base
    size: $size
    sha256: $sha
EOF
done

echo
echo "已完成。artifacts.yaml:"
cat "$RUN_DIR/artifacts.yaml"
echo
echo "提示: 确认归档无误后可删除快盘原件;artifacts.yaml 里已记录一切。"
