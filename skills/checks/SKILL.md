---
name: checks
description: >-
  This skill should be used when the user says "create a check", "write a check",
  "add a check", "apply checks", "run checks", "/checks", "vulnerability pattern",
  "detection check", "check for common bugs", "scan with checks", or wants to create,
  apply, or manage simple vulnerability pattern files that agents use to find flaws.
  Checks are the simplest unit of agentic vulnerability detection — markdown files
  describing what to look for and how to assess matches. This skill is NOT for
  general code review or ad-hoc vulnerability analysis.
---

# Checks

Create, apply, and manage vulnerability pattern checks — simple markdown files that describe
what to look for in a codebase and how to assess matches.

## Philosophy

**Many simple checks beat one complex check.** Checks are starting points based on common
mistakes and best practices, not comprehensive analyses. Each check hunts one pattern. Agent
attention is the scarcest resource — keep checks focused and short. When reasoning gets complex,
split into multiple checks. Consult `references/design-principles.md` for the full rationale.

## Workflow

When this skill is activated, create a todo list from the following steps. Mark each task
in_progress before starting it and completed when done.

```
- [ ] 1. Determine intent — create new check, apply existing checks, or manage collection
- [ ] 2. (Create) Identify the vulnerability pattern
- [ ] 3. (Create) Write the check file
- [ ] 4. (Create) Validate the check
- [ ] 5. (Apply) Select applicable checks
- [ ] 6. (Apply) Run checks against the codebase
- [ ] 7. Collect and present results
- [ ] 8. Suggest follow-ups
```

---

### 1. Determine Intent

Ask the user (or infer from context) which mode they need:

- **Create** (steps 2-4) — write a new check from a finding, domain knowledge, or research
- **Apply** (steps 5-7) — run existing checks against a codebase
- **Manage** — index the collection, validate files, reorganize. Use the scripts directly:
  - `bash skills/checks/scripts/index-checks.sh grimoire/spells/checks/` to list all checks
  - `bash skills/checks/scripts/validate-check.sh <file>` to validate a specific check

If unclear, ask the user. Then skip to the relevant step.

### 2. Identify the Vulnerability Pattern

Three sources for new checks:

**From a confirmed finding.** The user or an agent found a specific bug. Generalize the pattern:
what was the observable code pattern? What conditions made it exploitable? What would a grep
for similar instances look like?

**From domain knowledge.** The user knows a class of bugs to look for (e.g., "check for ERC-4626
vault issues"). Extract the specific patterns and assessment criteria.

**From external research.** Use the librarian agent to gather context on a
vulnerability class, then distill into grep-able patterns and assessment rules.

For any source, extract:
1. The observable code pattern (what to search for)
2. The conditions that make a match problematic vs benign
3. A reasonable default severity and confidence level

Consult `references/design-principles.md` to decide whether the pattern should be one check or
multiple. If the pattern involves multiple independent sub-patterns or the assessment requires
deep reasoning, split now rather than after writing.

Check in with the user before continuing.

### 3. Write the Check File

Create a file at `grimoire/spells/checks/<slug>.md` where `<slug>` is a lowercase, hyphenated
version of the check name.

Follow the format in `references/check-format.md`. The file has:

1. **Frontmatter** — `name`, `description`, `languages`, `severity-default`, `confidence`,
   `tools`. Optionally `tags`, `related-checks`, `attribution-name`, and `attribution-url`.
   Add `attribution-name` and `attribution-url` when the check is inspired by external
   research, a known registry (e.g., SWC), an audit report, or another person's work.
2. **Pattern section** — what to search for. Keep patterns grep-able where possible.
3. **Assessment section** — how to evaluate matches. Categories, severity adjustments, benign
   cases to dismiss.

Keep the body under ~30 lines. If it grows longer, split into multiple checks.

Consult `examples/` for worked examples at different complexity levels:
- `examples/debug-assertions.md` — simplest possible check (one pattern family)
- `examples/rounding-direction.md` — scanning check (identify pattern, defer assessment)
- `examples/rounding-inflation-attack.md` — assessment check (deep reasoning on known pattern)
- `examples/erc4626-vault.md` — checklist-style check (multiple items for one standard)
- `examples/unchecked-return-values.md` — cross-language check

If `grimoire/spells/checks/` does not exist, create it. This directory is part of the spellbook
structure created by [[summon]].

### 4. Validate the Check

Run the validation script:

```bash
bash skills/checks/scripts/validate-check.sh grimoire/spells/checks/<slug>.md
```

This verifies:
- All required frontmatter fields are present and non-empty
- Body content exists after the frontmatter
- Body length is within the recommended limit (warns if >30 lines)

Review the check against the simplicity principle: is this one pattern? Is the assessment
clear? Could an agent apply this in a single focused pass?

Check in with the user before continuing.

### 5. Select Applicable Checks

Run the indexing script to see available checks:

```bash
bash skills/checks/scripts/index-checks.sh grimoire/spells/checks/
```

This outputs a tab-separated list: name, description, languages, severity, confidence, filepath.

Filter by:
- **Language** — match the `languages` field against the target codebase
- **Tags** — if the user has a specific focus (e.g., "defi", "crypto", "error-handling")
- **User selection** — present the filtered list and let the user choose which to apply, or
  apply all matching checks

### 6. Run Checks Against the Codebase

For each selected check, spawn a subagent with:

1. The check file content as its instructions
2. The target codebase path
3. Only the tools listed in the check's `tools` field

Each subagent operates independently with minimal context — just the check and the code. This
isolation is critical for attention management. Do not bundle multiple checks into one agent.

Subagents report back for each match:
- File path and line number
- Which pattern matched
- Assessed severity (adjusted from default based on context)
- Confidence assessment
- Brief description of why this is or isn't a finding

Run subagents in parallel where possible.

### 7. Collect and Present Results

Aggregate results from all subagents. Present findings grouped by severity:

1. **Critical / High** — show first, with full context
2. **Medium** — show with summary
3. **Low / Informational** — list briefly

For each finding, include:
- Check name and file path
- Match location (file:line)
- Assessed severity and confidence
- Brief description

After presenting findings, suggest invoking the familiar agent to triage them. The familiar
independently verifies each finding and filters false positives before the user acts on them.

### 8. Suggest Follow-ups

Based on results, suggest:

- **[[write-poc]]** — for confirmed high-severity findings that need proof-of-concept
- **[[cartography]]** — for flows that surfaced during checking and are worth documenting
- **Create more checks** — if patterns suggest related issues not covered by existing checks
- **Scribe distill** — invoke `/scribe-distill` to encode validated patterns into detection
  modules for future audits

---

## Guidelines

- **One pattern per check file.** If a check covers multiple unrelated patterns, split it.
- **Subagents for application.** Never apply checks in the main context. Each check gets its
  own subagent with isolated context.
- **Checks are pointers, not analyses.** They describe where to look and how to assess, not
  what the vulnerability is in depth. Use the librarian agent for background.
- **When in doubt, split.** Two simple checks always beat one complex check.
- **Checks live in `grimoire/spells/checks/`.** This is part of the spellbook directory
  created by [[summon]].
- **Validate before committing.** Run the validation script on every new check.
