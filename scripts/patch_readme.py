#!/usr/bin/env python3
"""Maintain public README CTAs without exposing release download counters.

Safe for repeated use: removes legacy download badges, replaces deprecated
static skills.sh badge with last-commit badge, adds Star/Watch prompt once.
It intentionally never inserts metrics sections or download-count widgets.
"""
import re
import sys
from pathlib import Path

OLD_BADGE = '[![skills.sh](https://img.shields.io/badge/skills.sh-indexed-brightgreen)](https://skills.sh)'
COMMIT_BADGE = '[![Last commit](https://img.shields.io/github/last-commit/flashfrogluo/second-take?style=flat)](https://github.com/flashfrogluo/second-take/commits/main)'
CTA_CN = (
    '> ⭐ **如果这个 skill 对你有用，点一下右上角的 Star** —— 它会进入你账号的 Stars 列表，方便随时找回；'
    '点 **Watch** 可以订阅版本更新与讨论。\n'
)
CTA_EN = (
    '> ⭐ **If this skill is useful to you, please hit Star** — it lands in your Stars list so you can find it again; '
    'hit **Watch** to subscribe to releases and discussions.\n'
)
# Only remove the badge we previously generated, not arbitrary contributor content.
DOWNLOAD_BADGE = re.compile(
    r'^\[!\[Downloads\]\(https://img\.shields\.io/github/downloads/flashfrogluo/second-take/total[^\n]*(?:\n|$)',
    re.MULTILINE,
)


def patch(path: Path, is_en: bool, dry: bool) -> bool:
    original = path.read_text(encoding='utf-8')
    updated = DOWNLOAD_BADGE.sub('', original)
    updated = updated.replace(OLD_BADGE, COMMIT_BADGE)
    # Avoid a duplicated last-commit badge when the old pair was present.
    badge_line = COMMIT_BADGE + '\n'
    updated = updated.replace(badge_line + badge_line, badge_line)
    cta = CTA_EN if is_en else CTA_CN
    if not ('点一下右上角的 Star' in updated or 'please hit Star' in updated):
        match = re.search(r'```bash\n?npx skills add flashfrogluo/second-take\n```\n', updated)
        if match:
            updated = updated[:match.end()] + '\n' + cta + updated[match.end():]
    if updated == original:
        print(f'[{path.name}] unchanged')
        return False
    if dry:
        print(f'[{path.name}] dry-run: public download badges removed / CTA maintained')
    else:
        path.write_text(updated, encoding='utf-8')
        print(f'[{path.name}] updated: no public download counter')
    return True


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    if len(args) != 1 or any(a not in ('--dry-run',) for a in sys.argv[1:] if a.startswith('--')):
        print('Usage: python3 scripts/patch_readme.py REPO_DIR [--dry-run]', file=sys.stderr)
        return 2
    root = Path(args[0]).expanduser().resolve()
    for name, is_en in (('README.md', False), ('README_EN.md', True)):
        path = root / name
        if not path.is_file():
            print(f'[{name}] missing; skipped')
            continue
        patch(path, is_en, '--dry-run' in sys.argv[1:])
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
