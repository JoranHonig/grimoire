#!/usr/bin/env bash
# merge-flows.sh — Merge two cartography files by combining their sections.
# Produces a merged file from a primary and absorbed flow.
#
# Usage: merge-flows.sh <primary-file> <absorbed-file> [output-file]
# If output-file is omitted, writes to primary-file (in-place merge).
#
# The script performs structural merging:
#   - Combines frontmatter (union of tags, related; primary name kept)
#   - Unions entry points and key components (deduplicated)
#   - Keeps primary flow sequence as main body
#   - Moves absorbed flow's unique content into a conditional section
#   - Unions security notes (preserves all)
#
# Does NOT delete the absorbed file — that's a manual step after review.
# Exits 0 on success, 1 on error.

set -euo pipefail

primary="${1:-}"
absorbed="${2:-}"
output="${3:-$primary}"

if [ -z "$primary" ] || [ -z "$absorbed" ]; then
  echo "Usage: merge-flows.sh <primary-file> <absorbed-file> [output-file]" >&2
  exit 1
fi

if [ ! -f "$primary" ]; then
  echo "Primary file not found: $primary" >&2
  exit 1
fi

if [ ! -f "$absorbed" ]; then
  echo "Absorbed file not found: $absorbed" >&2
  exit 1
fi

tmpdir="${TMPDIR:-/tmp}/merge-flows.$$"
mkdir -p "$tmpdir"
trap 'rm -rf "$tmpdir"' EXIT

today=$(date +%Y-%m-%d)

# --- Parse frontmatter from a file ---
parse_frontmatter() {
  local file="$1"
  local prefix="$2"
  local in_fm=0
  while IFS= read -r line; do
    if [ "$line" = "---" ]; then
      if [ "$in_fm" -eq 0 ]; then in_fm=1; continue; else break; fi
    fi
    if [ "$in_fm" -eq 1 ]; then
      case "$line" in
        name:*) echo "${prefix}_name=${line#name: }" ;;
        description:*) echo "${prefix}_description=${line#description: }" ;;
        created:*) echo "${prefix}_created=${line#created: }" ;;
        updated:*) echo "${prefix}_updated=${line#updated: }" ;;
        tags:*) echo "${prefix}_tags=${line#tags: }" ;;
        related:*) echo "${prefix}_related=${line#related: }" ;;
      esac
    fi
  done < "$file"
}

# --- Extract a body section from a file ---
extract_section() {
  local file="$1"
  local section="$2"
  local in_section=0
  local past_frontmatter=0
  local fm_count=0

  while IFS= read -r line; do
    if [ "$line" = "---" ]; then
      fm_count=$((fm_count + 1))
      if [ "$fm_count" -eq 2 ]; then past_frontmatter=1; fi
      continue
    fi
    [ "$past_frontmatter" -eq 0 ] && continue

    case "$line" in
      "## $section"*)
        in_section=1
        continue
        ;;
      "## "*)
        if [ "$in_section" -eq 1 ]; then break; fi
        continue
        ;;
    esac
    if [ "$in_section" -eq 1 ]; then
      echo "$line"
    fi
  done < "$file"
}

# --- Extract list items (lines starting with "- ") ---
extract_list_items() {
  while IFS= read -r line; do
    case "$line" in
      "- "*) echo "$line" ;;
    esac
  done
}

# --- Parse tags from [a, b, c] format ---
parse_tags() {
  local raw="$1"
  raw="${raw#\[}"
  raw="${raw%\]}"
  echo "$raw" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | sort -u
}

# --- Parse primary and absorbed frontmatter ---
eval "$(parse_frontmatter "$primary" "p")"
eval "$(parse_frontmatter "$absorbed" "a")"

# Merge tags (union)
{
  parse_tags "${p_tags:-}"
  parse_tags "${a_tags:-}"
} | sort -u | grep -v '^$' > "$tmpdir/merged_tags.txt"
merged_tags=$(paste -sd ', ' "$tmpdir/merged_tags.txt")

# Merge related (union, removing absorbed flow's slug)
absorbed_slug=$(basename "$absorbed" .md)
{
  parse_tags "${p_related:-}"
  parse_tags "${a_related:-}"
} | sort -u | grep -v '^$' | grep -v "^${absorbed_slug}$" > "$tmpdir/merged_related.txt"
merged_related=$(paste -sd ', ' "$tmpdir/merged_related.txt")

# --- Extract sections from both files ---
extract_section "$primary" "Overview" > "$tmpdir/p_overview.txt"
extract_section "$absorbed" "Overview" > "$tmpdir/a_overview.txt"
extract_section "$primary" "Entry Points" > "$tmpdir/p_entry.txt"
extract_section "$absorbed" "Entry Points" > "$tmpdir/a_entry.txt"
extract_section "$primary" "Key Components" > "$tmpdir/p_components.txt"
extract_section "$absorbed" "Key Components" > "$tmpdir/a_components.txt"
extract_section "$primary" "Flow Sequence" > "$tmpdir/p_sequence.txt"
extract_section "$absorbed" "Flow Sequence" > "$tmpdir/a_sequence.txt"
extract_section "$primary" "Security Notes" > "$tmpdir/p_notes.txt"
extract_section "$absorbed" "Security Notes" > "$tmpdir/a_notes.txt"

