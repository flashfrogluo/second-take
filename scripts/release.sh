#!/usr/bin/env bash
# 发布 Release 并上传 zip 附件
#
# 为什么必须这么做：GitHub 不记录源码包（codeload）的下载次数，
# 只有 Release 附件才有 download_count。想让下载量可见、能上徽章，就必须发 release。
#
# 关键坑：覆盖同名附件会让该附件的计数归零。
# 所以本脚本禁止同名覆盖——每次发版必须用新 tag。
#
# 用法：
#   ./release.sh 1.7.1                       正式发布
#   ./release.sh 1.7.1 --dry-run             只打包，不碰 GitHub
#   ./release.sh 1.7.1 --notes "自定义说明"   覆盖 CHANGELOG 里抓的说明
#   ./release.sh 1.7.1 --repo owner/name     指定仓库（默认读 git remote）
#   ./release.sh 1.7.1 --root /path/to/repo  指定仓库根（默认脚本父目录）
#
# 环境变量：
#   GITHUB_TOKEN  必填（除非 --dry-run）。需要 repo 权限。
#   REPO          可选，等价于 --repo
set -euo pipefail

VERSION="${1:-}"
[ -n "$VERSION" ] || { sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
shift

DRY_RUN=0
NOTES=""
ASSET_OVERRIDE=""
ROOT_OVERRIDE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --notes)   NOTES="${2:-}"; shift 2 ;;
    --repo)    REPO="${2:-}"; shift 2 ;;
    --asset)   ASSET_OVERRIDE="${2:-}"; shift 2 ;;
    --root)    ROOT_OVERRIDE="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 2 ;;
  esac
done

# 归一化 tag：允许传 1.7.1 或 v1.7.1
TAG="v${VERSION#v}"
# 附件名用固定名 second-take-latest.zip：
#   install.sh 有「无版本号」通路，走 releases/latest/download/<固定名>，
#   版本化命名在那里匹配不上。固定名让带版本与不带版本两条通路都能命中。
# 需要版本化命名时用 --asset 覆盖。
ASSET="${ASSET_OVERRIDE:-second-take-latest.zip}"

# 仓库根：默认脚本的父目录。但必须真的是一份 skill 包（含 SKILL.md），
# 否则会打出「不含 SKILL.md 的畸形包」——装不上，且白占一次 release。
if [ -n "$ROOT_OVERRIDE" ]; then
  ROOT="$(cd "$ROOT_OVERRIDE" && pwd)"
else
  ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fi
if [ ! -f "$ROOT/SKILL.md" ]; then
  echo "✗ $ROOT 下没有 SKILL.md，不是一份 skill 包。" >&2
  echo "  这里很可能是「工具包目录」而非仓库根。" >&2
  echo "  用 --root /path/to/second-take 指定真正的仓库根，例如：" >&2
  echo "    $0 $VERSION --root \"$HOME/.agents/skills/second-take\"" >&2
  exit 1
fi
cd "$ROOT"

if [ -z "${REPO:-}" ]; then
  # 从 git remote 推出 owner/name。手工切分，避免 sed 扩展正则在不同平台的兼容问题。
  remote="$(git config --get remote.origin.url 2>/dev/null || true)"
  remote="${remote%.git}"
  case "$remote" in
    *github.com[:/]*) after="${remote#*github.com}" ;;
    *)                after="" ;;
  esac
  after="${after#:}"; after="${after#/}"
  owner="${after%%/*}"; rest="${after#*/}"
  repo_name="${rest%%/*}"
  if [ -n "$owner" ] && [ -n "$repo_name" ]; then
    REPO="$owner/$repo_name"
  fi
fi
[ -n "${REPO:-}" ] || { echo "无法确定仓库，请用 --repo owner/name 指定" >&2; exit 1; }

echo "==> 仓库: $REPO"
echo "==> 版本: $TAG"
echo "==> 附件: $ASSET"

