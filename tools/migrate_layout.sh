#!/usr/bin/env bash
# migrate_layout.sh — 把两块盘整理成统一结构
#
# 用法:
#   tools/migrate_layout.sh --dry-run            # 只看会做什么(默认)
#   tools/migrate_layout.sh --apply              # 全部执行
#   tools/migrate_layout.sh --apply fs tmp venv  # 只执行指定阶段
#
# 阶段: fs | tmp | venv | paths | verify
#
# 目标结构:
#   /autodl-fs/data/
#     lab/                                  (git 仓库,已有)
#     artifacts/{shared/models,recap,robocasa_v0,robocasa365}
#
#   /root/autodl-tmp/
#     code/{RLinf,robocasa_v0,robocasa365,robosuite_master}
#     projects/<proj>/{logs,ckpt,tb}
#     cache/{uv,hf}
#
# 所有旧路径都会留软链,保证已有脚本不断。
set -uo pipefail

DRY=1
PHASES=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) DRY=0 ;;
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) PHASES+=("$1") ;;
  esac
  shift
done
[[ ${#PHASES[@]} -eq 0 ]] && PHASES=(fs tmp venv paths verify)

FS=/autodl-fs/data
ART=$FS/artifacts
TMP=/root/autodl-tmp
CODE=$TMP/code

say() { printf '\n\033[1m== %s ==\033[0m\n' "$*"; }
run() {
  if [[ $DRY -eq 1 ]]; then echo "  [dry] $*"; else echo "  \$ $*"; "$@"; fi
}
# 把 src 移到 dst;dst 已存在则把 src 的内容并进去
merge_move() {
  local src=$1 dst=$2
  [[ -e "$src" ]] || { echo "  - 跳过(不存在) $src"; return 0; }
  if [[ -e "$dst" ]]; then
    echo "  - 合并 $src/* -> $dst/"
    if [[ $DRY -eq 1 ]]; then echo "  [dry] mv $src/* $dst/"; else
      shopt -s dotglob nullglob; mv "$src"/* "$dst"/ 2>/dev/null; shopt -u dotglob nullglob
      rmdir "$src" 2>/dev/null || true
    fi
  else
    run mv "$src" "$dst"
  fi
}
link() { # link <target> <linkpath>
  local t=$1 l=$2
  run ln -sfn "$t" "$l"
}

# ---------------------------------------------------------------- fs
phase_fs() {
  say "PHASE fs — 归档到 /autodl-fs/data/artifacts"
  run mkdir -p "$ART"/shared/models \
    "$ART"/recap/{models,ckpt,data} \
    "$ART"/robocasa_v0/{models,ckpt,data} \
    "$ART"/robocasa365/{models,ckpt,data}

  # 共用权重从 recap/models 抽出
  for m in pi05_base_openpi pi05_base_pytorch openpi_tokenizer \
           siglip2-so400m-patch14-224 gemma-3-270m \
           RLinf-Pi05-LIBERO-SFT-normstats RLinf-Pi05-LIBERO-SFT; do
    [[ -e "$FS/recap/models/$m" ]] && [[ ! -L "$FS/recap/models/$m" ]] \
      && merge_move "$FS/recap/models/$m" "$ART/shared/models/$m"
  done

  # recap: 剩余模型 / 报告 / 旧脚手架
  [[ -d "$FS/recap/models" ]] && merge_move "$FS/recap/models" "$ART/recap/models"
  [[ -d "$FS/recap/report" ]] && [[ ! -L "$FS/recap/report" ]] \
    && merge_move "$FS/recap/report" "$ART/recap/report"
  [[ -d "$FS/recap/run" ]] && merge_move "$FS/recap/run" "$ART/recap/legacy_run"
  [[ -f "$FS/recap/env.sh" ]] && merge_move "$FS/recap/env.sh" "$ART/recap/env.sh"

  # robocasa_v0
  [[ -d "$FS/robocasa/models" ]] && merge_move "$FS/robocasa/models" "$ART/robocasa_v0/models"
  [[ -d "$FS/robocasa/ckpt" ]]   && merge_move "$FS/robocasa/ckpt"   "$ART/robocasa_v0/ckpt"
  [[ -d "$FS/robocasa/report" ]] && merge_move "$FS/robocasa/report" "$ART/robocasa_v0/report"

  # robocasa365
  [[ -d "$FS/robocasa365/models" ]] && merge_move "$FS/robocasa365/models" "$ART/robocasa365/models"
  [[ -d "$FS/robocasa365_assets" ]] && [[ ! -L "$FS/robocasa365_assets" ]] \
    && merge_move "$FS/robocasa365_assets" "$ART/robocasa365/data/assets"

  # 旧路径软链(过渡期兼容)
  say "  -- 兼容软链 --"
  # 先把旧目录清空;清不干净就不建链,避免把软链建进目录内部
  local ok_to_link=1
  for d in "$FS/recap" "$FS/robocasa" "$FS/robocasa365"; do
    [[ -L "$d" ]] && continue
    if [[ -d "$d" ]]; then
      if [[ $DRY -eq 1 ]]; then echo "  [dry] rmdir $d"; continue; fi
      rmdir "$d" 2>/dev/null || {
        echo "  ! $d 非空,保留原目录,不建软链(请手工确认残留内容)"; ok_to_link=0
      }
    fi
  done
  if [[ $ok_to_link -eq 1 ]]; then
    link "$ART/recap"        "$FS/recap"
    link "$ART/robocasa_v0"  "$FS/robocasa"
    link "$ART/robocasa365"  "$FS/robocasa365"
    link "$ART/robocasa365/data/assets" "$FS/robocasa365_assets"
  else
    echo "  ! 跳过 $FS 顶层软链,请先清理残留目录"
  fi
  # 共用权重的旧引用
  for m in pi05_base_openpi pi05_base_pytorch openpi_tokenizer \
           siglip2-so400m-patch14-224 gemma-3-270m \
           RLinf-Pi05-LIBERO-SFT-normstats RLinf-Pi05-LIBERO-SFT; do
    link "$ART/shared/models/$m" "$ART/recap/models/$m"
  done
}

# ---------------------------------------------------------------- tmp
phase_tmp() {
  say "PHASE tmp — 代码与工作区"
  run mkdir -p "$CODE" "$TMP"/projects/{recap,robocasa_v0,robocasa365}/{logs,ckpt,tb} "$TMP"/cache

  merge_move "$TMP/RLinf"           "$CODE/RLinf"
  merge_move "$TMP/robocasa365"     "$CODE/robocasa365"
  merge_move "$TMP/robosuite_master" "$CODE/robosuite_master"

  # v0 源码从 venv 里搬出来
  if [[ -d "$CODE/RLinf/.venv-robocasa/robocasa" ]]; then
    merge_move "$CODE/RLinf/.venv-robocasa/robocasa" "$CODE/robocasa_v0"
  fi

  # openpi 在系统盘,只留软链
  [[ -d /root/openpi ]] && link /root/openpi "$CODE/openpi"

  # 缓存归位
  [[ -d "$TMP/.uv_cache" ]]  && merge_move "$TMP/.uv_cache"  "$TMP/cache/uv"
  [[ -d "$TMP/.uv_python" ]] && merge_move "$TMP/.uv_python" "$TMP/cache/uv_python"
  [[ -d "$TMP/hf" ]]         && merge_move "$TMP/hf"         "$TMP/cache/hf"
  link "$TMP/cache/uv"        "$TMP/.uv_cache"
  link "$TMP/cache/uv_python" "$TMP/.uv_python"
  link "$TMP/cache/hf"        "$TMP/hf"

  # 历史日志归入项目工作区
  if [[ -d "$CODE/RLinf/logs" ]]; then
    for d in "$CODE/RLinf/logs"/*robocasa365*; do
      [[ -e "$d" ]] && merge_move "$d" "$TMP/projects/robocasa365/logs/$(basename "$d")"
    done
  fi
}

# ---------------------------------------------------------------- venv
phase_venv() {
  say "PHASE venv — 修复移动后的绝对路径"
  local R=$CODE/RLinf
  for v in .venv .venv-robocasa .venv-robocasa365; do
    [[ -d "$R/$v" ]] || continue
    echo "  -- $v 修 shebang"
    if [[ $DRY -eq 1 ]]; then
      echo "  [dry] sed -i s|/root/autodl-tmp/RLinf|$R|g $R/$v/bin/*"
    else
      grep -rlZ '/root/autodl-tmp/RLinf' "$R/$v/bin" 2>/dev/null \
        | xargs -0 -r sed -i "s|/root/autodl-tmp/RLinf|$R|g"
    fi
  done

  echo "  -- 重装 editable 包"
  local py
  for v in .venv .venv-robocasa; do
    py="$R/$v/bin/python"
    [[ -x "$py" ]] && run "$py" -m pip install -q -e "$R" --no-deps
  done
  if [[ -x "$R/.venv-robocasa/bin/python" && -f "$CODE/robocasa_v0/setup.py" ]]; then
    run "$R/.venv-robocasa/bin/python" -m pip install -q -e "$CODE/robocasa_v0" --no-deps
  fi
  if [[ -x "$R/.venv-robocasa365/bin/python" ]]; then
    [[ -f "$CODE/robocasa365/setup.py" ]] && run "$R/.venv-robocasa365/bin/python" -m pip install -q -e "$CODE/robocasa365" --no-deps
    [[ -f "$CODE/robosuite_master/setup.py" ]] && run "$R/.venv-robocasa365/bin/python" -m pip install -q -e "$CODE/robosuite_master" --no-deps
  fi
}

# ---------------------------------------------------------------- paths
phase_paths() {
  say "PHASE paths — 改写配置与脚本里的路径"
  local pairs=(
    "/root/autodl-tmp/RLinf|$CODE/RLinf"
    "/root/autodl-tmp/robocasa365|$CODE/robocasa365"
    "/root/autodl-tmp/robosuite_master|$CODE/robosuite_master"
    "/autodl-fs/data/robocasa365_assets|$ART/robocasa365/data/assets"
    "/autodl-fs/data/robocasa365/models|$ART/robocasa365/models"
    "/autodl-fs/data/robocasa/models|$ART/robocasa_v0/models"
    "/autodl-fs/data/robocasa/ckpt|$ART/robocasa_v0/ckpt"
    "/autodl-fs/data/recap/models|$ART/recap/models"
  )
  local targets=(
    "$CODE/RLinf/examples/embodiment/config"
    "$CODE/RLinf/evaluations"
    "$FS/lab/projects"
    /root/env.sh
    /root/recap_env.sh
    /root/.bashrc
  )
  for p in "${pairs[@]}"; do
    local from=${p%%|*} to=${p##*|}
    echo "  -- $from -> $to"
    for t in "${targets[@]}"; do
      [[ -e "$t" ]] || continue
      if [[ $DRY -eq 1 ]]; then
        local n; n=$(grep -rl --exclude-dir=.git -- "$from" "$t" 2>/dev/null | wc -l)
        [[ "$n" -gt 0 ]] && echo "  [dry] 将改写 $n 个文件 (在 $t)"
      else
        grep -rlZ --exclude-dir=.git -- "$from" "$t" 2>/dev/null \
          | xargs -0 -r sed -i "s|$from|$to|g"
      fi
    done
  done
}

# ---------------------------------------------------------------- verify
phase_verify() {
  say "PHASE verify — 体检"
  local fail=0
  check_import() { # <venv python> <module>
    local py=$1 mod=$2
    if [[ ! -x "$py" ]]; then echo "  ✗ 缺 $py"; fail=1; return; fi
    if [[ $DRY -eq 1 ]]; then echo "  [dry] $py -c 'import $mod'"; return; fi
    if "$py" -c "import $mod" >/dev/null 2>&1; then echo "  ✓ import $mod ($py)"
    else echo "  ✗ import $mod 失败 ($py)"; fail=1; fi
  }
  check_import "$CODE/RLinf/.venv/bin/python" rlinf
  check_import "$CODE/RLinf/.venv-robocasa/bin/python" robocasa
  check_import "$CODE/RLinf/.venv-robocasa365/bin/python" robocasa
  check_import "$CODE/RLinf/.venv-robocasa365/bin/python" robosuite

  for p in "$ART/shared/models" "$ART/recap/models" "$ART/robocasa_v0/models" \
           "$ART/robocasa365/models" "$ART/robocasa365/data/assets" \
           "$CODE/RLinf" "$CODE/robocasa365" "$CODE/robosuite_master"; do
    [[ -e "$p" ]] && echo "  ✓ $p" || { echo "  ✗ 缺 $p"; fail=1; }
  done

  echo
  if [[ $fail -eq 0 ]]; then echo "  体检通过"; else echo "  有失败项,先别删旧东西"; fi
}

for ph in "${PHASES[@]}"; do
  case "$ph" in
    fs) phase_fs ;;
    tmp) phase_tmp ;;
    venv) phase_venv ;;
    paths) phase_paths ;;
    verify) phase_verify ;;
    *) echo "未知阶段: $ph" >&2; exit 2 ;;
  esac
done

echo
if [[ $DRY -eq 1 ]]; then
  echo "以上是 dry-run。确认无误后执行: tools/migrate_layout.sh --apply"
else
  echo "完成。建议接着跑: tools/bootstrap.sh all && (cd /autodl-fs/data/lab && git add -A && git commit -m 'chore: 统一目录结构')"
fi
