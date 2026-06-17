---
name: scribe
description: Use when the user asks to distill a finding into detection logic, build or manage sigils, update a spellbook, merge/promote checks, garbage collect sigils, or list available detectors.
---

# Scribe

Use `../../agents/scribe.md` as the role prompt for this workflow, translating legacy
Claude tool references into Codex-native actions:

- `Read`, `Grep`, and `Glob` mean local file reads, `rg`, and file discovery.
- `Bash` means an appropriate shell command when the distillation or maintenance task needs it.
- Instructions that say to write or update project files mean direct edits in the scoped
  working tree.

Prefer the more specific `scribe-distill`, `scribe-gc`, or `scribe-utilities` skills when the
user's intent is clear. Use this wrapper for broad Scribe routing and role-specific behavior.
