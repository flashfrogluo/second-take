#!/usr/bin/env bash
# second-take 影响力统计：GitHub + skills.sh + release 下载量
#
# 为什么要本地存历史：GitHub Traffic 只有 14 天窗口，过期即永久丢失；
# 星标/安装量的「增速」比总数更能说明影响力，而增速必须有历史快照才算得出来。
#
# 用法：
#   ./stats.sh                 正常采集
#   ./stats.sh --no-write      只打印，不写历史
#   ./stats.sh --history       只打印已有历史表
#
# 环境变量：
#   GITHUB_TOKEN   可选。未设置时走匿名 API（每小时 60 次限额，足够本脚本）；
#                  设置后还能读到 Traffic（访客/克隆），且限额提到 5000。
set -euo pipefail

REPO="${REPO:-flashfrogluo/second-take}"
SKILL_ID="${SKILL_ID:-flashfrogluo/second-take}"
SKILL_NAME="${SKILL_NAME:-second-take}"
OUT_DIR="${OUT_DIR:-$(cd "$(dirname "$0")" && pwd)/../metrics}"

NO_WRITE=0
ONLY_HISTORY=0
for arg in "$@"; do
  case "$arg" in
    --no-write)   NO_WRITE=1 ;;
    --history)    ONLY_HISTORY=1 ;;
    -h|--help)    sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "未知参数: $arg" >&2; exit 2 ;;
  esac
done

mkdir -p "$OUT_DIR"
HIST_JSONL="$OUT_DIR/history.jsonl"
LATEST_MD="$OUT_DIR/latest.md"

# ---------- 依赖检查 ----------
missing=0
for c in curl python3; do
  command -v "$c" >/dev/null 2>&1 || { echo "缺少依赖: $c" >&2; missing=1; }
done
[ "$missing" -eq 0 ] || { echo "请先安装上述命令后重试。" >&2; exit 1; }

if [ "$ONLY_HISTORY" -eq 1 ]; then
  # 历史文件可能不在默认位置——定时任务用 OUT_DIR 写到了 ~/.local/share。
  # 按序查找：显式 OUT_DIR > 默认位置 > 定时任务的数据目录。
  if [ ! -f "$HIST_JSONL" ]; then
    for cand in \
      "$HOME/.local/share/second-take-metrics/history.jsonl" \
      "$OUT_DIR/history.jsonl"
    do
      if [ -f "$cand" ]; then
        HIST_JSONL="$cand"
        echo "（历史文件: $cand）"
        break
      fi
    done
  fi
  [ -f "$HIST_JSONL" ] || {
    echo "尚无历史记录。已找过："
    echo "  $OUT_DIR/history.jsonl"
    echo "  $HOME/.local/share/second-take-metrics/history.jsonl"
    echo "先跑一次 ./stats.sh，或安装定时任务（schedule/install-schedule.sh）。"
    exit 0
  }
  python3 - "$HIST_JSONL" <<'PY'
import json, sys
rows = [json.loads(l) for l in open(sys.argv[1], encoding='utf-8') if l.strip()]
if not rows:
    print("历史为空"); sys.exit()

def num(r, k):
    """只把「确实没有这项数据」(None) 显示为 '-'；真实的 0 照实显示。"""
    v = r.get(k)
    return '-' if v is None else str(v)

hdr = f"{'日期':<12}{'stars':>7}{'forks':>7}{'watch':>7}{'installs':>10}{'dl':>8}"
print(hdr); print('-' * len(hdr))
for r in rows:
    print(f"{num(r,'date'):<12}{num(r,'stars'):>7}{num(r,'forks'):>7}"
          f"{num(r,'watchers'):>7}{num(r,'installs'):>10}{num(r,'downloads'):>8}")
if len(rows) >= 2:
    a, b = rows[0], rows[-1]
    print(f"\n窗口: {a.get('date')} → {b.get('date')}")
    for k, label in (('stars','星标'), ('forks','Fork'), ('watchers','关注'), ('installs','安装量')):
        av, bv = a.get(k), b.get(k)
        if bv is None:
            print(f"  {label:<6} —（最新采样点没有这项数据）")
            continue
        # 安装量特殊：窗口起点未收录时，以窗口内第一个已收录点为基准
        if av is None:
            pts = [r.get('installs') for r in rows if r.get('installs') is not None]
            if not pts:
                print(f"  {label:<6} —（窗口内始终未收录）")
                continue
            av = pts[0]
        d = bv - av
        print(f"  {label:<6} +{d}" if d >= 0 else f"  {label:<6} {d}")
PY
  exit 0
fi

