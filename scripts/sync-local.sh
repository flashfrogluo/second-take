#!/usr/bin/env bash
# 把 GitHub 上的 second-take 最新版同步到本地安装副本
# 目标: ~/.agents/skills/second-take（DSH 读取 skill 的位置）
#
# 为什么单独写这个：本地那份是解压安装的，不是 git 检出，
#   而本机 git clone 对 github.com 间歇性失败，所以走 codeload 归档。
#
# 用法：
#   ./sync-local.sh --diff     只显示差异（不写）
#   ./sync-local.sh            同步（会自动备份被覆盖的文件）
#
# 注意：目标目录在工作区外，沙箱下可能被拒；请在普通终端执行。
set -euo pipefail

REPO="${REPO:-flashfrogluo/second-take}"
DEST="${DEST:-$HOME/.agents/skills/second-take}"
REF="${REF:-main}"

PACKAGER="$(cd "$(dirname "$0")" && pwd)/package_files.py"
DIFF_ONLY=0
[ "${1:-}" = "--diff" ] && DIFF_ONLY=1

command -v curl >/dev/null || { echo "需要 curl" >&2; exit 1; }
command -v tar  >/dev/null || { echo "需要 tar" >&2; exit 1; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

echo "==> 下载 $REPO@$REF（走 codeload，避开 git clone）"
URL="https://codeload.github.com/$REPO/tar.gz/refs/heads/$REF"
curl -fsSL -m 180 --retry 5 --retry-all-errors "$URL" -o "$TMP/src.tar.gz" \
  || { echo "下载失败：$URL" >&2; exit 1; }
mkdir -p "$TMP/src"
tar -xzf "$TMP/src.tar.gz" -C "$TMP/src" --strip-components=1
[ -f "$TMP/src/SKILL.md" ] || { echo "归档内容异常，未找到 SKILL.md" >&2; exit 1; }
echo "  已解压到临时目录"

if [ ! -d "$DEST" ]; then
  echo "✗ 目标不存在: $DEST" >&2
  echo "  如果是首次安装，改用: bash $(dirname "$0")/../install.sh $DEST" >&2
  exit 1
fi

echo
echo "==> 差异（新增 / 变更）"
diff -rq "$TMP/src" "$DEST" 2>/dev/null | grep -v "^Only in $DEST: \.apply-backup" | sed 's/^/  /' || echo "  无差异"

if [ "$DIFF_ONLY" -eq 1 ]; then
  echo
  echo "（--diff：未做任何写入）"
  exit 0
fi

python3 "$PACKAGER" "$TMP/src"
[ ! -L "$DEST" ] || { echo "目标不能是符号链接" >&2; exit 1; }
STAMP="$(date +%Y%m%d-%H%M%S)-$$"
BACKUP="$DEST/.sync-backup-$STAMP"
echo
echo "==> 备份现有文件到 $BACKUP"
mkdir -p "$BACKUP"
for item in "$DEST"/* "$DEST"/.[!.]*; do
  [ -e "$item" ] || continue
  base="$(basename "$item")"
  case "$base" in .sync-backup-*|.git) continue ;; esac
  cp -RP "$item" "$BACKUP/" || { echo "备份失败，未执行同步" >&2; exit 1; }
done

echo "==> 更新公开文件（保留本地额外文件）"
python3 "$PACKAGER" "$TMP/src" "$DEST"
echo "  ✓ 完成"

echo
echo "==> 结果"
grep -m1 '^  version:' "$DEST/SKILL.md" | sed 's/^/  版本:/'
ls "$DEST/scripts/" 2>/dev/null | sed 's/^/  scripts\//' || echo "  （仍无 scripts 目录）"
echo
echo "  回滚: cp -R $BACKUP/. $DEST/"
