#!/usr/bin/env bash
# Second Take Release publisher.
# Upload assets to a draft, verify them, then publish. No public download counters.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/release.sh VERSION [--dry-run] [--notes TEXT] [--repo OWNER/REPO]
                         [--asset FILE.zip] [--root PATH]

Examples:
  scripts/release.sh 1.7.3 --dry-run
  GITHUB_TOKEN=... scripts/release.sh 1.7.3

The published release is created from the current clean, pushed default-branch HEAD.
USAGE
}
fail() { printf '✗ %s\n' "$*" >&2; exit 1; }
need_value() { [[ $# -ge 2 && -n "$2" && "$2" != --* ]] || fail "Missing value for $1"; }

VERSION="${1:-}"
if [[ "$VERSION" = '-h' || "$VERSION" = '--help' || -z "$VERSION" ]]; then
  usage
  [[ -n "$VERSION" ]] || exit 2
  exit 0
fi
shift
[[ "$VERSION" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)?$ ]] || fail "Invalid version: $VERSION"
TAG="v${VERSION#v}"
DRY_RUN=0
NOTES=''
REPO="${REPO:-}"
ASSET='second-take-latest.zip' # install.sh depends on this stable filename.
ROOT_OVERRIDE=''
while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --notes) need_value "$@"; NOTES="$2"; shift 2 ;;
    --repo) need_value "$@"; REPO="$2"; shift 2 ;;
    --asset) need_value "$@"; ASSET="$2"; shift 2 ;;
    --root) need_value "$@"; ROOT_OVERRIDE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) fail "Unknown option: $1" ;;
  esac
done
[[ "$ASSET" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*\.zip$ ]] || fail 'Asset must be a safe .zip basename'
command -v python3 >/dev/null || fail 'python3 is required'
command -v curl >/dev/null || [[ "$DRY_RUN" -eq 1 ]] || fail 'curl is required'

if [[ -n "$ROOT_OVERRIDE" ]]; then
  ROOT="$(cd "$ROOT_OVERRIDE" && pwd)" || fail "Cannot enter $ROOT_OVERRIDE"
else
  ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fi
[[ -f "$ROOT/SKILL.md" ]] || fail "SKILL.md missing in $ROOT"
[[ -f "$ROOT/scripts/package_files.py" ]] || fail 'scripts/package_files.py missing'
cd "$ROOT"

if [[ -z "$REPO" ]]; then
  origin="$(git remote get-url origin 2>/dev/null || true)"
  case "$origin" in
    git@github.com:*) REPO="${origin#git@github.com:}" ;;
    https://github.com/*) REPO="${origin#https://github.com/}" ;;
    ssh://git@github.com/*) REPO="${origin#ssh://git@github.com/}" ;;
  esac
