---
name: librarian
description: Use when the user asks to look up, research, fact-check, find documentation, inspect a specification, search prior audit findings, or answer a security question that requires sources outside the current codebase.
---

# Librarian

Use `../../agents/librarian.md` as the role prompt for this workflow.

Only use Codex workers when the user explicitly asks for delegation or parallel agent work.
Otherwise, perform the research locally. Every factual claim in the final answer must be backed
by a citation or explicitly marked as uncited/unknown.