# ---------- 前置检查 ----------
if [ -f SKILL.md ]; then
  ver="$(grep -m1 '^  version:' SKILL.md | sed -E 's/.*"([^"]+)".*/\1/')" || true
  if [ -n "${ver:-}" ] && [ "$ver" != "${TAG#v}" ]; then
    echo "⚠  SKILL.md 里的 version 是 $ver，与本次 $TAG 不一致。" >&2
    echo "   先改 SKILL.md 再发版，否则用户看到的版本号会对不上。" >&2
    exit 1
  fi
fi

if [ "$DRY_RUN" -eq 0 ]; then
  [ -n "${GITHUB_TOKEN:-}" ] || { echo "未设置 GITHUB_TOKEN" >&2; exit 1; }
  if git rev-parse --git-dir >/dev/null 2>&1; then
    if [ -n "$(git status --porcelain)" ]; then
      echo "⚠  工作区有未提交改动。建议先提交，否则 release 内容与仓库状态不一致。" >&2
      printf "   继续？(y/N) "; read -r ans
      [ "$ans" = "y" ] || [ "$ans" = "Y" ] || exit 1
    fi
    if git rev-parse "$TAG" >/dev/null 2>&1; then
      echo "✗ tag $TAG 已存在。换新版本号——原地覆盖附件会把下载量清零。" >&2
      exit 1
    fi
  else
    echo "（非 git 仓库，跳过提交状态与 tag 检查）"
  fi
fi

# ---------- 打包 ----------
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
STAGE="$TMP/second-take"
mkdir -p "$STAGE"

echo "==> 打包（排除版本控制与临时文件）"
EXCLUDES=(.git '.apply-backup-*' '.sync-backup-*' '.write-backup-*' metrics node_modules __pycache__ '*.pyc' .DS_Store '*.log' 'second-take-*.zip' MANIFEST.txt cases DEVLOG.md)
for item in .[!.]* *; do
  [ -e "$item" ] || continue
  skip=0
  for ex in "${EXCLUDES[@]}"; do
    case "$item" in $ex|$ex/*) skip=1; break ;; esac
  done
  [ "$skip" -eq 1 ] && continue
  cp -R "$item" "$STAGE/"
done

# 清单便于核对
( cd "$STAGE" && find . -type f | sed 's|^\./||' | sort > MANIFEST.txt )
FILE_COUNT="$(wc -l < "$STAGE/MANIFEST.txt" | tr -d ' ')"
( cd "$TMP" && zip -qr "$ASSET" second-take )
SIZE="$(du -h "$TMP/$ASSET" | cut -f1 | tr -d ' ')"
echo "    文件数 $FILE_COUNT，压缩包 $SIZE"

if [ "$DRY_RUN" -eq 1 ]; then
  cp "$TMP/$ASSET" "$ROOT/$ASSET"
  echo
  echo "==> dry-run 完成，未接触 GitHub。"
  echo "    产物: $ROOT/$ASSET"
  echo "    清单前 10 行:"
  head -10 "$STAGE/MANIFEST.txt" | sed 's/^/      /'
  exit 0
fi

# ---------- 发布说明 ----------
if [ -z "$NOTES" ] && [ -f CHANGELOG.md ]; then
  NOTES="$(awk -v v="${TAG#v}" '
    $0 ~ "^## \\[" v "\\]" {flag=1; next}
    flag && /^## \[/ {exit}
    flag {print}
  ' CHANGELOG.md)"
  [ -n "$NOTES" ] && echo "==> 发布说明取自 CHANGELOG [$TAG]"
fi
[ -n "$NOTES" ] || NOTES="本次更新内容见 CHANGELOG.md"

PAYLOAD_NOTES="$(python3 -c 'import json,sys;print(json.dumps(sys.stdin.read()))' <<< "$NOTES")"

# ---------- 创建 release ----------
echo "==> 创建 release $TAG"
RESP="$(curl -sS -m 60 -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$REPO/releases" \
  -d "{\"tag_name\":\"$TAG\",\"name\":\"$TAG\",\"body\":$PAYLOAD_NOTES,\"draft\":false,\"prerelease\":false}")"

UPLOAD_URL="$(python3 -c '
import json,sys
d=json.loads(sys.stdin.read())
if "upload_url" not in d:
    raise SystemExit("创建 release 失败：" + str(d.get("message") or d))
print(d["upload_url"].split("{")[0])
' <<< "$RESP")" || exit 1

echo "==> 上传附件 $ASSET"
UP_RESP="$(curl -sS -m 300 -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/zip" \
  --data-binary "@$TMP/$ASSET" \
  "$UPLOAD_URL?name=$ASSET")"

python3 -c '
import json,sys
d=json.loads(sys.stdin.read())
if "browser_download_url" not in d:
    raise SystemExit("上传失败：" + str(d.get("message") or d))
print("==> 已发布:", d["browser_download_url"])
' <<< "$UP_RESP" || exit 1

# ---------- 回显下载量 ----------
echo
echo "==> 当前 Release 下载量"
curl -sS -m 30 -H "Authorization: Bearer $GITHUB_TOKEN" \
  "https://api.github.com/repos/$REPO/releases" \
  | python3 -c '
import json,sys
for r in json.load(sys.stdin):
    print("  %-10s %s" % (r["tag_name"], r["name"]))
    for a in r.get("assets", []):
        print("      %-34s %6d 次" % (a["name"], a["download_count"]))
'

cat <<EOF

==> 收尾清单
  1. 推送 tag（若本地未推）: git push origin $TAG
  2. README 的 downloads 徽章会自动开始计数
  3. 检查 install.sh / update.sh 的下载地址是否指向本次 release 附件
  4. 下次发版换新版本号——覆盖同名附件会把上面的计数清零
EOF
