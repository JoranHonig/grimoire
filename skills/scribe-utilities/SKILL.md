---
name: scribe-utilities
description: >-
  This skill should be used when the user says "list my sigils", "what detectors
  do I have", "show my spellbook", "scribe info", "/scribe-utilities", "what's
  in my grimoire", "search sigils", "spellbook stats", or wants information about
  available detection modules. Read-only queries against the personal grimoire
  and project spellbook.
---

# Scribe Utilities

Query and explore the contents of the personal grimoire and project spellbook.

## Workflow

When this skill is activated, create a todo list from the following steps. Mark each task
in_progress before starting it and completed when done.

```
- [ ] 1. Determine operation
- [ ] 2. Determine scope
- [ ] 3. Execute query
- [ ] 4. Present results
```

---

### 1. Determine Operation

Identify what the user wants to know. Four operations are available:

- **List** — show all sigils with summary info (default if the user just says "show my
  spellbook" or "what sigils do I have")
- **Describe** — read and present one specific sigil in detail
- **Stats** — aggregate counts by type, vulnerability class, language, severity
- **Search** — find sigils matching a keyword, vulnerability class, language, or tag

### 2. Determine Scope

Ask or infer which collections to query:

- **Personal grimoire** (`~/.grimoire/sigils/` and `~/.grimoire/knowledge/`)
- **Project-local** (`grimoire/spells/checks/` and `grimoire/spells/knowledge/`)
- **Both** (default)

If `~/.grimoire/sigils/` is empty, note that the personal grimoire has no sigils yet and
explain that it is populated through end-of-audit merges (`/scribe-distill` → end-of-audit
merge via scribe Mode 2a).

If project-local directories do not exist, note that no project spellbook exists yet and
suggest running [[summon]] to initialize the workspace.

### 3. Execute Query

**List:** Run `bash skills/checks/scripts/index-checks.sh <path>` for each directory in
scope. Also scan any `knowledge/` directories for knowledge artifacts (these have
frontmatter with name, description, vulnerability-class, languages).

**Describe:** Read the specified sigil file. Extract and format: all frontmatter fields,
search patterns, assessment criteria (for checks), or guidance content (for knowledge
artifacts).

**Stats:** Count sigils across all directories in scope, grouped by:
- Type (check, knowledge artifact)
- Vulnerability class (from tags)
- Language coverage
- Severity distribution

**Search:** Grep across all sigil and knowledge artifact files in scope for the search
term. Match against name, description, tags, and body content. Present matching results
with name, description, and location.

### 4. Present Results

Format output using the Query output format from `agents/scribe.md`:

| Name | Type | Severity | Languages | Description |
|------|------|----------|-----------|-------------|

For knowledge artifacts, show "n/a" for Severity since they are not automated detectors.

If no results are found, confirm the scope was correct and suggest creating detection
modules via `/scribe-distill` from confirmed findings.
