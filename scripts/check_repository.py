#!/usr/bin/env python3
"""Reject unreviewed tracked paths, including unchanged private files."""
from pathlib import Path
import subprocess
from package_files import public_paths

ROOT = Path(__file__).resolve().parents[1]

def check_repository(root=ROOT):
    allowed = set(public_paths(root))
    allowed.update(public_paths(root, root / 'scripts/repository-files.txt', require_skill=False))
    tracked = set(subprocess.check_output(['git', '-C', str(root), 'ls-files', '-z']).decode().split('\0')) - {''}
    blocked = sorted(tracked - allowed)
    if blocked:
        raise ValueError('Unreviewed tracked files: ' + ', '.join(blocked))
    return allowed

if __name__ == '__main__':
    check_repository()
    print('Repository public-file boundary passed')
