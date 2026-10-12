#!/usr/bin/env bash
# Push reviewed public changes from a clean Git checkout.
# Usage: scripts/push-to-github.sh [--dry-run|--check]
# Uses Git's configured authentication; never stores a token.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
MODE="${1:-push}"
case "$MODE" in push|--dry-run|--check) ;; *) echo "Unknown option: $MODE" >&2; exit 2 ;; esac
[ "$(git rev-parse --show-toplevel)" = "$ROOT" ] || { echo "Run from a dedicated Git checkout, not an installed skill directory." >&2; exit 1; }
BRANCH="${BRANCH:-main}"
[ "$(git branch --show-current)" = "$BRANCH" ] || { echo "Checkout $BRANCH first." >&2; exit 1; }
python3 scripts/package_files.py "$ROOT"
# Reject already-staged private paths too; never commit unrelated staged files.
python3 - <<'PY'
from pathlib import Path
import subprocess, sys
sys.path.insert(0, 'scripts')
from package_files import public_paths
allowed = set(public_paths(Path.cwd()))
changed = set()
for args in [('diff', '--name-only', '-z'), ('diff', '--cached', '--name-only', '-z')]:
    changed.update(p.decode() for p in subprocess.check_output(['git', *args]).split(b'\0') if p)
blocked = sorted(changed - allowed)
if blocked:
    raise SystemExit('Non-public tracked changes; use a clean checkout: ' + ', '.join(blocked))
print('Reviewed changes:')
for name in sorted(allowed):
    state = subprocess.check_output(['git', 'status', '--porcelain', '--', name]).decode().strip()
    if state:
        print(state)
PY
[ "$MODE" != --dry-run ] || exit 0
if [ "$MODE" = --check ]; then
  git ls-remote --exit-code origin "refs/heads/$BRANCH"
  exit 0
fi
python3 tests/validate.py all
python3 -m unittest discover -s tests -p 'test_*.py'
# Stage exact names only. Unknown untracked files never enter this commit.
while IFS= read -r path; do
  case "$path" in ''|'#'*) continue ;; esac
  git add -- "$path"
done < scripts/public-files.txt
if ! git diff --cached --quiet; then
  VERSION="$(python3 -c 'import re,pathlib;print(re.search(r"^  version: \"([^\"]+)\"",pathlib.Path("SKILL.md").read_text(),re.M)[1])')"
  git commit -m "fix: second-take $VERSION public update"
fi
# Normal push rejects concurrent remote updates; do not force or auto-resolve.
git push origin "HEAD:$BRANCH"
