#!/usr/bin/env python3
# 重写 README 首屏：把「这能解决我什么问题」提到最前面。
#
# 依据（GitHub Traffic 实测）：35 个独立访客停下、0 星标；且有人绕过 README
# 直接去翻 prompts/ 与 docs/ —— 说明访客要的是「现在能拿它干什么」和
# 「不用装就能试」，而原首屏先给品牌名与徽章、把价值说明压到很后面。
#
# 改法：把 hero 图之后、`## 为什么叫 Second Take` 之前整段替换为新首屏。
#   保留：徽章区、hero 图、「为什么叫」及之后所有内容。
#   新增：问题描述 + 前后对比表 + 不用安装的 30 秒试法 + 安装命令。
#
# 用法：
#   python3 patch_intro.py <repo_dir>            写入
#   python3 patch_intro.py <repo_dir> --dry-run  只显示将要替换的范围
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent

# 替换范围：hero 图那一行之后，到 `## 为什么叫 Second Take` 之前
START_PAT = re.compile(r'^\[!\[Second Take 主视觉.*?\n', re.M)
END_MARK_CN = '## 为什么叫 Second Take'
END_MARK_EN = '## Why it is called Second Take'


def load_snippet(name: str) -> str:
    # 脚本可能被放在 scripts/ 子目录里，也可能与文案同级，两处都找
    for base in (HERE, HERE / 'scripts'):
        p = base / 'readme-snippets' / name
        if p.exists():
            return p.read_text(encoding='utf-8')
    raise SystemExit(f"缺少文案文件 {name}，已找过：{HERE}/readme-snippets 与 {HERE}/scripts/readme-snippets")


def patch(path: Path, snippet: str, end_mark: str, dry: bool) -> bool:
    text = path.read_text(encoding='utf-8')

    m = START_PAT.search(text)
    if not m:
        print(f"  [{path.name}] 未找到 hero 图行，跳过")
        return False
    end = text.find(end_mark, m.end())
    if end == -1:
        print(f"  [{path.name}] 未找到结束锚点「{end_mark}」，跳过")
        return False

    old_block = text[m.end():end]
    new_block = snippet

    if old_block.strip() == new_block.strip():
        print(f"  [{path.name}] 首屏已是最新，无需改动")
        return False

    print(f"  [{path.name}] 将替换第 {text[:m.end()].count(chr(10))+1} 行起、"
          f"共 {old_block.count(chr(10))} 行（截至「{end_mark}」之前）")
    if dry:
        print("    --- 被替换掉的旧内容（前 12 行）---")
        for line in old_block.strip().splitlines()[:12]:
            print(f"    - {line[:88]}")
        print("    --- 新内容（前 12 行）---")
        for line in new_block.strip().splitlines()[:12]:
            print(f"    + {line[:88]}")
        return True

    path.write_text(text[:m.end()] + new_block + text[end:], encoding='utf-8')
    print(f"  [{path.name}] ✓ 已写入")
    return True


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    dry = '--dry-run' in sys.argv
    if not args:
        print(__doc__)
        return 2
    root = Path(args[0]).expanduser().resolve()

    print(f"==> 仓库根: {root}{'（dry-run）' if dry else ''}")
    done = False
    for name, snippet, end_mark in (
        ('README.md', 'intro-cn.md', END_MARK_CN),
        ('README_EN.md', 'intro-en.md', END_MARK_EN),
    ):
        p = root / name
        if not p.exists():
            print(f"  [{name}] 不存在，跳过")
            continue
        text = p.read_text(encoding='utf-8')
        if end_mark not in text:
            # README_EN 可能沿用中文标题，退一步找英文锚或跳过
            print(f"  [{name}] 未找到结束锚点「{end_mark}」，跳过（不影响中文版）")
            continue
        done = patch(p, load_snippet(snippet), end_mark, dry) or done

    print("==> 无改动" if not done else "==> 完成")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
