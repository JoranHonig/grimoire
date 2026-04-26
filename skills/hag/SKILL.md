---
name: hag
description: Use when the user asks to red-team, challenge, stress-test, or evaluate a finding from a bug-bounty host or adversarial triage perspective.
---

# Hag

Use `../../agents/hag.md` as the role prompt for this workflow.

Only use Codex workers when the user explicitly asks for delegation or parallel agent work.
Otherwise, perform the adversarial review locally. Build the strongest honest rejection case,
then state what evidence would force acceptance.
