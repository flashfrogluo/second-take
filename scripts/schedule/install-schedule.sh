#!/usr/bin/env bash
# 安装 launchd 定时任务：每 6 小时采集一次 second-take 影响力快照
#
# 会做四件事：
#   1. 建数据目录 ~/.local/share/second-take-metrics
#   2. 复制 plist 到 ~/Library/LaunchAgents/
#   3. launchctl bootstrap 装载（并因 RunAtLoad 立刻跑一次）
#   4. 显示装载状态与前几条日志
#
# 注意：步骤 2/3 需要写工作区外的目录，沙箱下可能被拒；请在普通终端手动执行本脚本。
#
# 用法：
#   ./install-schedule.sh            安装
#   ./install-schedule.sh --dry-run  只检查前置条件与 plist 合法性
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
LABEL="com.flashfrogluo.second-take-stats"
PLIST_SRC="$HERE/$LABEL.plist"
AGENT_DIR="$HOME/Library/LaunchAgents"
PLIST_DST="$AGENT_DIR/$LABEL.plist"
DATA_DIR="$HOME/.local/share/second-take-metrics"
SKILL_DIR="$HOME/.agents/skills/second-take"

DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

echo "==> 前置检查"
fail=0
chk() { if eval "$2" >/dev/null 2>&1; then echo "  ✓ $1"; else echo "  ✗ $1"; fail=1; fi; }

chk "plist 源文件存在" "[ -f '$PLIST_SRC' ]"
chk "plist 语法合法" "plutil -lint '$PLIST_SRC'"
chk "采集脚本存在" "[ -x '$SKILL_DIR/scripts/stats.sh' ]"
chk "采集脚本语法合法" "bash -n '$SKILL_DIR/scripts/stats.sh'"
chk "curl 可用" "command -v curl"
chk "python3 可用" "command -v python3"

[ "$fail" -eq 0 ] || { echo; echo "前置检查未通过，先解决问题" >&2; exit 1; }

echo
echo "==> 计划"
echo "  定时: 每天 0/6/12/18 点的第 17 分钟（错过的会在唤醒后补跑）"
echo "  命令: $SKILL_DIR/scripts/stats.sh"
echo "  数据: $DATA_DIR/history.jsonl"
echo "  日志: $DATA_DIR/launchd.{out,err}.log"
echo "  代理: $PLIST_DST"

if [ "$DRY" -eq 1 ]; then
  echo
  echo "（dry-run：未做任何写入）"
  exit 0
fi

echo
echo "==> 建数据目录"
mkdir -p "$DATA_DIR"
echo "  $DATA_DIR"

echo "==> 安装 plist"
mkdir -p "$AGENT_DIR"
if [ -f "$PLIST_DST" ]; then
  cp "$PLIST_DST" "$PLIST_DST.bak.$(date +%s)"
  echo "  已备份旧文件"
fi
cp "$PLIST_SRC" "$PLIST_DST"
echo "  $PLIST_DST"

echo "==> 装载"
# 先卸载旧的（若存在），忽略错误
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
if launchctl bootstrap "gui/$(id -u)" "$PLIST_DST" 2>/dev/null; then
  echo "  ✓ bootstrap 成功"
else
  # 旧版 macOS 用 load
  launchctl load -w "$PLIST_DST" && echo "  ✓ load -w 成功"
fi

echo
echo "==> 装载状态"
launchctl print "gui/$(id -u)/$LABEL" 2>/dev/null | grep -E "state|program|runs|last exit" | head -8 \
  || echo "  （launchctl print 无输出，可稍后用 --status 查看）"

echo
echo "==> 等待 RunAtLoad 首次执行（最多 20 秒）"
for i in $(seq 1 20); do
  [ -f "$DATA_DIR/history.jsonl" ] && break
  sleep 1
done
if [ -f "$DATA_DIR/history.jsonl" ]; then
  echo "  ✓ 首次采集已完成，历史："
  python3 - "$DATA_DIR/history.jsonl" <<'PY'
import json, sys
rows=[json.loads(l) for l in open(sys.argv[1],encoding='utf-8') if l.strip()]
for r in rows[-2:]:
    print(f"    {r.get('date')}  stars={r.get('stars')} forks={r.get('forks')} "
          f"installs={r.get('installs')} 收录={r.get('index_listed')}")
PY
else
  echo "  ⚠ 尚未看到历史文件，检查日志："
  echo "    tail -20 $DATA_DIR/launchd.err.log"
fi

cat <<EOF

==> 完成

  查看历史与增速:  $SKILL_DIR/scripts/stats.sh --history
  本次日志:        tail -20 $DATA_DIR/launchd.out.log
  卸载:            $HERE/uninstall-schedule.sh
EOF
