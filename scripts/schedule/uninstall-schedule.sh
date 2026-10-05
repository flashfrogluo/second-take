#!/usr/bin/env bash
# 卸载 launchd 定时任务。默认保留已采集的历史数据，只摘掉定时器。
#
# 用法：
#   ./uninstall-schedule.sh            卸载定时任务（保留数据）
#   ./uninstall-schedule.sh --purge    连数据目录一起删掉
set -euo pipefail

LABEL="com.flashfrogluo.second-take-stats"
PLIST_DST="$HOME/Library/LaunchAgents/$LABEL.plist"
DATA_DIR="$HOME/.local/share/second-take-metrics"

PURGE=0
[ "${1:-}" = "--purge" ] && PURGE=1

echo "==> 卸载 $LABEL"
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null && echo "  ✓ bootout 成功" \
  || { launchctl unload -w "$PLIST_DST" 2>/dev/null && echo "  ✓ unload 成功" || echo "  · 未在运行"; }

if [ -f "$PLIST_DST" ]; then
  rm -f "$PLIST_DST"
  echo "  ✓ 已删除 $PLIST_DST"
fi

if [ "$PURGE" -eq 1 ]; then
  if [ -d "$DATA_DIR" ]; then
    rm -rf "$DATA_DIR"
    echo "  ✓ 已删除数据目录 $DATA_DIR"
  fi
else
  echo
  echo "  历史数据保留在: $DATA_DIR"
  echo "  想一起删掉就跑: $0 --purge"
fi
