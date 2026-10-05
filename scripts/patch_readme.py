#!/usr/bin/env python3
# 给 README.md / README_EN.md 打补丁：
#   1) 徽章区：改掉写死的假 skills.sh 徽章，换成会真实计数的徽章
#   2) 在安装命令下方插入 Star / Watch 引导（转化入口）
#   3) 文件末尾追加「关于数据与统计」小节（说明去哪看增长、怎么贡献数据）
#
# 用法：
#   python3 patch_readme.py <repo_dir>           写入
#   python3 patch_readme.py <repo_dir> --dry-run 只打印将要发生的改动
import re
import sys
from pathlib import Path

BADGE_OLD_CN = '[![skills.sh](https://img.shields.io/badge/skills.sh-indexed-brightgreen)](https://skills.sh)'
BADGE_OLD_EN = BADGE_OLD_CN

# 说明：原来那枚 skills.sh 徽章是写死的静态徽章，不反映任何真实状态，换掉。
# 这里不把 skills.sh 安装量做成动态徽章——skills.sh 只按文本匹配检索，未收录时会渲染成
# "not found"，比不做徽章更难看。等确认收录后再单独加。
BADGE_NEW = '\n'.join([
    '[![Downloads](https://img.shields.io/github/downloads/flashfrogluo/second-take/total?style=flat&logo=github)](https://github.com/flashfrogluo/second-take/releases)',
    '[![Last commit](https://img.shields.io/github/last-commit/flashfrogluo/second-take?style=flat)](https://github.com/flashfrogluo/second-take/commits/main)',
])

CTA_CN = """
> ⭐ **如果这个 skill 对你有用，点一下右上角的 Star** —— 它会进入你账号的 Stars 列表，方便随时找回；点 **Watch** 可以订阅版本更新与讨论。<br>
> 安装量由 `npx skills add` 的 CLI 遥测统计（可用 `DISABLE_TELEMETRY=1` 关闭），每装一次记一次。你的一次安装就是最直接的反馈。
"""

CTA_EN = """
> ⭐ **If this skill is useful to you, please hit Star** — it lands in your Stars list so you can find it again; hit **Watch** to subscribe to releases and discussions.<br>
> Installs are counted via `npx skills add` CLI telemetry (opt out with `DISABLE_TELEMETRY=1`). Each install is recorded once — one install from you is the most direct feedback.
"""

STATS_CN = """
## 关于数据与统计

这个项目关注三类数据，各自来源不同：

| 数据 | 来源 | 说明 |
|---|---|---|
| 星标 / Fork / 关注 | GitHub 仓库页 | Star 即「收藏」，Watch 是订阅更新；Watch 数只有仓库所有者可见 |
| 安装量 | skills.sh（`npx skills add` 的 CLI 遥测） | 反映**真实使用**，比 Star 更接近实际采用度 |
| Release 下载量 | GitHub Releases 附件 | 源码包（Code → Download ZIP）不计入，只有 Release 附件计数 |

维护者可运行 `scripts/stats.sh` 采集并留存历史（GitHub Traffic 只有 14 天窗口，不存即永久丢失），运行 `scripts/release.sh` 发版并查看下载量。
"""

STATS_EN = """
## Data and metrics

Three kinds of numbers matter here, each from a different source:

| Metric | Source | Notes |
|---|---|---|
| Stars / forks / watchers | GitHub repository page | A star is the closest thing to a "favorite"; watcher count is visible only to the owner |
| Installs | skills.sh (CLI telemetry from `npx skills add`) | Closest proxy for **real usage**, more honest than stars |
| Release downloads | GitHub release assets | Source archives (Code → Download ZIP) are never counted; only release assets are |

Maintainers can run `scripts/stats.sh` to collect and retain history (GitHub Traffic only covers 14 days — unrecorded means lost), and `scripts/release.sh` to publish a release and read download counts.
"""


def patch(path: Path, is_en: bool, dry: bool) -> bool:
    text = path.read_text(encoding="utf-8")
    orig = text

    # 1) 徽章
    if BADGE_OLD_CN in text:
        text = text.replace(BADGE_OLD_CN, BADGE_NEW, 1)
        print(f"  [{path.name}] 徽章已替换（去掉写死的 skills.sh indexed，换为 Downloads + Last commit）")
    else:
        print(f"  [{path.name}] ⚠ 未找到原 skills.sh 徽章，跳过徽章替换")

    # 2) Star/Watch 引导：插在 npx 安装代码块之后
    if "点一下右上角的 Star" in text or "please hit Star" in text:
        print(f"  [{path.name}] Star/Watch 引导已存在，跳过")
    else:
        m = re.search(r"```bash\nnpx skills add flashfrogluo/second-take\n```\n", text)
        if m:
            cta = CTA_EN if is_en else CTA_CN
            text = text[: m.end()] + cta + text[m.end():]
            print(f"  [{path.name}] 已在安装命令后插入 Star/Watch 引导")
        else:
            print(f"  [{path.name}] ⚠ 未找到 npx 安装代码块，跳过引导插入")

    # 3) 数据说明小节
    if "## 关于数据与统计" in text or "## Data and metrics" in text:
        print(f"  [{path.name}] 数据说明小节已存在，跳过")
    else:
        text = text.rstrip("\n") + "\n" + (STATS_EN if is_en else STATS_CN)
        print(f"  [{path.name}] 已在末尾追加「数据与统计」小节")

    if text == orig:
        print(f"  [{path.name}] 无改动")
        return False
    if dry:
        print(f"  [{path.name}] (dry-run) 将写入 {len(text) - len(orig):+d} 字符")
        return True
    path.write_text(text, encoding="utf-8")
    print(f"  [{path.name}] 已写入（{len(text) - len(orig):+d} 字符）")
    return True


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dry = "--dry-run" in sys.argv
    if not args:
        print(__doc__)
        return 2
    root = Path(args[0]).expanduser().resolve()
    print(f"==> 目标仓库: {root}{'（dry-run）' if dry else ''}")
    for name, is_en in (("README.md", False), ("README_EN.md", True)):
        p = root / name
        if not p.exists():
            print(f"  [{name}] 不存在，跳过")
            continue
        patch(p, is_en, dry)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
