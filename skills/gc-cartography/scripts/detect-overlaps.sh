#!/usr/bin/env bash
# detect-overlaps.sh — Detect overlapping cartography files with merge recommendations.
# Wraps review-cartography's find-overlaps.sh and adds:
#   - Subset detection (smaller flow 100% contained in larger)
#   - Cluster detection (groups of connected overlapping flows)
#   - Primary flow suggestion (based on component count)
#
# Usage: detect-overlaps.sh [directory] [threshold]
# Default directory: grimoire/cartography/  Default threshold: 40
# Exits 0 if no merge candidates, 1 if candidates found.

set -euo pipefail

dir="${1:-grimoire/cartography/}"
threshold="${2:-40}"

if [ ! -d "$dir" ]; then
  echo "Directory not found: $dir" >&2
  exit 1
fi

# Locate find-overlaps.sh relative to this script
script_dir="$(cd "$(dirname "$0")" && pwd)"
find_overlaps="$script_dir/../../review-cartography/scripts/find-overlaps.sh"

if [ ! -f "$find_overlaps" ]; then
  echo "Error: find-overlaps.sh not found at $find_overlaps" >&2
  echo "This script requires review-cartography/scripts/find-overlaps.sh" >&2
  exit 1
fi

tmpdir="${TMPDIR:-/tmp}/detect-overlaps.$$"
mkdir -p "$tmpdir"
trap 'rm -rf "$tmpdir"' EXIT

# --- Step 1: Run base overlap detection ---
# Capture stdout (overlap lines) and stderr (info/summary) separately
bash "$find_overlaps" "$dir" "$threshold" > "$tmpdir/overlaps.tsv" 2> "$tmpdir/info.txt" || true

if [ ! -s "$tmpdir/overlaps.tsv" ]; then
  echo "No overlaps exceed ${threshold}% threshold." >&2
  cat "$tmpdir/info.txt" >&2
  exit 0
fi

# --- Step 2: Count components per flow for primary suggestion ---
count_components() {
  local file="$1"
  local count=0
  local in_components=0
  while IFS= read -r line; do
    case "$line" in
      "## Key Components"*) in_components=1; continue ;;
      "## "*) [ "$in_components" -eq 1 ] && break; continue ;;
    esac
    if [ "$in_components" -eq 1 ]; then
      case "$line" in
        "- \`"*) count=$((count + 1)) ;;
      esac
    fi
  done < "$file"
  echo "$count"
}

count_security_notes() {
  local file="$1"
  local count=0
  local in_notes=0
  while IFS= read -r line; do
    case "$line" in
      "## Security Notes"*) in_notes=1; continue ;;
      "## "*) [ "$in_notes" -eq 1 ] && break; continue ;;
    esac
    if [ "$in_notes" -eq 1 ]; then
      case "$line" in
        "- "*) count=$((count + 1)) ;;
      esac
    fi
  done < "$file"
  echo "$count"
}