fi
REPO="${REPO%.git}"
[[ "$REPO" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || fail 'Expected GitHub repository OWNER/REPO (use --repo)'

# Fail closed on a missing version; the old script silently accepted no version field.
skill_version="$(sed -n -E 's/^[[:space:]]*version:[[:space:]]*"?([^"[:space:]]+)"?.*$/\1/p' SKILL.md | head -n 1)"
[[ -n "$skill_version" ]] || fail 'Could not read SKILL.md metadata.version'
[[ "$skill_version" = "${TAG#v}" ]] || fail "SKILL.md is $skill_version, requested $TAG"

printf '==> Repository: %s\n==> Version: %s\n==> Asset: %s\n' "$REPO" "$TAG" "$ASSET"

if [[ "$DRY_RUN" -eq 0 ]]; then
  [[ -n "${GITHUB_TOKEN:-}" ]] || fail 'GITHUB_TOKEN is required for publishing'
  git rev-parse --is-inside-work-tree >/dev/null || fail 'Publishing requires a git repository'
  [[ -z "$(git status --porcelain --untracked-files=all)" ]] || fail 'Working tree is dirty; commit/clean before publishing'
  COMMIT="$(git rev-parse HEAD)"
  remote_head="$(git ls-remote origin HEAD | awk 'NR==1{print $1}')" || fail 'Could not query origin HEAD'
  [[ -n "$remote_head" && "$COMMIT" = "$remote_head" ]] || fail 'Local HEAD must match pushed remote default-branch HEAD'
  remote_tags="$(git ls-remote --tags origin "refs/tags/$TAG")" || fail 'Cannot check remote tag'
  [[ -z "$remote_tags" ]] || fail "Tag $TAG already exists on origin"
fi

TMP="$(mktemp -d)"
RELEASE_ID=''
ROLLBACK_ALLOWED=1
cleanup() {
  result=$?
  trap - EXIT
  if [[ "$result" -ne 0 && -n "$RELEASE_ID" && "$ROLLBACK_ALLOWED" -eq 1 ]]; then
    printf '==> Release failed: deleting unpublished draft %s\n' "$RELEASE_ID" >&2
    if ! curl -fsS -m 30 -X DELETE \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H 'Accept: application/vnd.github+json' \
      "https://api.github.com/repos/$REPO/releases/$RELEASE_ID" >/dev/null; then
      printf '⚠ Draft cleanup failed; inspect release %s manually\n' "$RELEASE_ID" >&2
    fi
  elif [[ "$result" -ne 0 && -n "$RELEASE_ID" && "$ROLLBACK_ALLOWED" -eq 0 ]]; then
    printf '⚠ Publish request outcome is uncertain; inspect release %s before retrying\n' "$RELEASE_ID" >&2
  fi
  rm -rf -- "$TMP"
  exit "$result"
}
trap cleanup EXIT
STAGE="$TMP/second-take"
mkdir -p "$STAGE"
python3 "$ROOT/scripts/package_files.py" "$ROOT" "$STAGE"
[[ -f "$STAGE/SKILL.md" ]] || fail 'Packager did not include SKILL.md'
python3 - "$STAGE" "$TMP/$ASSET" <<'PYZIP'
from pathlib import Path
import sys, zipfile
stage = Path(sys.argv[1])
with zipfile.ZipFile(sys.argv[2], 'w', zipfile.ZIP_DEFLATED) as archive:
    for path in sorted(stage.rglob('*')):
        if path.is_file():
            archive.write(path, 'second-take/' + path.relative_to(stage).as_posix())
PYZIP
# Ensure archive is readable and contains the expected root entry.
python3 - "$TMP/$ASSET" <<'PYCHECK'
import sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as f:
    if f.testzip() is not None or 'second-take/SKILL.md' not in f.namelist():
        raise SystemExit('Bad release ZIP')
PYCHECK
ASSET_BYTES="$(wc -c < "$TMP/$ASSET" | tr -d ' ')"
printf '==> Verified package: %s bytes, %s files\n' "$ASSET_BYTES" "$(wc -l < "$STAGE/MANIFEST.txt" | tr -d ' ')"
if [[ "$DRY_RUN" -eq 1 ]]; then
  cp "$TMP/$ASSET" "$ROOT/$ASSET"
  printf '==> Dry run complete, not published: %s\n' "$ROOT/$ASSET"
  exit 0
fi

if [[ -z "$NOTES" && -f CHANGELOG.md ]]; then
  NOTES="$(awk -v version="${TAG#v}" '
    index($0, "## [" version "]") == 1 { flag=1; next }
    flag && /^## \[/ { exit }
    flag { print }
  ' CHANGELOG.md)"
fi
[[ -n "$NOTES" ]] || NOTES='See CHANGELOG.md for changes.'
notes_json="$(python3 -c 'import json,sys; print(json.dumps(sys.stdin.read(),ensure_ascii=False))' <<< "$NOTES")"

# Draft first: no incomplete published release if asset upload fails.
printf '==> Creating draft release %s\n' "$TAG"
RESP="$(curl -fsS -m 60 -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H 'Accept: application/vnd.github+json' \
  -H 'Content-Type: application/json' \
  "https://api.github.com/repos/$REPO/releases" \
  -d "{\"tag_name\":\"$TAG\",\"target_commitish\":\"$COMMIT\",\"name\":\"$TAG\",\"body\":$notes_json,\"draft\":true,\"prerelease\":false}")"
release_fields="$(python3 -c '
import json,sys
obj=json.load(sys.stdin)
assert isinstance(obj.get("id"),int) and obj.get("upload_url") and obj.get("draft") is True, "Invalid draft release response"
print(str(obj["id"]) + " " + obj["upload_url"].split("{")[0])
' <<< "$RESP")" || fail 'Invalid draft release response'
RELEASE_ID="${release_fields%% *}"
UPLOAD_URL="${release_fields#* }"

printf '==> Uploading %s\n' "$ASSET"
UPLOAD_RESP="$(curl -fsS -m 300 -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H 'Content-Type: application/zip' \
  --data-binary "@$TMP/$ASSET" \
  "$UPLOAD_URL?name=$ASSET")"
# Parse JSON using -c so stdin is not consumed by the Python source.
python3 -c '
import json,sys
obj=json.load(sys.stdin)
assert obj.get("name") == sys.argv[1], "Wrong uploaded asset"
assert obj.get("state") == "uploaded", "Asset not uploaded"
assert obj.get("size") == int(sys.argv[2]), "Uploaded byte count mismatch"
assert obj.get("browser_download_url"), "Missing download URL"
' "$ASSET" "$ASSET_BYTES" <<< "$UPLOAD_RESP" || fail 'Upload verification failed'

# After issuing PATCH, its outcome may be ambiguous on network failure: do not auto-delete.
ROLLBACK_ALLOWED=0
printf '==> Publishing verified release %s\n' "$TAG"
PUBLISH_RESP="$(curl -fsS -m 60 -X PATCH \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H 'Accept: application/vnd.github+json' \
  -H 'Content-Type: application/json' \
  "https://api.github.com/repos/$REPO/releases/$RELEASE_ID" \
  -d '{"draft":false,"prerelease":false,"make_latest":"true"}')"
python3 -c '
import json,sys
obj=json.load(sys.stdin)
assert obj.get("draft") is False and obj.get("tag_name") == sys.argv[1], "Release not published"
print("==> Published:", obj.get("html_url", ""))
' "$TAG" <<< "$PUBLISH_RESP" || fail 'Publish verification failed'
cat <<EOF
==> Publish complete. No download count displayed.
Follow-up: verify the latest asset URL and the installer against $TAG.
EOF
