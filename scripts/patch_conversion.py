#!/usr/bin/env python3
# 转化补丁：让数据可归因、首屏可信。
#
# 解决三个具体问题（都有实测依据）：
#   1. 徽章太多：7 个徽章各是一次第三方请求，既拖慢首屏也是噪声来源。
#      而且 /last-commit 对访客毫无决策价值——访客不关心你上周有没有提交。
#   2. 无法归因：无法区分「从 README 点进文档站的」和「从搜索来的」，
#      导致每次判断改动效果都靠猜。文档站链接此前还被我重写首屏时弄丢了。
#   3. 首屏缺可信信号：访客看不到任何「这东西可靠」的证据。
#
# 幂等：重复运行不会重复添加。
#
# 用法：
#   python3 patch_conversion.py <repo_dir>            写入
#   python3 patch_conversion.py <repo_dir> --dry-run  只看会改什么
import re
import sys
from pathlib import Path

# ── 保留哪些徽章 ──────────────────────────────────────────────────────
# 判断标准：访客是否会因为看到它而改变决定。
#   stars    留：社交证明
#   downloads 留：真实使用量
#   license  留：能否商用是硬决策项
#   CI       留：贡献者关心
#   version  去：CHANGELOG 里有，且版本号不帮助决策
#   Agent-Skill 去：受众已知，对访客是噪音
#   last-commit 去：与访客无关
KEEP_PATTERNS = [
    r'!\[GitHub stars\]',
    r'!\[Downloads\]',
    r'!\[License\]',
    r'!\[CI\]',
]

# 加 UTM 的链接：只有仓库外的链接才需要归因
UTM = '?utm_source=github&utm_medium=readme&utm_campaign=intro'

DOC_SITE = 'https://flashfrogluo.github.io/second-take/'

# 首屏可信信号：访客看到「有人认真做过」比看到功能列表更容易留下。
# 位置很关键——插在对比表之后、而不是标题正下方，
# 否则会把「它解决什么问题」这句最该先被读到的话挤走。
TRUST_BLOCK = """
📖 **上手手册**（含五种模式的完整走法）：{doc_link}

若在 DeepSeek 上用，可直接取用 [`prompts/for-deepseek.md`](prompts/for-deepseek.md)——为它的思考模式调过；其他平台用 [`prompts/abc.md`](prompts/abc.md)。
"""


def slim_badges(text: str, dry: bool) -> str:
    """把徽章区精简到 KEEP_PATTERNS 保留下来的那几个。"""
    lines = text.split('\n')
    # 找连续的徽章行区间
    # 注意：hero 主视觉图也是 [![...] 开头，它不是徽章，必须排除，
    # 否则会被当徽章删掉（干跑时实测踩到过）。
    def is_badge(line: str) -> bool:
        if not line.strip().startswith('[!['):
            return False
        if 'hero' in line or '主视觉' in line or '/assets/' in line:
            return False
        return True

    idx = [i for i, l in enumerate(lines) if is_badge(l)]
    if not idx:
        print("    · 未找到徽章行，跳过精简")
        return text
    kept, dropped = [], []
    for i in idx:
        line = lines[i]
        if any(re.search(p, line) for p in KEEP_PATTERNS):
            kept.append(line)
        else:
            dropped.append(line)
    if not dropped:
        print(f"    · 徽章已是精简状态（{len(kept)} 个），跳过")
        return text
    print(f"    · 徽章 {len(idx)} → {len(kept)} 个，移除 {len(dropped)} 个")
    for l in dropped:
        m = re.search(r'badge/([^?\)]+)|/(stars|license|downloads|last-commit)/', l)
        print(f"        - 移除 {(m.group(0) if m else '?')[:44]}")
    # 用保留的行替换第一段徽章区，删掉其余徽章行
    first, last = idx[0], idx[-1]
    new_lines = lines[:first] + kept + lines[last + 1:]
    return '\n'.join(new_lines)


def strip_utm(url: str) -> str:
    return url.split('?utm_source=')[0]


def add_attribution(text: str, dry: bool) -> str:
    """给文档站链接加 UTM；缺失则补回一个带 UTM 的入口。"""
    has_doc = DOC_SITE in text or 'github.io/second-take' in text
    has_utm = 'utm_source=github' in text

    if has_doc and has_utm:
        print("    · 文档站链接已带归因参数，跳过")
        return text

    if has_doc and not has_utm:
        print("    · 文档站链接存在但无归因参数，补上")
        if dry:
            return text
        return re.sub(
            r'https://flashfrogluo\.github\.io/second-take/?(?![?\w])',
            DOC_SITE + UTM, text)

    # 链接缺失（重写首屏时弄丢的），补一个带归因的入口
    print("    · 文档站链接缺失，补回并带归因参数")
    if dry:
        return text
    block = TRUST_BLOCK.format(doc_link=f'[{DOC_SITE}]({DOC_SITE}{UTM})')
    # 首选：插在「它不替你写答案」那段之后——此时读者刚看完对比表，正需要下一步
    m = re.search(r'^(\*\*它不替你写答案。\*\*[^\n]*)\n', text, re.M)
    if m:
        return text[:m.end()] + block + '\n' + text[m.end():]
    # 退一步：插在第一个二级标题之前
    anchor = re.search(r'^## ', text, re.M)
    if not anchor:
        print("    · 找不到插入点，跳过")
        return text
    return text[:anchor.end()] + block + '\n' + text[anchor.end():]


def fix_hero_spacing(text: str, dry: bool) -> str:
    """hero 图行与紧随其后的标题之间必须有空行，否则 markdown 渲染会粘连。"""
    m = re.search(r'^(\[!\[Second Take 主视觉[^\n]*)\n(## )', text, re.M)
    if not m:
        # 兼用更宽的特征：hero 或 /assets/ 图片行后紧跟标题
        m = re.search(r'^([^\n]*hero\.svg[^\n]*)\n(## )', text, re.M)
    if m:
        print("    · hero 图与标题之间缺空行，补上")
        if dry:
            return text
        return text[:m.end(1)] + '\n' + text[m.end(1):]
    return text


def collapse_blank(text: str, dry: bool) -> str:
    """把 3 个以上连续空行压成 1 个——摘除错位块时容易留下空洞。"""
    new = re.sub(r'\n{4,}', '\n\n\n', text)
    if new != text:
        print("    · 清理多余空行")
        return text if dry else new
    return text


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    dry = '--dry-run' in sys.argv
    if not args:
        print(__doc__)
        return 2
    root = Path(args[0]).expanduser().resolve()
    print(f"==> 仓库根: {root}{'（dry-run）' if dry else ''}")

    for name in ('README.md', 'README_EN.md'):
        p = root / name
        if not p.exists():
            print(f"  [{name}] 不存在，跳过")
            continue
        print(f"  [{name}]")
        text = p.read_text(encoding='utf-8')
        before = text
        text = slim_badges(text, dry)
        text = fix_hero_spacing(text, dry)
        text = add_attribution(text, dry)
        text = collapse_blank(text, dry)
        if text == before:
            print("    → 无改动")
        elif dry:
            print("    → (dry-run) 将写入")
        else:
            p.write_text(text, encoding='utf-8')
            print("    → ✓ 已写入")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
