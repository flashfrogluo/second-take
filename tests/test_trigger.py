"""触发覆盖回归：description 是否仍覆盖已知触发词与排除项。

自动部分只能保证「关键词/排除项没被改掉」；真正的语义触发仍需人工按
tests/trigger-cases.md 的「人工验证方法」跑一遍。
"""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# A/B 组：每组至少命中一个线索即可
SHOULD_TRIGGER = {
    'A1 深度思考对不对': ['深度思考', 'deep thinking', 'reasoning'],
    'A2 答案很难用': ['很难用', 'bad', 'unusable'],
    'A3 分享链接': ['分享链接', 'share link', 'share'],
    'A4 优化提示语': ['优化提示', 'prompt qa', '提示词'],
    'A5 让原 AI 重写': ['重写', 'retake note', 'paste back', '粘回'],
    'A6 漏了要点': ['漏了要点', 'missing'],
    'A7 字数不达标': ['字数', 'word count'],
    'A8 AI 味太重': ['ai 味', '不像人话', 'ai-flavored'],
    'A9 rubric 质检': ['rubric', '评分标准'],
    'A10 推理想错了': ['推理', 'reasoning'],
    'B1 只贴一段思维链': ['深度思考', '思维链', 'thinking'],
    'B2 让原 AI 自己改': ['润色', '重写', 'retake'],
    'B5 能粘回去的指令': ['粘回', 'retake note', 'paste'],
}

# C 组：description 必须含对应的排除表述
SHOULD_NOT_TRIGGER = {
    'C1 从零创作': ['从零创作', '从零'],
    'C2 纯信息查询': ['纯信息查询', '信息查询'],
    'C4 闲聊': ['闲聊'],
}


def description() -> str:
    text = (ROOT / 'SKILL.md').read_text(encoding='utf-8')
    m = re.match(r'^---\n(.*?)\n---\n', text, re.S)
    if not m:
        raise AssertionError('SKILL.md 缺少 frontmatter')
    dm = re.search(r'^description:(.*?)(?=^\w+:)', m.group(1), re.S | re.M)
    if not dm:
        raise AssertionError('frontmatter 缺少 description')
    return dm.group(1).strip()


class TriggerCoverageTests(unittest.TestCase):
    def setUp(self):
        self.desc = description()
        self.lower = self.desc.lower()

    def test_should_trigger_keywords_present(self):
        missing = []
        for case, options in SHOULD_TRIGGER.items():
            if not any(o.lower() in self.lower for o in options):
                missing.append(f'{case}（缺 {options}）')
        self.assertEqual(missing, [], '以下触发场景在 description 里已无对应线索：\n  ' + '\n  '.join(missing))

    def test_should_not_trigger_exclusions_present(self):
        missing = [f'{case}（缺 {opt}）' for case, opt in SHOULD_NOT_TRIGGER.items()
                   if not any(o.lower() in self.lower for o in opt)]
        self.assertEqual(missing, [], '以下排除项已从 description 消失（会误触发）：\n  ' + '\n  '.join(missing))

    def test_description_stays_compact(self):
        # 路由入口越长越容易漂移；超出预算时先想清楚要加什么
        self.assertLessEqual(len(self.desc), 700, f'description 已 {len(self.desc)} 字符，超出 700 预算')

    def test_no_volatile_platform_enumeration(self):
        # 模型名会过期；description 里不该列具体平台
        volatile = ['midjourney', 'jimeng', '即梦', '可灵', 'claude', 'chatgpt', 'gemini', 'deepseek']
        hit = [v for v in volatile if v in self.lower]
        self.assertEqual(hit, [], f'description 里出现了会过期的平台名：{hit}')


if __name__ == '__main__':
    unittest.main()
