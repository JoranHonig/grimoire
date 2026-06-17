---
name: librarian
description: Use when the user asks to look up, research, fact-check, find documentation, inspect a specification, search prior audit findings, or answer a security question that requires sources outside the current codebase.
---

# Librarian

Use `../../agents/librarian.md` as the role prompt for this workflow, translating legacy
Claude tool references into Codex-native actions:

- `Read`, `Grep`, and `Glob` mean local file reads, `rg`, and file discovery.
- `Bash` means an appropriate shell command when the research task needs it.
- `WebSearch` and `WebFetch` mean Codex web browsing with source links.
- `mcp__plugin_grimoire_context7__*` and `mcp__plugin_grimoire_claudit__*` mean the
  optional `context7` and `claudit` MCP servers declared in `.mcp.json`; if unavailable,
  state that clearly and use an approved fallback source.

Only use Codex workers when the user explicitly asks for delegation or parallel agent work.
Otherwise, perform the research locally. Every factual claim in the final answer must be backed
by a citation or explicitly marked as uncited/unknown.
