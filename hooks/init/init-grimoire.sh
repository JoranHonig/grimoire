#!/usr/bin/env bash
# init-grimoire.sh — Ensure ~/.grimoire/ has the expected directory structure.
# Runs on every SessionStart. Idempotent: only creates missing pieces.
# Exit 0 on success, exit 2 on failure.

set -euo pipefail

GRIMOIRE="${GRIMOIRE_HOME:-$HOME/.grimoire}"

dirs=(
  "$GRIMOIRE/librarian/library"
  "$GRIMOIRE/librarian/cache"
  "$GRIMOIRE/sigils/archived"
  "$GRIMOIRE/knowledge"
)

for dir in "${dirs[@]}"; do
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir" || { echo "grimoire-init: failed to create $dir" >&2; exit 2; }
  fi
done

# Initialize git repository — idempotent (no-op if already a repo)
git init -q "$GRIMOIRE" 2>/dev/null \
  || { echo "grimoire-init: failed to git init $GRIMOIRE" >&2; exit 2; }

# Create libraries.yaml only if absent — never overwrite
LIBRARIES_YAML="$GRIMOIRE/librarian/library/libraries.yaml"
if [ ! -f "$LIBRARIES_YAML" ]; then
  printf 'libraries: {}\n' > "$LIBRARIES_YAML" \
    || { echo "grimoire-init: failed to create $LIBRARIES_YAML" >&2; exit 2; }
fi

exit 0
