#!/usr/bin/env bash
# index-checks.sh — Index check files by reading YAML frontmatter.
# Outputs tab-separated: name\tdescription\tlanguages\tseverity\tconfidence\tattribution-name\tattribution-url\tfilepath
# Usage: index-checks.sh [directory]
# Default directory: grimoire/spells/checks/

set -euo pipefail

dir="${1:-grimoire/spells/checks/}"

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
  languages=""
  severity=""
  confidence=""
  attribution_name=""
  attribution_url=""
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
        languages:*)
          languages="${line#languages:}"
          languages="${languages# }"
          languages="${languages#\"}"
          languages="${languages%\"}"
          languages="${languages#\[}"
          languages="${languages%\]}"
          ;;
        severity-default:*)
          severity="${line#severity-default:}"
          severity="${severity# }"
          ;;
        confidence:*)
          confidence="${line#confidence:}"
          confidence="${confidence# }"
          ;;
        attribution-name:*)
          attribution_name="${line#attribution-name:}"
          attribution_name="${attribution_name# }"
          attribution_name="${attribution_name#\"}"
          attribution_name="${attribution_name%\"}"
          attribution_name="${attribution_name#\'}"
          attribution_name="${attribution_name%\'}"
          ;;
        attribution-url:*)
          attribution_url="${line#attribution-url:}"
          attribution_url="${attribution_url# }"
          attribution_url="${attribution_url#\"}"
          attribution_url="${attribution_url%\"}"
          attribution_url="${attribution_url#\'}"
          attribution_url="${attribution_url%\'}"
          ;;
      esac
    fi
  done < "$file"

  # Only output if we found both required display fields
  if [ -n "$name" ] && [ -n "$description" ]; then
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$description" "$languages" "$severity" "$confidence" "$attribution_name" "$attribution_url" "$file"
  fi
done