# Build a lookup of slug -> file path
declare -A slug_to_file
for file in "$dir"/*.md; do
  [ -e "$file" ] || continue
  basename=$(basename "$file")
  [ "$basename" = "_index.md" ] && continue
  slug="${basename%.md}"
  slug_to_file["$slug"]="$file"
done

# --- Step 3: Enrich overlap data with merge recommendations ---
echo "=== GC-Cartography Merge Candidates ===" >&2
echo "" >&2

candidates=0
while IFS=$'\t' read -r name_a name_b pct shared_files; do
  candidates=$((candidates + 1))

  # Find files by matching name in frontmatter
  file_a=""
  file_b=""
  for slug in "${!slug_to_file[@]}"; do
    f="${slug_to_file[$slug]}"
    # Extract name from frontmatter
    fm_name=$(sed -n '/^---$/,/^---$/{ /^name:/{ s/^name: *//; s/^"//; s/"$//; p; } }' "$f")
    if [ "$fm_name" = "$name_a" ] && [ -z "$file_a" ]; then
      file_a="$f"
    elif [ "$fm_name" = "$name_b" ] && [ -z "$file_b" ]; then
      file_b="$f"
    fi
  done

  # Fallback: try slug matching if name matching failed
  if [ -z "$file_a" ] || [ -z "$file_b" ]; then
    for slug in "${!slug_to_file[@]}"; do
      f="${slug_to_file[$slug]}"
      if [ -z "$file_a" ] && [[ "$(basename "$f" .md)" == *"${name_a// /-}"* ]]; then
        file_a="$f"
      fi
      if [ -z "$file_b" ] && [[ "$(basename "$f" .md)" == *"${name_b// /-}"* ]]; then
        file_b="$f"
      fi
    done
  fi

  # Get component and note counts
  comp_a=0; comp_b=0; notes_a=0; notes_b=0
  if [ -n "$file_a" ] && [ -f "$file_a" ]; then
    comp_a=$(count_components "$file_a")
    notes_a=$(count_security_notes "$file_a")
  fi
  if [ -n "$file_b" ] && [ -f "$file_b" ]; then
    comp_b=$(count_components "$file_b")
    notes_b=$(count_security_notes "$file_b")
  fi

  # Detect subset
  shared_count=$(echo "$shared_files" | tr ',' '\n' | wc -l | tr -d ' ')
  is_subset=""
  if [ "$comp_a" -gt 0 ] && [ "$shared_count" -eq "$comp_a" ]; then
    is_subset="$name_a is a subset of $name_b"
  elif [ "$comp_b" -gt 0 ] && [ "$shared_count" -eq "$comp_b" ]; then
    is_subset="$name_b is a subset of $name_a"
  fi

  # Suggest primary
  if [ "$comp_a" -gt "$comp_b" ]; then
    primary="$name_a"
    absorbed="$name_b"
  elif [ "$comp_b" -gt "$comp_a" ]; then
    primary="$name_b"
    absorbed="$name_a"
  elif [ "$notes_a" -ge "$notes_b" ]; then
    primary="$name_a"
    absorbed="$name_b"
  else
    primary="$name_b"
    absorbed="$name_a"
  fi

  # Output enriched record
  printf '%s\t%s\t%s\t%s\n' "$name_a" "$name_b" "$pct" "$shared_files"

  # Enriched report to stderr
  echo "--- Candidate $candidates ---" >&2
  echo "  Flow A: $name_a ($comp_a components, $notes_a security notes)" >&2
  echo "  Flow B: $name_b ($comp_b components, $notes_b security notes)" >&2
  echo "  Overlap: $pct" >&2
  echo "  Shared: $shared_files" >&2
  if [ -n "$is_subset" ]; then
    echo "  Subset: $is_subset" >&2
  fi
  echo "  Suggestion: keep \"$primary\" as primary, absorb \"$absorbed\"" >&2
  echo "" >&2
done < "$tmpdir/overlaps.tsv"

# --- Step 4: Detect clusters ---
# A cluster exists when 3+ flows are connected through overlapping pairs
if [ "$candidates" -gt 1 ]; then
  echo "--- Cluster Analysis ---" >&2
  # Collect all flow names involved in overlaps
  all_flows=$(cut -f1,2 "$tmpdir/overlaps.tsv" | tr '\t' '\n' | sort -u)
  flow_count=$(echo "$all_flows" | wc -l | tr -d ' ')
  if [ "$flow_count" -ge 3 ]; then
    echo "  $flow_count flows involved in overlapping pairs — possible overlap cluster" >&2
    echo "  Consider consolidating into fewer flows, starting with highest-overlap pair" >&2
  else
    echo "  No clusters detected (overlapping pairs are independent)" >&2
  fi
  echo "" >&2
fi

# --- Summary ---
echo "Found $candidates merge candidate(s) exceeding ${threshold}% threshold" >&2

exit 1
