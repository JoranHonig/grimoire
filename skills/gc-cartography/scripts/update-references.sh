#!/usr/bin/env bash
# update-references.sh — Fix stale cartography references after a merge.
# Scans all markdown files for references to a deleted flow and updates them
# to point to the merged flow.
#
# Usage: update-references.sh <old-slug> <new-slug> [search-dir]
# Default search-dir: . (current directory, typically repo root)
#
# Updates:
#   - [[cartography/old-slug]] links -> [[cartography/new-slug]]
#   - related: [..., old-slug, ...] entries -> new-slug
#   - Any other markdown references to cartography/old-slug
#
# Exits 0 on success (even if no references found). Prints changes to stderr.

set -euo pipefail

old_slug="${1:-}"
new_slug="${2:-}"
search_dir="${3:-.}"

if [ -z "$old_slug" ] || [ -z "$new_slug" ]; then
  echo "Usage: update-references.sh <old-slug> <new-slug> [search-dir]" >&2
  exit 1
fi

updated=0
checked=0

echo "Scanning for references to '$old_slug' (replacing with '$new_slug')..." >&2
echo "" >&2

# Find all markdown files that reference the old slug
while IFS= read -r file; do
  [ -f "$file" ] || continue
  checked=$((checked + 1))

  # Skip the old file itself if it still exists
  if [ "$(basename "$file" .md)" = "$old_slug" ]; then
    continue
  fi

  if grep -q "$old_slug" "$file" 2>/dev/null; then
    # Perform replacements
    # 1. [[cartography/old-slug]] -> [[cartography/new-slug]]
    # 2. related: [...old-slug...] -> new-slug
    # 3. cartography/old-slug -> cartography/new-slug (in any context)
    sed -i '' \
      -e "s|cartography/${old_slug}|cartography/${new_slug}|g" \
      -e "s|${old_slug}|${new_slug}|g" \
      "$file"

    echo "  Updated: $file" >&2
    updated=$((updated + 1))
  fi
done < <(find "$search_dir" -name '*.md' -not -path '*/node_modules/*' -not -path '*/.git/*')

# --- Check for reciprocal related links ---
# The new (merged) flow should have reciprocal links to all flows that reference it
merged_file=""
if [ -f "$search_dir/grimoire/cartography/$new_slug.md" ]; then
  merged_file="$search_dir/grimoire/cartography/$new_slug.md"
fi

if [ -n "$merged_file" ]; then
  echo "" >&2
  echo "Checking reciprocal links in $merged_file..." >&2

  # Find all cartography files that now reference the new slug in their related field
  for file in "$search_dir"/grimoire/cartography/*.md; do
    [ -f "$file" ] || continue
    [ "$file" = "$merged_file" ] && continue
    slug=$(basename "$file" .md)
    [ "$slug" = "_index" ] && continue

    # Check if this file has the new slug in its related field
    if sed -n '/^---$/,/^---$/p' "$file" | grep -q "$new_slug"; then
      # Check if merged file has reciprocal link
      if ! sed -n '/^---$/,/^---$/p' "$merged_file" | grep -q "$slug"; then
        echo "  Warning: $slug references $new_slug but $new_slug does not reference $slug back" >&2
        echo "           Add '$slug' to the related field in $merged_file" >&2
      fi
    fi
  done
fi

# --- Summary ---
echo "" >&2
echo "Checked $checked files, updated $updated reference(s)." >&2
if [ "$updated" -eq 0 ]; then
  echo "No stale references found for '$old_slug'." >&2
fi

exit 0
