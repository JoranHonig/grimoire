---
name: scribe-gc
description: >-
  This skill should be used when the user says "clean up sigils", "garbage
  collect", "deduplicate sigils", "scribe gc", "/scribe-gc", "merge duplicate
  detectors", "review my spellbook", "prune sigils", or when duplicate detection
  modules need to be identified and resolved. Scans the personal grimoire or
  project spellbook for overlapping or duplicate sigils and proposes resolutions.
user_invocable: true
---

# Scribe GC

Detect and resolve duplicate or overlapping detection modules in the spellbook.

## Philosophy

A cluttered spellbook is worse than a small one. Duplicate sigils waste token budget when
applied, confuse triage with redundant findings, and make the spellbook harder to maintain.
Regular garbage collection keeps the spellbook lean and effective.

## Workflow

When this skill is activated, create a todo list from the following steps. Mark each task
in_progress before starting it and completed when done.

```
- [ ] 1. Determine scope
- [ ] 2. Inventory sigils
- [ ] 3. Detect overlaps
- [ ] 4. Propose resolutions
- [ ] 5. Execute approved changes
```

---

### 1. Determine Scope

Ask the user which scope to review:

- **Personal grimoire** (`~/.grimoire/sigils/`) — default for manual GC
- **Project-local** (`grimoire/spells/checks/`) — useful mid-engagement
- **Both** — default when invoked from summon at start-of-audit

If `~/.grimoire/sigils/` is empty, note that the personal grimoire has no sigils yet (populated
through end-of-audit merges) and limit scope to project-local.

### 2. Inventory Sigils

For each sigil/check file in scope, extract from frontmatter:
- name, description, languages, severity-default, tags

Present a summary table to the user.

If no sigils are found in any directory in scope, report that the spellbook is empty — there
is nothing to garbage collect. Suggest creating detection modules via `/scribe-distill` from
confirmed findings.

### 3. Detect Overlaps

Compare sigils pairwise within the scope. Overlap indicators:
- **Same vulnerability class/type** (matching tags or similar descriptions)
- **Similar grep patterns** (both search for the same function calls or code shapes)
- **Subset relationship** (one sigil's patterns are a strict subset of another's)
- **Overlapping assessment criteria** (both assess the same conditions)

Group overlapping sigils into clusters.

### 4. Propose Resolutions

For each overlap cluster, propose one of:

- **Merge** — combine patterns and assessment into one stronger sigil. Use when both
  sigils target the same vulnerability class but catch different manifestations.
- **Deduplicate** — keep the more comprehensive sigil, archive the other. Use when one
  sigil strictly subsumes the other.
- **Keep both** — the sigils are sufficiently different despite surface similarity. Note
  the distinction clearly so future GC does not re-flag them.

Present proposals to the user. Do not proceed without confirmation.

### 5. Execute Approved Changes

For each approved resolution:

- **Merge:** Create a new combined sigil file. Archive the originals in
  `~/.grimoire/sigils/archived/` (or `grimoire/spells/checks/archived/` for project-local).
  Create archive directories with `mkdir -p` if needed.
- **Deduplicate:** Archive the weaker sigil. Leave the surviving sigil unchanged.
- **Keep both:** No file changes. Add a note to both sigils' `related-checks` field
  documenting why they coexist.

Validate all modified/created files with
`bash skills/checks/scripts/validate-check.sh <path>`.

Present a summary of changes made.
