#!/usr/bin/env bash
# validate-finding.sh — Validate a finding file against the schema.
# Checks frontmatter fields, required sections, and PoC references.
# Usage: validate-finding.sh <finding-file>
# Exits 0 if valid, 1 if errors found. Prints results to stderr.

set -euo pipefail

file="${1:-}"
if [ -z "$file" ] || [ ! -f "$file" ]; then
  echo "Usage: validate-finding.sh <finding-file>" >&2
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

# --- Parse frontmatter ---
title=""
severity=""
type=""
context_found=0
in_frontmatter=0
frontmatter_closed=0

# Section tracking
has_description=0
has_recommendation=0
has_poc_section=0
in_poc_section=0
poc_reference=""

while IFS= read -r line; do
  if [ "$line" = "---" ]; then
    if [ "$in_frontmatter" -eq 0 ]; then
      in_frontmatter=1
      continue
    else
      frontmatter_closed=1
      continue
    fi
  fi

  if [ "$in_frontmatter" -eq 1 ] && [ "$frontmatter_closed" -eq 0 ]; then
    case "$line" in
      title:*)
        title="${line#title:}"
        title="${title# }"
        title="${title#\"}"
        title="${title%\"}"
        last_key="title"
        ;;
      severity:*)
        severity="${line#severity:}"
        severity="${severity# }"
        severity="${severity#\"}"
        severity="${severity%\"}"
        last_key="severity"
        ;;
      type:*)
        type="${line#type:}"
        type="${type# }"
        type="${type#\"}"
        type="${type%\"}"
        last_key="type"
        ;;
      context:*)
        context_found=1
        last_key="context"
        ;;
      "  - "*)
        # YAML list item — only counts for context if immediately following context: key
        if [ "${last_key:-}" = "context" ]; then
          context_found=1
        fi
        ;;
    esac
  fi

  if [ "$frontmatter_closed" -eq 1 ]; then
    # Check for required sections
    case "$line" in
      "## Description"*) has_description=1; in_poc_section=0 ;;
      "## Recommendation"*) has_recommendation=1; in_poc_section=0 ;;
      "## Proof of Concept"*|"## Proof of concept"*) has_poc_section=1; in_poc_section=1 ;;
      "## "*) in_poc_section=0 ;;  # any other heading exits PoC section
    esac

    # Check for @reference only while inside the PoC section
    if [ "$in_poc_section" -eq 1 ] && [ -z "$poc_reference" ]; then
      case "$line" in
        @*) poc_reference="${line#@}" ;;
      esac
    fi
  fi
done < "$file"

# --- Validate frontmatter ---
if [ "$in_frontmatter" -eq 0 ]; then
  fail "frontmatter" "No frontmatter found (missing opening ---)"
elif [ "$frontmatter_closed" -eq 0 ]; then
  fail "frontmatter" "Frontmatter not closed (missing closing ---)"
else
  pass "frontmatter-structure"
fi

# Required fields
if [ -n "$title" ]; then
  pass "title"
else
  fail "title" "Missing required field: title"
fi

if [ -n "$severity" ]; then
  # Validate severity value
  case "$(echo "$severity" | tr '[:upper:]' '[:lower:]')" in
    critical|high|medium|low|informational)
      pass "severity"
      ;;
    *)
      fail "severity" "Invalid severity value: '$severity'. Must be Critical, High, Medium, Low, or Informational"
      ;;
  esac
else
  fail "severity" "Missing required field: severity"
fi

if [ -n "$type" ]; then
  pass "type"
else
  fail "type" "Missing required field: type"
fi

if [ "$context_found" -eq 1 ]; then
  pass "context"
else
  fail "context" "Missing required field: context (list of affected files)"
fi

# --- Validate sections ---
if [ "$has_description" -eq 1 ]; then
  pass "description-section"
else
  fail "description-section" "Missing required section: ## Description"
fi

if [ "$has_recommendation" -eq 1 ]; then
  pass "recommendation-section"
else
  fail "recommendation-section" "Missing required section: ## Recommendation"
fi

# PoC section is optional but if present, check for @reference
if [ "$has_poc_section" -eq 1 ]; then
  if [ -n "$poc_reference" ]; then
    # Check if referenced file exists
    if [ -f "$poc_reference" ]; then
      pass "poc-reference"
    else
      warn "poc-reference" "PoC file not found: $poc_reference"
    fi
  else
    warn "poc-reference" "Proof of Concept section exists but contains no @reference"
  fi
fi

# --- Validate filename ---
basename=$(basename "$file" .md)
if echo "$basename" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
  pass "filename-format"
else
  warn "filename-format" "Filename '$basename' is not strict kebab-case (lowercase alphanumeric with hyphens)"
fi

# --- Summary ---
total=$((passes + errors + warnings))
echo "" >&2
if [ "$errors" -gt 0 ]; then
  echo "FAIL: $passes/$total passed, $errors error(s), $warnings warning(s) — $file" >&2
  exit 1
else
  if [ "$warnings" -gt 0 ]; then
    echo "PASS with $warnings warning(s): $passes/$total passed — $file" >&2
  else
    echo "PASS: $passes/$total passed — $file" >&2
  fi
  exit 0
fi
