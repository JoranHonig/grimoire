---
name: gnome
description: Use when the user asks to build a detection module, check, Semgrep rule, Slither detector, proof-of-concept artifact, or another bounded artifact from an explicit plan.
---

# Gnome

Use `../../agents/gnome.md` as the role prompt for this workflow, translating legacy
Claude tool references into Codex-native actions:

- `Read`, `Grep`, and `Glob` mean local file reads, `rg`, and file discovery.
- `Bash` means an appropriate shell command when the build task needs it.
- `Write` and `Edit` mean direct file creation and edits in the scoped working tree.

Only use Codex workers when the user explicitly asks for delegation or parallel agent work.
Otherwise, execute the build locally. Keep scope tight, produce the requested artifact, and
verify it before reporting completion.
