#!/usr/bin/env bash
# One-command reproducible build for the nocodb-zh custom image.
#
# Usage: build.sh <release-tag>
#   e.g. build.sh 2026.06.1
#
# Requires: a clean checkout of this repo on branch `zh-release/<release-tag>`
# (built per MAINTENANCE.md's upgrade playbook: from the upstream release tag,
# cherry-pick unmerged topic branches + deploy/zh-build-config + temp Crowdin
# overlay). This script does not create that branch; it only builds from it.
#
# Produces an immutable tag: nocodb-zh:<release-tag>-<n>-git.<sha>
# where <n> increments per release-tag and <sha> is the exact commit built.
# Never overwrites an existing tag (rebuilds always get a new <n>).
set -euo pipefail

RELEASE_TAG="${1:?usage: build.sh <release-tag>}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"

cd "$REPO_ROOT"

CUR_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
EXPECTED_BRANCH="zh-release/${RELEASE_TAG}"
if [ "$CUR_BRANCH" != "$EXPECTED_BRANCH" ]; then
  echo "[FAIL] expected to be on branch '$EXPECTED_BRANCH', currently on '$CUR_BRANCH'."
  echo "       run: git checkout $EXPECTED_BRANCH"
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "[FAIL] working tree is dirty. build.sh only builds from a committed, clean checkout"
  echo "       (server is not a build source of truth -- see MAINTENANCE.md iron law 3)."
  git status --short
  exit 1
fi

SHA="$(git rev-parse --short=12 HEAD)"

# Find the next free build number N for this release tag.
N=1
while docker image inspect "nocodb-zh:${RELEASE_TAG}-${N}-git.${SHA}" >/dev/null 2>&1; do
  N=$((N + 1))
done
# Also skip N already used by a *different* sha for this release tag, so the
# human-facing "-N" ordinal still increases monotonically across rebuilds.
while docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^nocodb-zh:${RELEASE_TAG}-${N}-git\."; do
  N=$((N + 1))
done

TAG="nocodb-zh:${RELEASE_TAG}-${N}-git.${SHA}"

echo "[*] building $TAG from $EXPECTED_BRANCH @ $SHA"
docker build -f Dockerfile.zh -t "$TAG" .

echo "[*] running baseline selfcheck against $TAG"
"$SCRIPT_DIR/selfcheck.sh" "$TAG"

APP_TO_CLEAN="$(cat /tmp/.selfcheck-last-app 2>/dev/null || true)"
PG_TO_CLEAN="$(cat /tmp/.selfcheck-last-pg 2>/dev/null || true)"
NET_TO_CLEAN="$(cat /tmp/.selfcheck-last-net 2>/dev/null || true)"

if [ -x "$SCRIPT_DIR/selfcheck-attachments.sh" ] && [ -n "$APP_TO_CLEAN" ]; then
  echo "[*] running attachment-specific selfcheck against the still-running $APP_TO_CLEAN"
  HOST_PORT="$(cat /tmp/.selfcheck-last-port)"
  TOKEN="$(cat /tmp/.selfcheck-last-token)"
  "$SCRIPT_DIR/selfcheck-attachments.sh" "$HOST_PORT" "$TOKEN" "$REPO_ROOT" "$APP_TO_CLEAN" \
    || { echo "[FAIL] attachment selfcheck failed"; docker rm -f "$APP_TO_CLEAN" "$PG_TO_CLEAN" >/dev/null 2>&1; docker network rm "$NET_TO_CLEAN" >/dev/null 2>&1; exit 1; }
fi

docker rm -f "$APP_TO_CLEAN" "$PG_TO_CLEAN" >/dev/null 2>&1 || true
docker network rm "$NET_TO_CLEAN" >/dev/null 2>&1 || true

echo "[OK] built and self-checked: $TAG"
echo "$TAG"
