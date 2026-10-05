#!/usr/bin/env bash
# 用 GitHub Contents API 把本次改动推到 flashfrogluo/second-take。
#
# 为什么不用 git：这台机器对 github.com 的 git 传输被阻断
#   （git ls-remote https://github.com → HTTP2 framing error / Empty reply，
#     而同一 git 对 gitee.com 正常），所以改走纯 HTTPS 的 Contents API。
#
# 用法：
#   export GITHUB_TOKEN=github_pat_xxx
#   ./push-to-github.sh --dry-run   打印将提交的文件清单（不写远端）
#   ./push-to-github.sh --check     校验 token / 权限 / 远端 sha（只读）
#   ./push-to-github.sh             正式提交
#
# token 权限：Fine-grained，仅 flashfrogluo/second-take，Contents: Read and write
set -euo pipefail

REPO="${REPO:-flashfrogluo/second-take}"
BRANCH="${BRANCH:-main}"
HERE="$(cd "$(dirname "$0")" && pwd)"
API="https://api.github.com/repos/$REPO/contents"

MODE=push
case "${1:-}" in
  --check)   MODE=check ;;
  --dry-run) MODE=dry ;;
  "")        ;;
  *)         echo "未知参数: $1" >&2; exit 2 ;;
esac

command -v python3 >/dev/null || { echo "需要 python3" >&2; exit 1; }
command -v curl    >/dev/null || { echo "需要 curl" >&2; exit 1; }

# ── 计划提交的内容 ────────────────────────────────────────────────────
# direct：本地已就绪，直接提交
# patch ：先取远端原文，再用补丁脚本就地改，然后提交（避免版本倒退）
# 格式：仓库路径|方式|本地源或补丁脚本|提交信息
PLAN=(
  "SKILL.md|patch|patch_description.py|feat(skill): description 检索词前置，保留原触发集"
  "install.sh|direct|scripts/install.sh|feat(install): Release 附件优先，回退 codeload"
  "update.sh|direct|scripts/update.sh|feat(update): 同 install 的双通路改造"
  "scripts/stats.sh|direct|scripts/stats.sh|feat(scripts): 影响力采集器 stats.sh"
  "scripts/release.sh|direct|scripts/release.sh|feat(scripts): 发版脚本 release.sh"
  "scripts/patch_readme.py|direct|scripts/patch_readme.py|feat(scripts): README 补丁脚本"
  "scripts/patch_description.py|direct|scripts/patch_description.py|feat(scripts): description 补丁脚本"
  "README.md|patch|patch_readme.py|docs: 真实计数徽章 + Star/Watch 引导 + 数据说明"
  "README_EN.md|patch|patch_readme.py|docs: same as README.md (EN)"
)

if [ "$MODE" = "dry" ]; then
  echo "==> 计划提交（仓库路径 | 方式 | 来源）"
  for row in "${PLAN[@]}"; do
    IFS='|' read -r path how src msg <<< "$row"
    if [ "$how" = "direct" ]; then
      if [ -f "$HERE/$src" ]; then
        printf "  %-30s direct  %-32s %6s 字节\n" "$path" "$src" "$(wc -c < "$HERE/$src" | tr -d ' ')"
      else
        printf "  %-30s direct  %-32s 缺失！\n" "$path" "$src"
      fi
    else
      printf "  %-30s patch   %-32s 远端原文 + 补丁\n" "$path" "$src"
    fi
  done
  echo
  echo "（dry-run：未发送写请求）"
  exit 0
fi

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "未设置 GITHUB_TOKEN" >&2
  echo "  export GITHUB_TOKEN=github_pat_xxx 后重试" >&2
  exit 1
fi

api_get() {
  curl -sS -m 30 --retry 5 --retry-all-errors --retry-delay 2 \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" "$API/$1?ref=$BRANCH"
}

remote_sha() {
  api_get "$1" | python3 -c '
import json,sys
try: d=json.load(sys.stdin)
except Exception: print(""); raise SystemExit
print(d.get("sha","") if isinstance(d,dict) else "")
'
}

if [ "$MODE" = "check" ]; then
  echo "==> 校验 token"
  curl -sS -m 30 -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" https://api.github.com/user \
  | python3 -c '
import json,sys
d=json.load(sys.stdin)
if "login" not in d:
    print("  token 无效:", d.get("message")); raise SystemExit(1)
