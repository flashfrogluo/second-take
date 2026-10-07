#!/usr/bin/env bash
# Second Take 更新脚本：从 GitHub 拉取最新版并重装
# 优先 Release 附件（可统计下载量），失败回退 codeload tarball。
#
# 用法：
#   ./update.sh                        更新到默认目录
#   ./update.sh /path/to/skills/second-take
#   ./update.sh --version 1.7.0        固定到某版本
set -euo pipefail

REPO="${REPO:-flashfrogluo/second-take}"
VERSION=""
TARGET=""

while [ $# -gt 0 ]; do
  case "$1" in
    --version) VERSION="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)        echo "未知参数: $1" >&2; exit 2 ;;
    *)         TARGET="$1"; shift ;;
  esac
done
TARGET="${TARGET:-$HOME/.workbuddy/skills/second-take}"

TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

SRC=""
BASE="${DOWNLOAD_BASE:-https://github.com/$REPO/releases}"
if command -v curl >/dev/null 2>&1; then
  if [ -n "$VERSION" ]; then
    CANDIDATES=(
      "$BASE/download/v${VERSION#v}/second-take-latest.zip"
      "$BASE/download/v${VERSION#v}/second-take-${VERSION#v}.zip"
    )
  else
    CANDIDATES=(
      "$BASE/latest/download/second-take-latest.zip"
      "$BASE/latest/download/second-take.zip"
    )
  fi
  echo "==> 尝试 Release 附件 ..."
  for cand in "${CANDIDATES[@]}"; do
    rm -rf "$TMP/src"; rm -f "$TMP/pkg.zip"
    curl -fsSL -m 180 --retry 5 --retry-all-errors "$cand" -o "$TMP/pkg.zip" 2>/dev/null || continue
    unzip -q "$TMP/pkg.zip" -d "$TMP/src" 2>/dev/null || continue
    if [ -f "$TMP/src/SKILL.md" ]; then SRC="$TMP/src"
    else SRC="$(find "$TMP/src" -maxdepth 2 -name SKILL.md -print -quit 2>/dev/null | xargs -r dirname)"; fi
    if [ -n "$SRC" ] && [ -f "$SRC/SKILL.md" ]; then
      echo "    ✓ 已取得 release 附件（$cand）"
      break
    fi
    SRC=""
  done
fi

if [ -z "$SRC" ]; then
  REF="${VERSION:+v${VERSION#v}}"; REF="${REF:-main}"
  echo "==> 回退：下载源码包 $REPO@$REF（GitHub 不统计这类下载）"
  if command -v git >/dev/null 2>&1 \
     && git clone --depth=1 --branch "$REF" "https://github.com/$REPO.git" "$TMP/repo" >/dev/null 2>&1; then
    SRC="$TMP/repo"
  else
    curl -fsSL -m 180 "https://codeload.github.com/$REPO/tar.gz/refs/heads/$REF" -o "$TMP/pkg.tar.gz" \
      || curl -fsSL -m 180 "https://codeload.github.com/$REPO/tar.gz/refs/tags/$REF" -o "$TMP/pkg.tar.gz"
    mkdir -p "$TMP/src" && tar -xzf "$TMP/pkg.tar.gz" -C "$TMP/src" --strip-components=1
    SRC="$TMP/src"
  fi
fi

echo "==> 重装到: $TARGET"
mkdir -p "$TARGET"
for item in "$SRC"/* "$SRC"/.[!.]*; do
  [ -e "$item" ] || continue
  name="$(basename "$item")"
  case "$name" in .git|node_modules|__pycache__|metrics) continue ;; esac
  cp -R "$item" "$TARGET/"
done

echo "==> 更新完成。当前版本见 $TARGET/CHANGELOG.md"
grep -m1 '^  version:' "$TARGET/SKILL.md" 2>/dev/null | sed 's/^/    /' || true
