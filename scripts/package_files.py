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
NEW_IN_172 = {'docs/assets/hero-dark.svg', 'docs/assets/hero-light.svg',
              'docs/assets/social-card-en.png', 'scripts/package_files.py',
              'scripts/public-files.txt', 'tests/test_packaging.py'}
DENIED = ('corpus', 'cases', 'metrics', 'DEVLOG.md', '.git', '.env', '.env.*',
          '*backup*', '__pycache__', 'node_modules', '*.pyc', '*.log', '.DS_Store')


def public_paths(source, manifest=MANIFEST, allow_legacy=False):
    source = Path(source).resolve()
    legacy = False
    if allow_legacy:
        match = re.search(r'^  version: "(\d+)\.(\d+)\.(\d+)"$',
                          (source / 'SKILL.md').read_text(encoding='utf-8'), re.M)
        legacy = bool(match and tuple(map(int, match.groups())) < (1, 7, 2))
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
        if not path.exists() and legacy and name in NEW_IN_172:
            continue
        if not path.is_file():
            raise ValueError(f'Missing public file: {name}')
        result.append(name)
    if 'SKILL.md' not in seen:
        raise ValueError('Public manifest must contain SKILL.md')
    return result


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
    (destination / 'MANIFEST.txt').write_text('\n'.join(sorted(names + ['MANIFEST.txt'])) + '\n', encoding='utf-8')
    return names


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('destination', type=Path, nargs='?')
    parser.add_argument('--allow-legacy', action='store_true', help='Allow only the three new tooling files to be absent in pre-1.7.2 installs')
    args = parser.parse_args()
    try:
        names = copy_public(args.source, args.destination, allow_legacy=args.allow_legacy) if args.destination else public_paths(args.source, allow_legacy=args.allow_legacy)
    except (ValueError, OSError) as exc:
        parser.exit(1, f'Public-file check failed: {exc}\n')
    print(f'Public-file check passed: {len(names)} files')


if __name__ == '__main__':
    main()
