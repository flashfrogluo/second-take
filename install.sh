#!/usr/bin/env bash
# Second Take 安装脚本
# 将本仓库装到各 agent 的 skills 目录。优先从 Release 附件安装（可统计下载量），
# Release 不可用时回退到 codeload tarball。
#
# 用法：
#   ./install.sh                          装到默认目录
#   ./install.sh /path/to/skills/second-take   指定目标目录
#   ./install.sh --from-local             从当前仓库目录装（开发者自用）
#   ./install.sh --version 1.7.3          指定正式版本（默认取 GitHub 最新 Release）
#
# 环境变量：
#   REPO   默认 flashfrogluo/second-take
set -euo pipefail

REPO="${REPO:-flashfrogluo/second-take}"
VERSION=""
FROM_LOCAL=0
TARGET=""

while [ $# -gt 0 ]; do
  case "$1" in
    --from-local) FROM_LOCAL=1; shift ;;
    --version)    [[ $# -ge 2 && -n "$2" && "$2" != --* ]] || { echo "--version 缺少版本号" >&2; exit 2; }; VERSION="$2"; shift 2 ;;
    -h|--help)    sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)           echo "未知参数: $1" >&2; exit 2 ;;
    *)            TARGET="$1"; shift ;;
  esac
done
[[ "$REPO" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || { echo "无效仓库名称: $REPO" >&2; exit 2; }
if [[ -n "$VERSION" ]]; then
  [[ "$VERSION" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)?$ ]] || { echo "无效版本号: $VERSION" >&2; exit 2; }
  VERSION="${VERSION#v}"
fi
TARGET="${TARGET:-$HOME/.workbuddy/skills/second-take}"
SRC="$(cd "$(dirname "$0")" && pwd)"

# Use this installer's reviewed list, including for older downloaded releases.
PACKAGER="$SRC/scripts/package_files.py"
command -v python3 >/dev/null || { echo "需要 python3" >&2; exit 1; }

install_from() {
  local from="$1"
  echo "==> 安装到: $TARGET"
  python3 "$PACKAGER" "$from" "$TARGET" --allow-legacy
}

if [ "$FROM_LOCAL" -eq 1 ]; then
  echo "==> 从本地目录安装: $SRC"
  install_from "$SRC"
else
  command -v curl >/dev/null || { echo "远端安装需要 curl" >&2; exit 1; }
  command -v unzip >/dev/null || { echo "远端安装需要 unzip" >&2; exit 1; }
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  BASE="${DOWNLOAD_BASE:-https://github.com/$REPO/releases}"

  # Pin the default to the latest published tag, never silently fall back to main.
  if [[ -z "$VERSION" ]]; then
    curl -fsSL -m 30 "https://api.github.com/repos/$REPO/releases/latest" -o "$TMP/latest.json" \
      || { echo "无法获取最新正式 Release；可用 --version 指定已发布版本" >&2; exit 1; }
    VERSION="$(python3 - "$TMP/latest.json" <<'PYVERSION'
import json, re, sys
from pathlib import Path
try:
    tag = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))['tag_name']
    if not re.fullmatch(r'v[0-9]+\.[0-9]+\.[0-9]+(?:[-+][0-9A-Za-z.-]+)?', tag):
        raise ValueError('bad tag')
    print(tag[1:])
except (KeyError, ValueError, OSError, TypeError):
    sys.exit(1)
PYVERSION
)" || { echo "最新 Release 的 Tag 无效；已停止，不会改装 main" >&2; exit 1; }
  fi

  GOT=0
  for cand in "$BASE/download/v$VERSION/second-take-latest.zip" \
              "$BASE/download/v$VERSION/second-take-$VERSION.zip"; do
    echo "==> 尝试 Release 附件: $cand"
    rm -rf "$TMP/src"; rm -f "$TMP/pkg.zip"
    curl -fsSL -m 180 --retry 5 --retry-all-errors "$cand" -o "$TMP/pkg.zip" 2>/dev/null || continue
    unzip -q "$TMP/pkg.zip" -d "$TMP/src" 2>/dev/null || continue
    if [[ -f "$TMP/src/SKILL.md" ]]; then
      SRC="$TMP/src"
    else
      SRC="$(find "$TMP/src" -maxdepth 2 -name SKILL.md -print -quit 2>/dev/null | xargs -r dirname)"
    fi
    if [[ -f "${SRC:-}/SKILL.md" ]]; then
      actual="$(sed -n -E 's/^[[:space:]]*version:[[:space:]]*"?([^"[:space:]]+)"?.*$/\1/p' "$SRC/SKILL.md" | head -n 1)"
      if [[ "$actual" = "$VERSION" ]]; then GOT=1; break; fi
      echo "    — 附件版本 $actual 与目标 $VERSION 不一致，拒绝安装" >&2
    fi
    SRC=""
  done

  if [[ "$GOT" -eq 0 ]]; then
    echo "==> Release 附件不可用，改用同版本 Tag 源码包: v$VERSION"
    curl -fsSL -m 180 "https://codeload.github.com/$REPO/tar.gz/refs/tags/v$VERSION" -o "$TMP/pkg.tar.gz" \
      || { echo "无法获取 v$VERSION；不会静默安装 main" >&2; exit 1; }
    rm -rf "$TMP/src"; mkdir -p "$TMP/src"
    tar -xzf "$TMP/pkg.tar.gz" -C "$TMP/src" --strip-components=1
    SRC="$TMP/src"
  fi

  actual="$(sed -n -E 's/^[[:space:]]*version:[[:space:]]*"?([^"[:space:]]+)"?.*$/\1/p' "$SRC/SKILL.md" | head -n 1)"
  [[ "$actual" = "$VERSION" ]] || { echo "下载版本 $actual 与目标 $VERSION 不一致，停止安装" >&2; exit 1; }
  install_from "$SRC"
fi

echo "==> 完成。在支持 agentskills.io 的 agent 里即可调用 second-take。"
echo "    或运行: npx skills add $REPO"
