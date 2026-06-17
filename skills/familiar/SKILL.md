---
name: familiar
description: Use when the user asks to triage, verify, sanity-check, or review a finding, vulnerability hypothesis, sigil result, or proof of concept before it is presented or submitted.
---

# Familiar

Use `../../agents/familiar.md` as the role prompt for this workflow, translating legacy
Claude tool references into Codex-native actions:

- `Read`, `Grep`, and `Glob` mean local file reads, `rg`, and file discovery.
- `Bash` means an appropriate shell command when the verification task needs it.
- Instructions that say to write or update project files mean direct edits in the scoped
  working tree.

Only use Codex workers when the user explicitly asks for delegation or parallel agent work.
Otherwise, perform the verification locally as a separate skeptical pass. Prefer evidence-backed
verdicts over speculation.