# ---------- 采集 ----------
# 注意：不要写成「空数组 + "${arr[@]}"」——set -u 下空数组展开会报 unbound variable。
# 用函数在内部决定是否带 Authorization 头。
gh_api() {
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    curl -sS -m 30 -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github+json" "$@"
  else
    curl -sS -m 30 -H "Accept: application/vnd.github+json" "$@"
  fi
}

echo "==> 采集 GitHub 仓库数据: $REPO"
REPO_JSON="$(gh_api "https://api.github.com/repos/$REPO")" \
  || { echo "GitHub API 请求失败" >&2; exit 1; }

echo "==> 采集 releases 下载量"
RELEASES_JSON="$(gh_api "https://api.github.com/repos/$REPO/releases?per_page=100" || echo '[]')"

TRAFFIC_JSON='null'
if [ -n "${GITHUB_TOKEN:-}" ]; then
  echo "==> 采集 Traffic（14 天窗口，需 token）"
  TRAFFIC_JSON="$(gh_api "https://api.github.com/repos/$REPO/traffic/views" || echo 'null')"
fi

echo "==> 采集 skills.sh 安装量"
SKILLSH_JSON="$(curl -sS -m 30 \
  "https://www.skills.sh/api/search?q=$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$SKILL_NAME")" || echo '{}')"

# 索引正身判定：搜索接口是模糊匹配，可能给出同名无关结果，不足以证明已收录。
# /api/download 是权威信号——已收录返回 200，未收录 404（索引直接服务该路径）。
echo "==> 校验 skills.sh 索引状态"
INDEX_HTTP="$(curl -s -o /dev/null -m 30 -w '%{http_code}' \
  "https://www.skills.sh/api/download/$SKILL_ID/$SKILL_NAME" || echo '000')"
export INDEX_HTTP

REGISTRY_JSON="$(curl -sS -m 30 \
  "https://registry.npmjs.org/skills" || echo '{}')"

# ---------- 汇总 ----------
export REPO_JSON RELEASES_JSON TRAFFIC_JSON SKILLSH_JSON REGISTRY_JSON
export SKILL_ID SKILL_NAME REPO
SUMMARY="$(python3 <<'PY'
import json, os, datetime

def load(name, default):
    raw = os.environ.get(name, '')
    try:
        return json.loads(raw) if raw.strip() else default
    except Exception:
        return default

repo = load('REPO_JSON', {})
if not isinstance(repo, dict) or 'stargazers_count' not in repo:
    msg = repo.get('message') if isinstance(repo, dict) else None
    raise SystemExit(f"GitHub 返回异常：{msg or '未知错误'}（检查仓库名或 API 限额）")

releases = load('RELEASES_JSON', [])
if not isinstance(releases, list):
    releases = []
traffic = load('TRAFFIC_JSON', None)
skillsh = load('SKILLSH_JSON', {})
registry = load('REGISTRY_JSON', {})

skill_id = os.environ.get('SKILL_ID', '')
skill_name = os.environ.get('SKILL_NAME', '')

# release 资产明细
assets = []
downloads = 0
for r in releases:
    for a in r.get('assets', []):
        c = a.get('download_count', 0)
        downloads += c
        assets.append({'release': r.get('tag_name'), 'name': a.get('name'), 'downloads': c})

# skills.sh：在搜索结果里精确匹配本仓库
installs, rank_hit = None, None
res = skillsh.get('skills') if isinstance(skillsh, dict) else None
if isinstance(res, list):
    for i, s in enumerate(res, 1):
        sid = str(s.get('id', ''))
        if sid == f"{skill_id}/{skill_name}" or sid.startswith(skill_id + '/'):
            installs = s.get('installs')
            rank_hit = i
            break
    if installs is None:
        # 退一步：source 字段匹配
        for i, s in enumerate(res, 1):
            if str(s.get('source', '')) == skill_id:
                installs = s.get('installs')
                rank_hit = i
                break

npm_dl = None
if isinstance(registry, dict):
    try:
        npm_dl = registry['downloads']['last-month']
    except Exception:
        npm_dl = None

out = {
    'date': datetime.date.today().isoformat(),
    'repo': os.environ.get('REPO', ''),
    'stars': repo.get('stargazers_count', 0),
    'forks': repo.get('forks_count', 0),
    'watchers': repo.get('subscribers_count', 0),
    'open_issues': repo.get('open_issues_count', 0),
    'releases': len(releases),
    'downloads': downloads,
    'assets': assets,
    'installs': installs,
    'installs_rank_in_search': rank_hit,
    'installs_indexed': installs is not None,
    'index_download_http': os.environ.get('INDEX_HTTP', '000'),
    'index_listed': os.environ.get('INDEX_HTTP', '') == '200',
    'npm_skills_last_month': npm_dl,
    'traffic_14d_views': (traffic or {}).get('count') if isinstance(traffic, dict) else None,
    'traffic_14d_uniques': (traffic or {}).get('uniques') if isinstance(traffic, dict) else None,
}
print(json.dumps(out, ensure_ascii=False))
PY
)" || exit 1

