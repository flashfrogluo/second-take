#!/usr/bin/env bash
# The installer owns download, version pinning and public-file safety checks.
# This entry point is kept for existing update.sh users.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
exec bash "$ROOT/install.sh" "$@"
