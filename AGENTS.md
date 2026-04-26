# AGENTS.md

This file provides guidance to Codex when working with this repository.

## Project Overview

Grimoire is a Codex plugin for security research. It is a collection of markdown-driven
skills, command workflows, reference documents, scripts, and optional MCP integrations.
There is no traditional build system, runtime, or compiled application.

## Architecture

### Specification vs Implementation

- `grimoire/` is the human-written specification and design vault. Treat it as read-only.
- `skills/` contains implemented Codex skills and their references, examples, and scripts.
- `commands/` contains Codex slash-command workflow definitions converted from the original
  command surface.
- `.codex-plugin/plugin.json` is the Codex plugin manifest.
- `.mcp.json` declares optional MCP servers for Solodit/Claudit and Context7 lookups.

### Implemented Skills

- `summon` initializes an audit workspace and writes `GRIMOIRE.md`.
- `cartography`, `review-cartography`, and `gc-cartography` map and maintain code-flow context.
- `finding`, `finding-draft`, `finding-review`, and `finding-dedup` structure and triage findings.
- `write-poc` writes authorized, benign proof-of-concept code.
- `checks` manages reusable vulnerability pattern checks.
- `scribe-*` skills distill findings into reusable checks and maintain the spellbook.
- `librarian-*` skills index, search, and maintain external/local research libraries.

## Codex Conventions

- Keep skills concise and progressively disclosed: put deep details in `references/`, runnable
  automation in `scripts/`, and examples in `examples/`.
- Do not modify the `grimoire/` specification tree unless the user explicitly asks.
- Prefer Codex-native skill descriptions over provider-specific command names or tool names.
- Only delegate to workers when the active Codex session and the user explicitly permit it.
  Otherwise, run the same workflow locally with focused file reads, `rg`, and concise checkpoints.
- Preserve Grimoire's security boundaries: authorized contexts only, benign payloads, parameterized
  targets, and concrete reproducibility for every finding.
