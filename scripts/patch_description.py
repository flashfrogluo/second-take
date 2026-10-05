#!/usr/bin/env python3
# 改写 SKILL.md 的 frontmatter description：
#   把「别人真会打的检索词」提到最前面（skills.sh 只按 name + description 做文本匹配），
#   同时完整保留原有触发集（中文触发语、点名模式、平台名、适用/不适用边界）。
#
# 用法：
#   python3 patch_description.py <repo_dir>            写入
#   python3 patch_description.py <repo_dir> --dry-run  只对比新旧
import re
import sys
from pathlib import Path

NEW_DESCRIPTION = (
    "当 AI 给的结果不满意时使用：诊断那段深度思考（CoT / 推理链 / thinking）哪里出错，"
    "并产出一段可粘回原对话的重拍单。**不适用**：从零创作新内容、纯信息查询（无需诊断已有推理）、闲聊。"
    "覆盖文本推理与图像 / 视频生成多类 AI（Claude、DeepSeek、Gemini、ChatGPT、即梦、可灵、Midjourney…）；"
    "也适用于生成平台出图出片不对时质检提示词。完整工作流：重拍 → 补拍 → 定剪 → 调色 → 包装。"
    "**默认给轻装版（多为定点修复：只改几处；要完整版说「详细点 / 往深了查」）。** "
    "Use when 用户说「这个结果不对 / 很难用 / 漏了要点 / 字数不达标 / 输出不像人话 / AI 味太重 / 格式不对」，"
    "或贴来分享链接、一段深度思考、一份 rubric要求质检，"
    "或点名「重拍 / 补拍 / 定剪 / 调色 / 包装」「帮我取舍 / 润色 / 可视化 / 做个图」，"
    "或要求挑错、复盘、复核、改写 CoT、优化提示语、让原 AI 重写时使用。"
    "Second Take · 再来一条。"
)


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dry = "--dry-run" in sys.argv
    if not args:
        print(__doc__)
        return 2
    root = Path(args[0]).expanduser().resolve()
    skill = root / "SKILL.md"
    if not skill.exists():
        print(f"✗ 未找到 {skill}")
        return 1

    text = skill.read_text(encoding="utf-8")
    m = re.match(r"^(---\n)(.*?)(\n---\n)", text, re.S)
    if not m:
        print("✗ SKILL.md 没有 frontmatter，未改动")
        return 1

    fm = m.group(2)
    dm = re.search(r'^description:\s*"(.*?)"\s*$', fm, re.S | re.M)
    if not dm:
        print("✗ 未找到双引号包裹的 description（若为未加引号的多行，请手工处理）")
        return 1

    old = dm.group(1)
    if old.strip() == NEW_DESCRIPTION.strip():
        print("  description 已是最新，无需改动")
        return 0

    print(f"  description 长度 {len(old)} → {len(NEW_DESCRIPTION)}")
    print("  --- 旧开头 ---")
    print("  " + old[:110].replace("\n", " ") + " …")
    print("  --- 新开头 ---")
    print("  " + NEW_DESCRIPTION[:110] + " …")

    if ":" in NEW_DESCRIPTION and not NEW_DESCRIPTION.startswith('"'):
        print("  ✓ 已用双引号包裹（含冒号，必须包裹，否则 YAML 解析失败会导致静默不可安装）")

    new_fm = fm[: dm.start(1)] + NEW_DESCRIPTION + fm[dm.end(1):]
    new_text = m.group(1) + new_fm + m.group(3) + text[m.end():]

    if dry:
        print("  (dry-run) 未写入")
        return 0
    skill.write_text(new_text, encoding="utf-8")
    print("  ✓ 已写入 SKILL.md")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