# ---------- 输出 ----------
python3 - "$SUMMARY" <<'PY'
import json, sys
d = json.loads(sys.argv[1])
print()
print("=" * 56)
print(f"  second-take 影响力快照 · {d['date']}")
print("=" * 56)
print(f"  星标 Star        {d['stars']:>8}     ← 收藏 / 受喜欢程度")
print(f"  Fork             {d['forks']:>8}")
print(f"  关注 Watch       {d['watchers']:>8}     （页面上不显示，仅你可见）")
print(f"  Open issues      {d['open_issues']:>8}")
print(f"  Releases         {d['releases']:>8}")
print(f"  Release 下载量   {d['downloads']:>8}")
listed = d.get('index_listed')
if listed:
    print(f"  skills.sh 收录   {'已收录':>8}     （/api/download 返回 200）")
elif listed is False:
    print(f"  skills.sh 收录   {'未收录':>8}     （/api/download 返回 {d.get('index_download_http')}）")
if d['installs_indexed']:
    print(f"  skills.sh 安装量 {d['installs']:>8}     ← 真实使用量")
if d.get('npm_skills_last_month') is not None:
    print(f"  skills CLI 月下载 {d['npm_skills_last_month']:>7}")
if d.get('traffic_14d_views') is not None:
    print(f"  14 天访客        {d['traffic_14d_uniques']:>8} 独立 / {d['traffic_14d_views']} 次浏览")
elif d['traffic_14d_views'] is None:
    print(f"  14 天访客        {'—':>8}     （设置 GITHUB_TOKEN 可读）")
print("=" * 56)
if d['assets']:
    print("  附件明细：")
    for a in d['assets']:
        print(f"    {a['release']:<12} {a['name']:<32} {a['downloads']:>6} 次")
if not d.get('index_listed'):
    print()
    print("  索引未生效。机理（已由维护者确认）：")
    print("    收录由「一次成功的安装」触发——CLI 安装后上报")
    print("    add-skill.vercel.sh/t?event=install&source=<owner/repo>&skills=<name>，")
    print("    服务端据此建索引，按自己的周期重爬，不即时生效。")
    print("    触发方式（本机走归档 URL，绕开 git clone 故障）：")
    print("      npx -y skills@latest add \\")
    print("        https://codeload.github.com/flashfrogluo/second-take/tar.gz/refs/heads/main \\")
    print("        -s second-take -a universal -y")
    print("    不要提 indexing issue——机器人会回复「No manual reindex request is needed」并关闭。")
if not d['releases']:
    print()
    print("  ⚠  尚无 release，因此没有可统计的下载量。跑 scripts/release.sh 发一个。")
PY

if [ "$NO_WRITE" -eq 1 ]; then
  echo
  echo "(--no-write：未写入历史)"
  exit 0
fi

printf '%s\n' "$SUMMARY" >> "$HIST_JSONL"
python3 - "$SUMMARY" > "$LATEST_MD" <<'PY'
import json, sys
d = json.loads(sys.argv[1])
print(f"# second-take 影响力快照 · {d['date']}\n")
print("| 指标 | 数值 | 说明 |")
print("|---|---:|---|")
print(f"| 星标 Star | {d['stars']} | 收藏 / 受喜欢程度 |")
print(f"| Fork | {d['forks']} | |")
print(f"| 关注 Watch | {d['watchers']} | 仅仓库所有者可见 |")
print(f"| Open issues | {d['open_issues']} | |")
print(f"| Releases | {d['releases']} | |")
print(f"| Release 下载量 | {d['downloads']} | 仅附件可统计 |")
print(f"| skills.sh 安装量 | {d['installs'] if d['installs_indexed'] else '未收录'} | 真实使用量 |")
if d.get('npm_skills_last_month') is not None:
    print(f"| skills CLI 月下载 | {d['npm_skills_last_month']} | 生态热度参考 |")
print()
if d['assets']:
    print("## 附件下载明细\n")
    print("| Release | 附件 | 下载量 |")
    print("|---|---|---:|")
    for a in d['assets']:
        print(f"| {a['release']} | {a['name']} | {a['downloads']} |")
PY

echo
echo "  历史已追加: $HIST_JSONL"
echo "  最新快照:   $LATEST_MD"
echo "  看增速趋势: ./stats.sh --history"
