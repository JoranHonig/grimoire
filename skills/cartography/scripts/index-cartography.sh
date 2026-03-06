#!/usr/bin/env bash
# index-cartography.sh — Index cartography files by reading YAML frontmatter.
# Outputs tab-separated: name\tdescription\tfilepath
# Usage: index-cartography.sh [directory]
# Default directory: grimoire/cartography/

set -euo pipefail

dir="${1:-grimoire/cartography/}"

# Ensure directory exists
if [ ! -d "$dir" ]; then
  exit 0
fi

for file in "$dir"/*.md; do
  # Handle case where glob matches nothing
  [ -e "$file" ] || continue

  # Skip _index.md if present
  basename=$(basename "$file")
  if [ "$basename" = "_index.md" ]; then
    continue
  fi

  name=""
  description=""
  in_frontmatter=0

  while IFS= read -r line; do
    # Detect frontmatter boundaries
    if [ "$line" = "---" ]; then
      if [ "$in_frontmatter" -eq 0 ]; then
        in_frontmatter=1
        continue
      else
        # End of frontmatter
        break
      fi
    fi

    if [ "$in_frontmatter" -eq 1 ]; then
      # Extract name field
      case "$line" in
        name:*)
          name="${line#name:}"
          name="${name# }"
          name="${name#\"}"
          name="${name%\"}"
          name="${name#\'}"
          name="${name%\'}"
          ;;
        description:*)
          description="${line#description:}"
          description="${description# }"
          description="${description#\"}"
          description="${description%\"}"
          description="${description#\'}"
          description="${description%\'}"
          ;;
      esac
    fi
  done < "$file"

  # Only output if we found both fields
  if [ -n "$name" ] && [ -n "$description" ]; then
    printf '%s\t%s\t%s\n' "$name" "$description" "$file"
  fi
done
