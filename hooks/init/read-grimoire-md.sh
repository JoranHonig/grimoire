#!/usr/bin/env bash
# read-grimoire-md.sh — If GRIMOIRE.md exists in the project root, inject its
# contents as additional SessionStart context so Claude has it at session start.

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
GRIMOIRE_MD="$PROJECT_DIR/GRIMOIRE.md"

if [ ! -f "$GRIMOIRE_MD" ]; then
  exit 0
fi

contents=$(cat "$GRIMOIRE_MD")

python3 -c '
import json, sys
contents = sys.stdin.read()
out = {
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "Project GRIMOIRE.md contents (auto-loaded at session start):\n\n" + contents
  }
}
sys.stdout.write(json.dumps(out))
' <<< "$contents"
