#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Validation suite for the second-take skill.

This is the skill's "可验证信号" (verifiability signal): a machine-checkable
contract that the deliverable (the 重拍单 / retake note) always contains the
three required elements, and that the repo's entry points stay well-formed.

Subcommands:
  skill            Validate SKILL.md frontmatter has name / version / description.
  links            Check README internal Markdown links resolve to real files.
  retake <file>    Validate a retake-note text for the three required elements.
  all              Run skill + links + sample self-tests (CI entry point).

Exit code is non-zero when any check fails, so CI turns red on regression.
"""
import sys
import os
import re
import json
import glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKILL_MD = os.path.join(ROOT, "SKILL.md")
README_MD = os.path.join(ROOT, "README.md")
SAMPLES = os.path.join(ROOT, "tests", "samples")

# Heuristic keyword sets for the three required elements of a retake note.
DIAGNOSIS_HINTS = ["诊断", "问题", "缺陷", "症状", "漏", "矛盾", "无据", "模糊",
                   "错误", "不成立", "缺", "冲突"]
COPY_HINTS = ["复制", "粘回", "整段复制", "重拍单", "优化指令", "retake"]
CONSTRAINT_HINTS = ["约束", "不要", "禁止", "必须", "不改", "保持", "注意", "边界",
                    "只输出", "禁用", "不得", "不可"]


def _has_bullets(text):
    return bool(re.search(r'(?m)^\s*([-*]|\d+\.)\s', text))


def check_retake_note(text):
    """Return {diagnosis, instruction, constraint, problems[]} for a note."""
    problems = []

    # 1) 诊断条目 — a diagnosis heading, or a bulleted list using diagnosis words.
    has_diag_heading = bool(re.search(r'诊断|问题定位|缺陷清单|错误清单', text))
    diag_hits = sum(1 for h in DIAGNOSIS_HINTS if h in text)
    diagnosis_ok = has_diag_heading or (_has_bullets(text) and diag_hits >= 2)
    if not diagnosis_ok:
        problems.append("缺少诊断条目（诊断/问题清单，或带要点的诊断列表）")

    # 2) 可复制指令 — a fenced code block, a 重拍单/优化指令 heading, or copy hints.
    has_code = "```" in text
    has_instr_heading = bool(re.search(r'重拍单|优化指令|Retake note|Retake Note', text))
    copy_hits = sum(1 for h in COPY_HINTS if h.lower() in text.lower())
    instruction_ok = has_code or has_instr_heading or copy_hits >= 1
    if not instruction_ok:
        problems.append("缺少可复制指令（代码块 / 重拍单-优化指令段落 / 复制-粘回提示）")

    # 3) 约束 — at least two constraint keywords in the note.
    constr_hits = sum(1 for h in CONSTRAINT_HINTS if h in text)
    constraint_ok = constr_hits >= 2
    if not constraint_ok:
        problems.append("缺少约束（不要/禁止/必须/只输出/禁用 等至少 2 处）")

    return {"diagnosis": diagnosis_ok,
            "instruction": instruction_ok,
            "constraint": constraint_ok,
            "problems": problems}


def validate_skill_frontmatter():
    if not os.path.exists(SKILL_MD):
        return ["SKILL.md 不存在"]
    with open(SKILL_MD, encoding="utf-8") as f:
        content = f.read()
    m = re.match(r'^---\s*\n(.*?)\n---\s*\n', content, re.S)
    if not m:
        return ["SKILL.md 缺少 YAML frontmatter"]
    fm = m.group(1)
    problems = []
    for key in ("name", "version", "description"):
        if not re.search(rf'^\s*{key}\s*:', fm, re.M):
            problems.append(f"frontmatter 缺少必填字段：{key}")
    return problems


def check_readme_links():
    if not os.path.exists(README_MD):
        return ["README.md 不存在"]
    with open(README_MD, encoding="utf-8") as f:
        content = f.read()
    problems = []
    for mm in re.finditer(r'\[[^\]]*\]\(([^)]+)\)', content):
        target = mm.group(1).strip()
        if target.startswith(("http://", "https://", "#", "mailto:")):
            continue
        path = target.split("#")[0]
        if not path:
            continue
        full = os.path.normpath(os.path.join(ROOT, path))
        if not os.path.exists(full):
            problems.append(f"README 内链失效：{target}")
    return problems


def run_self_tests():
    problems = []
    samples = sorted(glob.glob(os.path.join(SAMPLES, "*.json")))
    if not samples:
        return ["tests/samples 下没有样例文件"]
    for sp in samples:
        with open(sp, encoding="utf-8") as f:
            data = json.load(f)
        note = data.get("expected_retake_note", "")
        res = check_retake_note(note)
        if res["problems"]:
            problems.append(f"{os.path.basename(sp)} 的 expected_retake_note 未通过：{res['problems']}")
    return problems


def run_negative_tests():
    """A clearly invalid note MUST be rejected — guards against empty-shell passes."""
    problems = []
    cases = (
        ("空笔记", ""),
        ("闲聊无三要素", "今天天气不错，谢谢你的帮助。"),
        ("只有标题无内容", "# 重拍单\n\n"),
    )
    for label, bad in cases:
        res = check_retake_note(bad)
        if not res["problems"]:
            problems.append(f"负例未拦截（{label}）：无效笔记竟通过校验")
    return problems


def _report(ok, label, detail):
    print(("✅" if ok else "❌") + f" {label}: " + (detail or "OK"))


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "all"
    all_problems = []

    if cmd in ("skill", "all"):
        p = validate_skill_frontmatter()
        _report(not p, "SKILL.md frontmatter", ", ".join(p))
        all_problems += [f"SKILL frontmatter: {x}" for x in p]

    if cmd in ("links", "all"):
        p = check_readme_links()
        _report(not p, "README links", ", ".join(p))
        all_problems += [f"README link: {x}" for x in p]

    if cmd == "retake":
        if len(sys.argv) < 3:
            print("usage: validate.py retake <file>")
            sys.exit(2)
        with open(sys.argv[2], encoding="utf-8") as f:
            text = f.read()
        res = check_retake_note(text)
        print(json.dumps(res, ensure_ascii=False, indent=2))
        sys.exit(0 if not res["problems"] else 1)

    if cmd == "all":
        p = run_self_tests()
        _report(not p, "sample self-tests", ", ".join(p))
        all_problems += [f"sample: {x}" for x in p]
        p = run_negative_tests()
        _report(not p, "negative cases rejected", ", ".join(p))
        all_problems += [f"negative: {x}" for x in p]

    if all_problems:
        print("\n❌ 校验未通过：")
        for x in all_problems:
            print("  - " + x)
        sys.exit(1)
    print("\n✅ 全部校验通过")
    sys.exit(0)


if __name__ == "__main__":
    main()
