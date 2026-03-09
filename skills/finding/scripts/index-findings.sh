#!/usr/bin/env bash
# index-findings.sh — Index finding files by reading YAML frontmatter.
# Outputs tab-separated: filepath\ttitle\tseverity\ttype
# Scans both grimoire/findings/ and grimoire/sigil-findings/ by default.
# Usage: index-findings.sh [directory ...]
# If no directories given, scans the default finding directories.

set -euo pipefail

# Severity sort order (lower number = higher priority)
severity_order() {
  case "$(echo "$1" | tr '[:upper:]' '[:lower:]')" in
    critical)      echo 1 ;;
    high)          echo 2 ;;
    medium)        echo 3 ;;
    low)           echo 4 ;;
    informational) echo 5 ;;
    *)             echo 9 ;;
  esac
}

# Collect directories to scan
if [ $# -gt 0 ]; then
  dirs=("$@")
else
  dirs=(grimoire/findings/ grimoire/sigil-findings/)
fi

# Temporary file for sorting
tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

for dir in "${dirs[@]}"; do
  # Skip if directory does not exist
  [ -d "$dir" ] || continue

  for file in "$dir"/*.md; do
    # Handle case where glob matches nothing
    [ -e "$file" ] || continue

    # Skip _index.md if present
    basename=$(basename "$file")
    if [ "$basename" = "_index.md" ]; then
      continue
    fi

    title=""
    severity=""
    type=""
    in_frontmatter=0

    while IFS= read -r line; do
      # Detect frontmatter boundaries
      if [ "$line" = "---" ]; then
        if [ "$in_frontmatter" -eq 0 ]; then
          in_frontmatter=1
          continue
        else
          break
        fi
      fi

      if [ "$in_frontmatter" -eq 1 ]; then
        case "$line" in
          title:*)
            title="${line#title:}"
            title="${title# }"
            title="${title#\"}"
            title="${title%\"}"
            title="${title#\'}"
            title="${title%\'}"
            ;;
          severity:*)
            severity="${line#severity:}"
            severity="${severity# }"
            severity="${severity#\"}"
            severity="${severity%\"}"
            ;;
          type:*)
            type="${line#type:}"
            type="${type# }"
            type="${type#\"}"
            type="${type%\"}"
            ;;
        esac
      fi
    done < "$file"

    # Only output if we found the required display fields
    if [ -n "$title" ] && [ -n "$severity" ]; then
      order=$(severity_order "$severity")
      printf '%s\t%s\t%s\t%s\t%s\n' "$order" "$file" "$title" "$severity" "$type" >> "$tmpfile"
    fi
  done
done

# Sort by severity order and output without the sort key
sort -t$'\t' -k1,1n "$tmpfile" | cut -f2-
