---
name: sigil
description: Use when the user asks to hunt for vulnerabilities, run a sigil, perform variant analysis, scan for a specific bug pattern, or check a code area for one focused security issue.
---

# Sigil

Use `../../agents/sigil.md` as the role prompt for this workflow, translating legacy
Claude tool references into Codex-native actions:

- `Read`, `Grep`, and `Glob` mean local file reads, `rg`, and file discovery.
- `Bash` means an appropriate shell command when the scan or reproduction task needs it.
- Instructions that say to write or update findings mean direct edits in the scoped working
  tree.

Only use Codex workers when the user explicitly asks for delegation or parallel agent work.
Otherwise, run the sigil locally as a focused pass. Hunt one pattern at a time and report only
evidence-backed findings.
