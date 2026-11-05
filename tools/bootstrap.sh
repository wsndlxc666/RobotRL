#!/usr/bin/env bash
# bootstrap.sh — 新实例开机后,按 manifest 把工作区恢复到可跑状态
#
# 用法: tools/bootstrap.sh [proj|all]
#
# 做的事(全部幂等):
#   1. 建 /root/autodl-tmp/{code,projects/<proj>}
#   2. 校验 code 目录与 commit 是否与 manifest 一致
#   3. 校验 venv 是否可用
#   4. 建 projects/<proj>/{logs,ckpt,tb}
#   5. 打印该项目的入口脚本与缺失项
#
# 它不负责重新 pip install(那由各项目 run/install.sh 负责),只做体检与搭建。
set -uo pipefail

LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:-all}"
TMP=/root/autodl-tmp

ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }
bad()  { printf '  \033[31m✗\033[0m %s\n' "$*"; }

yaml_get() { # yaml_get <file> <key>
  grep -m1 "^[[:space:]]*$2:" "$1" 2>/dev/null | sed "s/.*$2:[[:space:]]*//" | tr -d '"'
}

check_proj() {
  local p="$1"
  local m="$LAB_ROOT/projects/$p/manifest.yaml"
  echo
  echo "=== $p ==="
  [[ -f "$m" ]] || { bad "缺 manifest.yaml"; return; }

  mkdir -p "$TMP/projects/$p"/{logs,ckpt,tb}
  ok "工作区 $TMP/projects/$p/{logs,ckpt,tb}"

  # 代码目录与 commit:按 "- path:" 条目配对读取
  while read -r path commit origin; do
    [[ -n "$path" ]] || continue
    if [[ -d "$path" ]]; then
      local cur; cur=$(git -C "$path" rev-parse HEAD 2>/dev/null || echo "no-git")
      if [[ -z "$commit" || "$commit" == "n/a" ]]; then
        ok "code $path @ ${cur:0:8}(manifest 未记录 commit)"
      elif [[ "$cur" == "$commit" ]]; then ok "code $path @ ${commit:0:8}"
      elif [[ "$cur" == "no-git" ]]; then warn "code $path 存在但不是 git 仓库"
      else warn "code $path 在 ${cur:0:8},manifest 记录 ${commit:0:8}(不一致)"
      fi
    else
      bad "code 缺失: $path  (origin: $origin)"
    fi
  done < <(awk '
    /^  - path:/   {p=$3; c=""; o=""}
    /^    origin:/ {o=$2}
    /^    commit:/ {c=$2; print p, c, o}
  ' "$m")

  # venv
  local venv; venv=$(yaml_get "$m" "venv")
  if [[ -x "$venv/bin/python" ]]; then
    ok "venv $venv ($("$venv/bin/python" -V 2>&1))"
  else
    bad "venv 缺失: $venv  (rebuild: $(yaml_get "$m" "rebuild"))"
  fi

  # 数据/资产
  while IFS= read -r dpath; do
    [[ -n "$dpath" ]] || continue
    if [[ -e "$dpath" ]]; then ok "data $dpath"
    else bad "data 缺失: $dpath"; fi
  done < <(sed -n '/^data:/,/^entrypoints:/p' "$m" | sed -n 's/.*path:[[:space:]]*\([^,]*\).*/\1/p' | tr -d ' ')

  echo "  入口: $(sed -n '/^entrypoints:/,/^artifacts:/p' "$m" | grep -E 'eval:|train:' | sed 's/^[[:space:]]*/    /' | tr '\n' ' ')"
}

echo "lab bootstrap — $(date -Iseconds)"
mkdir -p "$TMP/code"

# ModelScope 凭据:从持久盘恢复(不打印 token)
MS_SECRETS=/autodl-fs/data/.secrets/modelscope
if [[ ! -s /root/.modelscope/credentials/git_token && -s "$MS_SECRETS/credentials/git_token" ]]; then
  mkdir -p /root/.modelscope
  cp -a "$MS_SECRETS/credentials" /root/.modelscope/
  ok "modelscope 凭据已从 $MS_SECRETS 恢复"
elif [[ -s /root/.modelscope/credentials/git_token ]]; then
  ok "modelscope 凭据已存在"
else
  warn "modelscope 凭据缺失:modelscope login --token <token> 后备份到 $MS_SECRETS"
fi

if [[ "$TARGET" == "all" ]]; then
  for d in "$LAB_ROOT"/projects/*/; do check_proj "$(basename "$d")"; done
else
  check_proj "$TARGET"
fi

echo
echo "完成。缺失项按上面 bad(✗) 行逐个补:代码 => git clone;venv => 项目 run/install.sh;data => 下载脚本。"
