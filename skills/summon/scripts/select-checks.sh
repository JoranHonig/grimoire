#!/usr/bin/env bash
# select-checks.sh — Filter checks by target language(s).
# Wraps index-checks.sh and filters by language overlap.
# Usage: select-checks.sh [checks-directory] [target-languages]
# Example: select-checks.sh grimoire/spells/checks/ "solidity,javascript"
# Output: tab-separated rows from index-checks.sh for matching checks only.
# A check matches if its languages field overlaps with any target language,
# or if its languages field is empty (applies to all languages).

set -euo pipefail

dir="${1:-grimoire/spells/checks/}"
target_langs="${2:-}"

# Resolve path to index-checks.sh relative to this script's location
script_dir="$(cd "$(dirname "$0")" && pwd)"
index_script="$script_dir/../../checks/scripts/index-checks.sh"

if [ ! -f "$index_script" ]; then
  echo "Error: index-checks.sh not found at $index_script" >&2
  exit 1
fi

# If no target languages specified, output all checks
if [ -z "$target_langs" ]; then
  bash "$index_script" "$dir"
  exit 0
fi

# Normalize target languages: lowercase, split by comma, trim whitespace
IFS=',' read -ra raw_targets <<< "$target_langs"
declare -a targets=()
for t in "${raw_targets[@]}"; do
  # Trim whitespace and lowercase
  cleaned=$(echo "$t" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  if [ -n "$cleaned" ]; then
    targets+=("$cleaned")
  fi
done

# Read index output and filter
bash "$index_script" "$dir" | while IFS=$'\t' read -r name description languages severity confidence filepath; do
  # Empty languages field = matches all
  if [ -z "$languages" ]; then
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$description" "$languages" "$severity" "$confidence" "$filepath"
    continue
  fi

  # Normalize check languages: lowercase, split by comma, trim
  check_langs_lower=$(echo "$languages" | tr '[:upper:]' '[:lower:]')
  IFS=',' read -ra check_langs <<< "$check_langs_lower"

  matched=0
  for cl in "${check_langs[@]}"; do
    cl_clean=$(echo "$cl" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    for tl in "${targets[@]}"; do
      if [ "$cl_clean" = "$tl" ]; then
        matched=1
        break 2
      fi
    done
  done

  if [ "$matched" -eq 1 ]; then
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$description" "$languages" "$severity" "$confidence" "$filepath"
  fi
done
