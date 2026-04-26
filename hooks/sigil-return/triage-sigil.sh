#!/usr/bin/env bash
# triage-sigil.sh — PostToolUse hook for the Task tool.
# When a sigil subagent returns, instruct Claude to spawn a Familiar to triage
# the findings before presenting them to the user. For any other subagent type
# (including Familiar itself), exits silently so the hook does not loop.

set -euo pipefail

input=$(cat)

tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty')
if [ "$tool_name" != "Task" ]; then
  exit 0
fi

subagent_type=$(printf '%s' "$input" | jq -r '.tool_input.subagent_type // empty')
if [ "$subagent_type" != "sigil" ]; then
  exit 0
fi

# Opt-out: let researchers disable auto-triage via a project-local flag file.
project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"
if [ -f "$project_dir/.grimoire/no-auto-triage" ]; then
  exit 0
fi

jq -n '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: (
      "A sigil subagent just returned. Per the grimoire workflow, its findings " +
      "must be triaged by a Familiar before being presented to the user. " +
      "Spawn a Familiar now via the Task tool (subagent_type=\"familiar\") and " +
      "point it at the findings the sigil just produced (typically under " +
      "grimoire/sigil-findings/ — use batch triage mode if multiple findings, " +
      "or single-finding triage mode otherwise). Wait for the Familiars verdict, " +
      "then present the triaged results (confirmed and uncertain findings) to " +
      "the user. Mention dismissed counts but do not detail each one unless asked. " +
      "To disable this behaviour for a project, create .grimoire/no-auto-triage."
    )
  }
}'
