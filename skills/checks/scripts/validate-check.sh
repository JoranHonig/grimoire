#!/usr/bin/env bash
# validate-check.sh — Validate a check file has required frontmatter fields.
# Usage: validate-check.sh <check-file>
# Exits 0 if valid, 1 if invalid. Prints issues to stderr.

set -euo pipefail

file="${1:-}"
if [ -z "$file" ] || [ ! -f "$file" ]; then
  echo "Usage: validate-check.sh <check-file>" >&2
  exit 1
fi

errors=0
warnings=0

# Required frontmatter fields
name=""
description=""
languages=""
severity=""
confidence=""
tools=""
attribution_name=""
attribution_url=""
in_frontmatter=0
frontmatter_closed=0
body_lines=0

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
      name:*) name="${line#name:}" ;;
      description:*) description="${line#description:}" ;;
      languages:*) languages="${line#languages:}" ;;
      severity-default:*) severity="${line#severity-default:}" ;;
      confidence:*) confidence="${line#confidence:}" ;;
      tools:*) tools="${line#tools:}" ;;
      attribution-name:*) attribution_name="${line#attribution-name:}" ;;
      attribution-url:*) attribution_url="${line#attribution-url:}" ;;
    esac
  fi

  if [ "$frontmatter_closed" -eq 1 ]; then
    # Count non-empty body lines
    trimmed="${line// /}"
    if [ -n "$trimmed" ]; then
      body_lines=$((body_lines + 1))
    fi
  fi
done < "$file"

# Check frontmatter was found and closed
if [ "$in_frontmatter" -eq 0 ]; then
  echo "ERROR: No frontmatter found (missing opening ---)" >&2
  errors=$((errors + 1))
fi
if [ "$frontmatter_closed" -eq 0 ] && [ "$in_frontmatter" -eq 1 ]; then
  echo "ERROR: Frontmatter not closed (missing closing ---)" >&2
  errors=$((errors + 1))
fi

# Check required fields
check_field() {
  local field_name="$1" field_value="$2"
  field_value="${field_value# }"
  if [ -z "$field_value" ]; then
    echo "ERROR: Missing required field: $field_name" >&2
    errors=$((errors + 1))
  fi
}

check_field "name" "$name"
check_field "description" "$description"
check_field "languages" "$languages"
check_field "severity-default" "$severity"
check_field "confidence" "$confidence"
check_field "tools" "$tools"

# Check body exists
if [ "$body_lines" -eq 0 ]; then
  echo "ERROR: No body content after frontmatter" >&2
  errors=$((errors + 1))
fi

# Warn on long body
if [ "$body_lines" -gt 30 ]; then
  echo "WARNING: Body has $body_lines non-empty lines (recommended max: 30). Consider splitting." >&2
  warnings=$((warnings + 1))
fi

# Warn on malformed attribution URL
attribution_url="${attribution_url# }"
if [ -n "$attribution_url" ]; then
  case "$attribution_url" in
    http://*|https://*)
      ;;
    *)
      echo "WARNING: attribution-url does not start with http:// or https://: $attribution_url" >&2
      warnings=$((warnings + 1))
      ;;
  esac
fi

# Summary
if [ "$errors" -gt 0 ]; then
  echo "FAIL: $errors error(s), $warnings warning(s)" >&2
  exit 1
else
  if [ "$warnings" -gt 0 ]; then
    echo "PASS with $warnings warning(s): $file" >&2
  else
    echo "PASS: $file" >&2
  fi
  exit 0
fi