# --- Merge entry points (union, deduplicated by path) ---
{
  extract_list_items < "$tmpdir/p_entry.txt"
  extract_list_items < "$tmpdir/a_entry.txt"
} | sort -u > "$tmpdir/merged_entry.txt"

# --- Merge key components (union, deduplicated by path) ---
# When both have the same path, keep the longer (more descriptive) line
declare -A component_lines
while IFS= read -r line; do
  case "$line" in
    "- \`"*)
      path="${line#- \`}"
      path="${path%%\`*}"
      path="${path%%:*}"
      existing="${component_lines[$path]:-}"
      if [ -z "$existing" ] || [ "${#line}" -gt "${#existing}" ]; then
        component_lines["$path"]="$line"
      fi
      ;;
  esac
done < <(cat "$tmpdir/p_components.txt" "$tmpdir/a_components.txt")

# Output components sorted by path
for path in $(echo "${!component_lines[@]}" | tr ' ' '\n' | sort); do
  echo "${component_lines[$path]}"
done > "$tmpdir/merged_components.txt"

# --- Merge security notes (union, deduplicated) ---
{
  extract_list_items < "$tmpdir/p_notes.txt"
  extract_list_items < "$tmpdir/a_notes.txt"
} | sort -u > "$tmpdir/merged_notes.txt"

# --- Build absorbed flow's unique content as conditional section ---
# Find components unique to absorbed flow
a_unique_components=""
while IFS= read -r line; do
  case "$line" in
    "- \`"*)
      path="${line#- \`}"
      path="${path%%\`*}"
      path="${path%%:*}"
      if ! grep -qF "$path" "$tmpdir/p_components.txt" 2>/dev/null; then
        a_unique_components="${a_unique_components}${line}\n"
      fi
      ;;
  esac
done < "$tmpdir/a_components.txt"

# Check if absorbed flow has a meaningfully different sequence
absorbed_name="${a_name:-$(basename "$absorbed" .md)}"
absorbed_name="${absorbed_name#\"}"
absorbed_name="${absorbed_name%\"}"

# --- Write merged output ---
{
  # Frontmatter
  echo "---"
  echo "name: ${p_name:-$(basename "$primary" .md)}"

  # Update description if absorbed flow adds scope
  echo "description: ${p_description:-}"

  echo "created: ${p_created:-$today}"
  echo "updated: $today"

  if [ -n "$merged_tags" ]; then
    echo "tags: [$merged_tags]"
  fi
  if [ -n "$merged_related" ]; then
    echo "related: [$merged_related]"
  fi
  echo "---"

  # Overview — keep primary's overview
  echo ""
  echo "## Overview"
  echo ""
  cat "$tmpdir/p_overview.txt"

  # Entry Points — merged
  echo ""
  echo "## Entry Points"
  echo ""
  cat "$tmpdir/merged_entry.txt"

  # Key Components — merged
  echo ""
  echo "## Key Components"
  echo ""
  cat "$tmpdir/merged_components.txt"

  # Flow Sequence — primary's sequence
  echo ""
  echo "## Flow Sequence"
  echo ""
  cat "$tmpdir/p_sequence.txt"

  # Conditional section for absorbed flow's sequence (if non-empty)
  if [ -s "$tmpdir/a_sequence.txt" ]; then
    echo ""
    echo "## Conditional: $absorbed_name"
    echo ""
    echo "<!-- condition: load only when investigating ${absorbed_name,,} specifics -->"
    echo ""
    cat "$tmpdir/a_sequence.txt"
  fi

  # Security Notes — merged
  echo ""
  echo "## Security Notes"
  echo ""
  cat "$tmpdir/merged_notes.txt"

} > "$tmpdir/merged.md"

# Remove excessive blank lines (3+ consecutive -> 2)
sed '/^$/N;/^\n$/N;/^\n\n$/d' "$tmpdir/merged.md" > "$output"

echo "Merged: $primary + $absorbed -> $output" >&2
echo "Components: $(wc -l < "$tmpdir/merged_components.txt" | tr -d ' ') (deduplicated union)" >&2
echo "Security notes: $(wc -l < "$tmpdir/merged_notes.txt" | tr -d ' ') (all preserved)" >&2
echo "" >&2
echo "Next steps:" >&2
echo "  1. Review the merged file and adjust description/overview if scope broadened" >&2
echo "  2. Review the conditional section — edit or restructure as needed" >&2
echo "  3. Delete the absorbed file: rm $absorbed" >&2
echo "  4. Run: bash skills/gc-cartography/scripts/update-references.sh $(basename "$absorbed" .md) $(basename "$primary" .md)" >&2
echo "  5. Run: bash skills/gc-cartography/scripts/validate-gc.sh $output" >&2

exit 0
