#!/usr/bin/env bash
# Second Take 安装脚本
# 将本仓库装到各 agent 的 skills 目录。优先从 Release 附件安装（可统计下载量），
# Release 不可用时回退到 codeload tarball。
#
# 用法：
#   ./install.sh                          装到默认目录
#   ./install.sh /path/to/skills/second-take   指定目标目录
#   ./install.sh --from-local             从当前仓库目录装（开发者自用）
#   ./install.sh --version 1.7.1          指定版本（默认取最新 release）
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
    --version)    VERSION="${2:-}"; shift 2 ;;
    -h|--help)    sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)           echo "未知参数: $1" >&2; exit 2 ;;
    *)            TARGET="$1"; shift ;;
  esac
done
TARGET="${TARGET:-$HOME/.workbuddy/skills/second-take}"
SRC="$(cd "$(dirname "$0")" && pwd)"

EXCLUDES=(.git .github/metrics node_modules __pycache__ metrics)

install_from() {
  local from="$1"
  echo "==> 安装到: $TARGET"
  mkdir -p "$TARGET"
  for item in "$from"/* "$from"/.[!.]*; do
    [ -e "$item" ] || continue
    local name; name="$(basename "$item")"
    local skip=0
    for ex in "${EXCLUDES[@]}"; do
      [ "$name" = "$ex" ] && skip=1 && break
    done
    [ "$skip" -eq 1 ] && continue
    cp -R "$item" "$TARGET/"
  done
}

if [ "$FROM_LOCAL" -eq 1 ]; then
  echo "==> 从本地目录安装: $SRC"
  install_from "$SRC"
else
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  GOT=0

  # 首选：Release 附件（这类下载才有 download_count）
  # DOWNLOAD_BASE 可用于自建中转/镜像，也便于本地测试回退逻辑
  BASE="${DOWNLOAD_BASE:-https://github.com/$REPO/releases}"
  if command -v curl >/dev/null 2>&1; then
    # 附件名有两种历史约定，按序尝试，避免「发版成功但装不上」：
    #   固定名（便于 latest 通路）  second-take-latest.zip
    #   版本名（release.sh 产出）   second-take-<版本>.zip
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
    # 判定成功必须同时满足：下载成功 + 解压成功 + 解压出有效的包根。
    # 只看「文件存在」会把畸形 zip 当成成功，正是这个脚本最容易骗过自己的地方。
    URL=""
    for cand in "${CANDIDATES[@]}"; do
      echo "==> 尝试 Release 附件: $cand"
      rm -rf "$TMP/src"; rm -f "$TMP/pkg.zip"
      curl -fsSL -m 180 --retry 5 --retry-all-errors "$cand" -o "$TMP/pkg.zip" 2>/dev/null || continue
      unzip -q "$TMP/pkg.zip" -d "$TMP/src" 2>/dev/null || continue
      # 兼容压缩包内多一层目录
      if [ -f "$TMP/src/SKILL.md" ]; then
        SRC="$TMP/src"
      else
        SRC="$(find "$TMP/src" -maxdepth 2 -name SKILL.md -print -quit 2>/dev/null | xargs -r dirname)"
      fi
      if [ -n "$SRC" ] && [ -f "$SRC/SKILL.md" ]; then
        URL="$cand"; GOT=1
        echo "    ✓ 已取得 release 附件"
        break
      fi
      echo "    — 附件内未找到 SKILL.md，继续尝试下一个"
      SRC=""
    done
    [ "$GOT" -eq 1 ] || echo "    — Release 附件不可用，回退到源码包"
  fi

  # 回退：codeload tarball（注意：这类下载 GitHub 不计数）
  if [ "$GOT" -eq 0 ]; then
    REF="${VERSION:+v${VERSION#v}}"; REF="${REF:-main}"
    echo "==> 下载源码包: $REPO@$REF"
    curl -fsSL -m 180 "https://codeload.github.com/$REPO/tar.gz/refs/heads/$REF" -o "$TMP/pkg.tar.gz" \
      || curl -fsSL -m 180 "https://codeload.github.com/$REPO/tar.gz/refs/tags/$REF" -o "$TMP/pkg.tar.gz"
    mkdir -p "$TMP/src" && tar -xzf "$TMP/pkg.tar.gz" -C "$TMP/src" --strip-components=1
    SRC="$TMP/src"
  fi

  install_from "$SRC"
fi

echo "==> 完成。在支持 agentskills.io 的 agent 里即可调用 second-take。"
echo "    或运行: npx skills add $REPO"
