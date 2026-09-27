#!/usr/bin/env bash
# Second Take 安装脚本
# 将本仓库装到各 agent 的 skills 目录。纯本地操作，无需网络。
set -euo pipefail

TARGET="${1:-$HOME/.workbuddy/skills/second-take}"
SRC="$(cd "$(dirname "$0")" && pwd)"

# 排除版本控制与临时文件
EXCLUDES=(.git .github node_modules __pycache__)

echo "==> 安装 Second Take 到: $TARGET"
mkdir -p "$TARGET"
for item in "$SRC"/* "$SRC"/.[!.]*; do
  name="$(basename "$item")"
  skip=0
  for ex in "${EXCLUDES[@]}"; do
    [ "$name" = "$ex" ] && skip=1 && break
  done
  [ "$skip" -eq 1 ] && continue
  cp -R "$item" "$TARGET/"
done
echo "==> 完成。在支持 agentskills.io 的 agent 里即可调用 second-take。"
echo "    或运行: npx skills add flashfrogluo/second-take"
