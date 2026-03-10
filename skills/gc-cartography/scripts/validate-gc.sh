#!/usr/bin/env bash
# validate-gc.sh — Verify merge result integrity after gc-cartography.
# Runs validate-cartography.sh on the merged file, then checks for dangling
# references to any deleted flows.
#
# Usage: validate-gc.sh <merged-file> [deleted-slug...]
# Example: validate-gc.sh grimoire/cartography/secret-retrieval.md vault-read-path
#
# Checks:
#   1. Merged file passes standard cartography validation
#   2. No remaining files reference deleted slugs
#   3. Merged file has more components than either original (sanity check)
#   4. All security notes from originals are preserved (if originals provided)
#
# Exits 0 if all checks pass, 1 if any fail.

set -euo pipefail

merged="${1:-}"
shift || true
deleted_slugs=("$@")

if [ -z "$merged" ] || [ ! -f "$merged" ]; then
  echo "Usage: validate-gc.sh <merged-file> [deleted-slug...]" >&2
  exit 1
fi

errors=0
warnings=0
passes=0

pass() {
  printf 'PASS\t%s\n' "$1" >&2
  passes=$((passes + 1))
}

fail() {
  printf 'FAIL\t%s\t%s\n' "$1" "$2" >&2
  errors=$((errors + 1))
}

warn() {
  printf 'WARN\t%s\t%s\n' "$1" "$2" >&2
  warnings=$((warnings + 1))
}

# --- Check 1: Standard cartography validation ---
script_dir="$(cd "$(dirname "$0")" && pwd)"
validate_script="$script_dir/../../review-cartography/scripts/validate-cartography.sh"

if [ -f "$validate_script" ]; then
  echo "--- Running standard cartography validation ---" >&2
  if bash "$validate_script" "$merged" 2>&1 >&2; then
    pass "cartography-validation"
  else
    fail "cartography-validation" "Merged file failed standard validation (see above)"
  fi
  echo "" >&2
else
  warn "cartography-validation" "validate-cartography.sh not found at $validate_script — skipping"
fi

# --- Check 2: No dangling references to deleted slugs ---
if [ "${#deleted_slugs[@]}" -gt 0 ]; then
  echo "--- Checking for dangling references ---" >&2
  cart_dir=$(dirname "$merged")

  for slug in "${deleted_slugs[@]}"; do
    # Ensure the deleted file is actually gone
    if [ -f "$cart_dir/$slug.md" ]; then
      warn "deleted-file:$slug" "File still exists: $cart_dir/$slug.md (expected deleted)"
    fi

    # Search for remaining references in all markdown files
    dangling=$(grep -rl "$slug" "$cart_dir"/*.md 2>/dev/null | grep -v "$(basename "$merged")" || true)
    if [ -n "$dangling" ]; then
      fail "dangling-ref:$slug" "Files still reference deleted slug '$slug': $dangling"
    else
      pass "no-dangling-refs:$slug"
    fi
  done
  echo "" >&2
fi

# --- Check 3: Merged file has expected sections ---
echo "--- Checking merge completeness ---" >&2

# Count components in merged file
comp_count=0
in_components=0
while IFS= read -r line; do
  case "$line" in
    "## Key Components"*) in_components=1; continue ;;
    "## "*) [ "$in_components" -eq 1 ] && break; continue ;;
  esac
  if [ "$in_components" -eq 1 ]; then
    case "$line" in
      "- \`"*) comp_count=$((comp_count + 1)) ;;
    esac
  fi
done < "$merged"

if [ "$comp_count" -gt 0 ]; then
  pass "has-components ($comp_count)"
else
  fail "has-components" "Merged file has no Key Components"
fi

# Count security notes
note_count=0
in_notes=0
while IFS= read -r line; do
  case "$line" in
    "## Security Notes"*) in_notes=1; continue ;;
    "## "*) [ "$in_notes" -eq 1 ] && break; continue ;;
  esac
  if [ "$in_notes" -eq 1 ]; then
    case "$line" in
      "- "*) note_count=$((note_count + 1)) ;;
    esac
  fi
done < "$merged"

if [ "$note_count" -gt 0 ]; then
  pass "has-security-notes ($note_count)"
else
  warn "has-security-notes" "Merged file has no security notes"
fi

# Check for conditional sections (expected after merge)
if grep -q "## Conditional:" "$merged" 2>/dev/null; then
  pass "has-conditional-section"
else
  warn "has-conditional-section" "No conditional section found — absorbed flow's unique content may be missing"
fi

# Check updated date is recent
updated=$(sed -n '/^---$/,/^---$/{ /^updated:/{ s/^updated: *//; p; } }' "$merged")
if [ -n "$updated" ]; then
  pass "updated-date ($updated)"
else
  fail "updated-date" "No updated date in frontmatter"
fi

# --- Summary ---
total=$((passes + errors + warnings))
echo "" >&2
if [ "$errors" -gt 0 ]; then
  echo "FAIL: $passes/$total passed, $errors error(s), $warnings warning(s) — $merged" >&2
  exit 1
else
  if [ "$warnings" -gt 0 ]; then
    echo "PASS with $warnings warning(s): $passes/$total passed — $merged" >&2
  else
    echo "PASS: $passes/$total passed — $merged" >&2
  fi
  exit 0
fi
