#!/usr/bin/env python3
"""Copy only reviewed public files. Used by release, install and update.

Unknown files are excluded. A missing listed file or a symbolic link aborts
before copying; the manifest is a file list, never executable configuration.
"""
import argparse
import fnmatch
from pathlib import Path, PurePosixPath
import re
import shutil
import sys

MANIFEST = Path(__file__).with_name('public-files.txt')
# 文件 → 首次出现的版本。给更老的源码树打包时，这些文件本就不存在，跳过即可。
# 新增公开文件时，在这里登记它的引入版本。
INTRODUCED = {
    'docs/assets/hero-dark.svg': (1, 7, 2),
    'docs/assets/hero-light.svg': (1, 7, 2),
    'docs/assets/social-card-en.png': (1, 7, 2),
    'scripts/package_files.py': (1, 7, 2),
    'scripts/public-files.txt': (1, 7, 2),
    'tests/test_packaging.py': (1, 7, 2),
    '.claude-plugin/marketplace.json': (1, 7, 3),
    '.codex-plugin/plugin.json': (1, 7, 3),
    '.cursor-plugin/plugin.json': (1, 7, 3),
    '.antigravity-plugin/plugin.json': (1, 7, 3),
    'tests/test_trigger.py': (1, 7, 3),
    'tests/trigger-cases.md': (1, 7, 3),
    'tests/samples/07-video-visual-elements.json': (1, 7, 3),  # 2026-10 由旧文件名改名（原 07-video-visual-elements 前身）
    'docs/assets/workflow-zh.svg': (1, 7, 3),
    'docs/assets/workflow-en.svg': (1, 7, 3),
}
# 后加的文件：装更老的源码树（或 tag 回退包）时本就不存在，缺失只提示、不中断。
# 核心文件（SKILL.md / README / references / prompts）缺失仍然直接报错。
OPTIONAL = set(INTRODUCED)
# 历史上改过名的文件：装新版时顺手删掉旧名，避免同一份东西两个名字并存。
RENAMED = {
    'references/优化指令自查rubric.md': 'references/优化与检查指令自查rubric.md',
    'tests/samples/07-video-caption.json': 'tests/samples/07-video-visual-elements.json',
}


DENIED = ('corpus', 'cases', 'metrics', 'DEVLOG.md', '.git', '.env', '.env.*',
          '*backup*', '__pycache__', 'node_modules', '*.pyc', '*.log', '.DS_Store')


def public_paths(source, manifest=MANIFEST, allow_legacy=False):
    source = Path(source).resolve()
    version = None
    if allow_legacy:
        match = re.search(r'^  version: "(\d+)\.(\d+)\.(\d+)"$',
                          (source / 'SKILL.md').read_text(encoding='utf-8'), re.M)
        version = tuple(map(int, match.groups())) if match else None
    result = []
    seen = set()
    for line in Path(manifest).read_text(encoding='utf-8').splitlines():
        name = line.strip()
        if not name or name.startswith('#'):
            continue
        rel = PurePosixPath(name)
        if rel.is_absolute() or '..' in rel.parts or str(rel) != name:
            raise ValueError(f'Invalid public path: {name}')
        if any(fnmatch.fnmatchcase(part, pattern) for part in rel.parts for pattern in DENIED):
            raise ValueError(f'Private/temporary path in public manifest: {name}')
        if name in seen:
            raise ValueError(f'Duplicate public path: {name}')
        seen.add(name)
        path = source
        for part in rel.parts:
            path = path / part
            if path.is_symlink():
                raise ValueError(f'Symbolic link in source: {name}')
        if not path.exists():
            if version is not None and name in OPTIONAL:
                print(f'  — 跳过（该源码树里没有）: {name}', file=sys.stderr)
                continue
        if not path.is_file():
            raise ValueError(f'Missing public file: {name}')
        result.append(name)
    if 'SKILL.md' not in seen:
        raise ValueError('Public manifest must contain SKILL.md')
    return result


def _prune_stale(destination, keep):
    """Delete files a previous install wrote that are no longer in the manifest."""
    manifest = destination / 'MANIFEST.txt'
    if not manifest.is_file():
        return []
    previous = {line.strip() for line in manifest.read_text(encoding='utf-8').splitlines() if line.strip()}
    removed = []
    for name in sorted(previous - set(keep) - {'MANIFEST.txt'}):
        rel = PurePosixPath(name)
        if rel.is_absolute() or '..' in rel.parts:
            continue
        path = destination / name
        if path.is_symlink() or not path.is_file():
            continue
        path.unlink()
        removed.append(name)
        parent = path.parent
        while parent != destination and parent.is_dir() and not any(parent.iterdir()):
            parent.rmdir()
            parent = parent.parent
    return removed


def copy_public(source, destination, manifest=MANIFEST, allow_legacy=False):
    source = Path(source).resolve()
    destination = Path(destination)
    if destination.is_symlink():
        raise ValueError('Symbolic link in destination: root')
    destination = destination.resolve()
    if source == destination or source in destination.parents or destination in source.parents:
        raise ValueError('Source and destination must be separate directories')
    names = public_paths(source, manifest, allow_legacy)
    if destination.exists() and not destination.is_dir():
        raise ValueError('Destination must be a directory')
    # Preflight every destination so a symlink cannot redirect an overwrite.
    for name in names + ['MANIFEST.txt']:
        path = destination
        parts = PurePosixPath(name).parts
        for i, part in enumerate(parts):
            path = path / part
            if path.is_symlink():
                raise ValueError(f'Symbolic link in destination: {name}')
            if path.exists() and (path.is_dir() if i == len(parts)-1 else not path.is_dir()):
                raise ValueError(f'Conflicting destination path: {name}')
    for name in names:
        target = destination / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source / name, target)
    removed = _prune_stale(destination, names)
    for old_name, new_name in RENAMED.items():
        if new_name in names:
            stale = destination / old_name
            if stale.is_file() and not stale.is_symlink():
                stale.unlink()
                removed.append(old_name)
    (destination / 'MANIFEST.txt').write_text('\n'.join(sorted(names + ['MANIFEST.txt'])) + '\n', encoding='utf-8')
    for name in removed:
        print(f'  — 删除旧版残留: {name}', file=sys.stderr)
    return names


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('destination', type=Path, nargs='?')
    parser.add_argument('--allow-legacy', action='store_true', help='Tolerate files introduced after the source version (see INTRODUCED); core files must still exist')
    args = parser.parse_args()
    try:
        names = copy_public(args.source, args.destination, allow_legacy=args.allow_legacy) if args.destination else public_paths(args.source, allow_legacy=args.allow_legacy)
    except (ValueError, OSError) as exc:
        parser.exit(1, f'Public-file check failed: {exc}\n')
    print(f'Public-file check passed: {len(names)} files')


if __name__ == '__main__':
    main()
