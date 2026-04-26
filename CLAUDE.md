# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Grimoire is a Claude Code plugin — a security research toolkit that transforms vulnerability discovery into structured proof-of-concept code for responsible disclosure. It's a collection of markdown-driven skills, reference documents, and (planned) agents. There is no traditional build system, runtime, or compiled code.

**Install:** `claude --plugin-dir /path/to/grimoire`

## Architecture

### Specification vs Implementation (Critical)

The codebase has a strict separation:

- **`grimoire/`** — Human-written specifications (source of truth). **Read-only.** Never modify these files. They are an Obsidian vault containing agent specs, concept docs, skill specs, and the project roadmap (`notes.md`).
- **`skills/`** — Implementation of those specs as Claude Code skills. This is where development happens.
- **`.claude/commands/gap-analysis.md`** — Command that compares specs against implementation to identify what needs building.

### Plugin Structure

```
.claude-plugin/plugin.json    # Manifest (v0.1.0, auto-discovers skills)
skills/                       # Implemented skills (each is a directory)
  <skill-name>/
    SKILL.md                  # Skill instructions (frontmatter + workflow)
    references/               # Deep-dive docs the skill can reference
    examples/                 # Worked examples
    scripts/                  # Automation (bash)
grimoire/                     # Specs — DO NOT MODIFY
forge-poc-templates/          # Git submodule: Immunefi's Solidity PoC library
```

### Implemented Skills

| Skill | Purpose |
|-------|---------|
| `write-poc` | Write proof-of-concept exploits (6-phase workflow, 10 reference docs covering 20+ vuln classes) |
| `summon` | Initialize a grimoire workspace on a new codebase (creates GRIMOIRE.md, maps architecture) |
| `cartography` | Map and document code flows with indexed YAML-frontmatter cartography files |
| `review-cartography` | Verify and refine existing cartography flows |
| `gc-cartography` | Detect overlapping flows, merge/deduplicate cartography |

### Specified but Not Yet Implemented

**Skills:** Semgrep rules, Slither detectors, CodeQL integration

Use `/gap-analysis` to get a current prioritized view of what's spec'd vs built.

## Skill Development Conventions

- Each skill lives in `skills/<name>/` with a `SKILL.md` containing YAML frontmatter (name, description, triggers, `user_invocable: true`)
- **Skill names must be lowercase and hyphenated** (e.g. `write-poc`, `gc-cartography`) — no spaces, no capitals. The `name` field in SKILL.md frontmatter and the directory name must both follow this format. This matches the Claude Code skill spec: only lowercase letters, numbers, and hyphens are allowed (max 64 characters).
- Skills use numbered-step workflows with explicit human confirmation points
- Supporting material goes in `references/` and `examples/` subdirectories
- All skills produce concrete artifacts (GRIMOIRE.md, cartography files, PoC scripts)
- Skills auto-load via `"skills": "auto"` in plugin.json — no manifest changes needed

## Key Principles

- **Trivial verifiability**: Every finding must be provable with a concrete artifact
- **Minimum viable proof**: Demonstrate the issue exists, nothing beyond that
- **Benign payloads only**: `alert(1)`, `sleep()`, `id` — never destructive commands
- **Parameterized targets**: localhost and variables, never hardcoded production URLs
- **Authorized contexts only**: pentesting, bug bounty, coordinated disclosure, CTF
