---
name: gnome
description: Use when the user asks to build a detection module, check, Semgrep rule, Slither detector, proof-of-concept artifact, or another bounded artifact from an explicit plan.
---

# Gnome

Use `../../agents/gnome.md` as the role prompt for this workflow.

Only use Codex workers when the user explicitly asks for delegation or parallel agent work.
Otherwise, execute the build locally. Keep scope tight, produce the requested artifact, and
verify it before reporting completion.