print("  ✓ 认证为", d["login"])
'
  echo "==> 仓库写权限"
  curl -sS -m 30 -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" "https://api.github.com/repos/$REPO" \
  | python3 -c '
import json,sys
d=json.load(sys.stdin)
p=d.get("permissions",{})
print("  push:", p.get("push"), "| admin:", p.get("admin"))
if not p.get("push"):
    print("  ✗ 该 token 对本仓库没有写权限"); raise SystemExit(1)
'
  echo "==> 远端当前 sha"
  for row in "${PLAN[@]}"; do
    IFS='|' read -r path how src msg <<< "$row"
    printf "  %-30s %s\n" "$path" "$(remote_sha "$path" | cut -c1-12)"
  done
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fetch_remote() { # 仓库路径  输出目录
  local path="$1" outdir="$2" base
  base="$(basename "$path")"
  mkdir -p "$outdir"
  api_get "$path" > "$TMP/_resp.json"
  python3 - "$TMP/_resp.json" "$outdir/$base" "$path" <<'PY'
import base64, json, pathlib, sys
src, dest, path = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    d = json.load(open(src, encoding='utf-8'))
except Exception as e:
    print(f"  ✗ 取远端 {path} 失败：响应无法解析（{e}）"); raise SystemExit(1)
if 'content' not in d:
    print(f"  ✗ 取远端 {path} 失败：{d.get('message')}"); raise SystemExit(1)
pathlib.Path(dest).write_bytes(base64.b64decode(d['content']))
PY
}

put_file() { # 仓库路径  本地文件  提交信息
  local path="$1" lf="$2" msg="$3" sha code
  sha="$(remote_sha "$path")"
  python3 - "$lf" "$sha" "$path" "$msg" "$BRANCH" > "$TMP/_payload.json" <<'PY'
import base64, json, sys
lf, sha, path, msg, branch = sys.argv[1:6]
body = {"message": msg,
        "content": base64.b64encode(open(lf, 'rb').read()).decode(),
        "branch": branch}
if sha:
    body["sha"] = sha
print(json.dumps(body))
PY
  code="$(curl -sS -m 180 --retry 5 --retry-all-errors --retry-delay 2 -X PUT \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -H "Content-Type: application/json" \
    "$API/$path" --data-binary "@$TMP/_payload.json" \
    -o "$TMP/_resp2.json" -w '%{http_code}')"
  if [ "$code" = "200" ] || [ "$code" = "201" ]; then
    printf "  ✓ %-30s %s\n" "$path" "$( [ -n "$sha" ] && echo 更新 || echo 新建 )"
  else
    printf "  ✗ %-30s http=%s\n" "$path" "$code" >&2
    python3 -c 'import json,sys;d=json.load(open(sys.argv[1]));print("     ",d.get("message"),d.get("errors",""))' "$TMP/_resp2.json" 2>/dev/null || true
    return 1
  fi
}

echo "==> 开始提交（每个文件一次 commit，便于单独回滚）"
FAIL=0
for row in "${PLAN[@]}"; do
  IFS='|' read -r path how src msg <<< "$row"
  if [ "$how" = "direct" ]; then
    if [ -f "$HERE/$src" ]; then
      put_file "$path" "$HERE/$src" "$msg" || FAIL=1
    else
      echo "  - 跳过 $path（本地缺失 $src）"
    fi
  else
    work="$TMP/patch-$(echo "$path" | tr '/' '_')"
    if fetch_remote "$path" "$work"; then
      base="$(basename "$path")"
      if python3 "$HERE/scripts/$src" "$work" > "$TMP/_patch.log" 2>&1; then
        sed 's/^/    /' "$TMP/_patch.log"
        put_file "$path" "$work/$base" "$msg" || FAIL=1
      else
        echo "  ✗ $path 补丁失败：" >&2
        sed 's/^/      /' "$TMP/_patch.log" >&2
        FAIL=1
      fi
    else
      FAIL=1
    fi
  fi
done

echo
if [ "$FAIL" -eq 0 ]; then
  echo "==> 全部完成。提交历史： https://github.com/$REPO/commits/$BRANCH"
else
  echo "==> 有文件失败（见上方 ✗），其余已提交；重跑本脚本会补上失败项。" >&2
  exit 1
fi
