#!/usr/bin/env bash
# Second Take 更新脚本：从 GitHub 拉取最新版并重装
set -euo pipefail

TARGET="${1:-$HOME/.workbuddy/skills/second-take}"
REPO="flashfrogluo/second-take"
TMP="$(mktemp -d)"

cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

echo "==> 从 GitHub 拉取 $REPO ..."
if command -v git >/dev/null 2>&1; then
  if git clone --depth=1 "https://github.com/$REPO.git" "$TMP/repo" >/dev/null 2>&1; then
    SRC="$TMP/repo"
  else
    echo "    git 克隆失败，改用 codeload tarball"
    curl -fsSL "https://codeload.github.com/$REPO/tar.gz/refs/heads/main" -o "$TMP/second-take.tar.gz"
    mkdir -p "$TMP/repo" && tar -xzf "$TMP/second-take.tar.gz" -C "$TMP/repo" --strip-components=1
    SRC="$TMP/repo"
  fi
else
  curl -fsSL "https://codeload.github.com/$REPO/tar.gz/refs/heads/main" -o "$TMP/second-take.tar.gz"
  mkdir -p "$TMP/repo" && tar -xzf "$TMP/second-take.tar.gz" -C "$TMP/repo" --strip-components=1
  SRC="$TMP/repo"
fi

echo "==> 重装到: $TARGET"
mkdir -p "$TARGET"
cp -R "$SRC/." "$TARGET/"
echo "==> 更新完成。当前版本见 $TARGET/CHANGELOG.md"
