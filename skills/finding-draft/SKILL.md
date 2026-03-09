---
name: Finding Draft
description: >-
  This skill should be used when the user says "draft a finding", "write a finding",
  "create a finding", "document a vulnerability", "write up this bug", "finding template",
  "report a vulnerability", "/finding-draft", or wants to construct a new structured
  security finding from a vulnerability observation. This skill is NOT for reviewing
  existing findings (use /finding-review) or deduplicating findings (use /finding-dedup).
user_invocable: true
---

# Finding Draft

Draft structured security findings from vulnerability observations.

## Prerequisites

Before starting, read `skills/finding/SKILL.md` to understand finding structure, best
practices, and conventions. That skill defines the format, frontmatter schema, severity
scale, and key principles that this workflow applies.

## Workflow

When this skill is activated, create a todo list from the following steps. Mark each task
in_progress before starting it and completed when done.

```
- [ ] 0. Load finding knowledge (read skills/finding/SKILL.md)
- [ ] 1. Gather context
- [ ] 2. Construct title
- [ ] 3. Estimate severity and classify type
- [ ] 4. Draft sections
- [ ] 5. Write finding file
- [ ] 6. Suggest follow-ups
```

---

### 0. Load Finding Knowledge

Read `skills/finding/SKILL.md` to internalize finding structure, best practices, and
conventions. This is required before proceeding — the base skill defines the format you
will produce.

### 1. Gather Context

Verify the workspace:
- Check for `GRIMOIRE.md` in the project root. If absent, suggest running [[summon]] first.
- Check whether `grimoire/findings/` exists. Create it if not.

Gather vulnerability context:
- If triage context exists from the familiar agent, use it. *(Familiar agent not yet
  available — skip this and note it was skipped.)*
- Otherwise, ask the user to describe: **what component** is affected, **what goes wrong**,
  and **what the impact is**.
- Search for existing PoC artifacts that relate to this vulnerability. If found, note the
  path for later `@reference`.

Check in with the user before continuing.

### 2. Construct Title

Build the title following the **where / how / what** rule from the finding skill.

Present the candidate title to the user for confirmation.

### 3. Estimate Severity and Classify Type

**Severity** — propose one of: Critical, High, Medium, Low, Informational. Provide a
one-sentence justification. Use the severity scale from the finding skill.

**Type** — classify the flaw. Consult `skills/finding/references/finding-format.md` for the
recommended type taxonomy.

**Context** — list the affected source files with optional line numbers for the `context`
frontmatter field.

Present severity, type, and context to the user for confirmation.

### 4. Draft Sections

Write each section following the format from the finding skill and the detailed guidelines
in `skills/finding/references/finding-best-practices.md`:

**## Description** (mandatory) — 2-4 self-contained paragraphs covering component, flaw,
preconditions, and impact.

**## Details** (optional) — only when the mechanism is non-obvious or multi-step.

**## Proof of Concept** — `@path/to/poc-file` if one exists, placeholder otherwise.

**## Recommendation** (mandatory) — objective fix direction. Never non-trivial code changes.

**## References** (optional) — numbered citations. *(Librarian agent not yet available.)*

Consult `skills/finding/examples/reentrancy-finding.md` for a complete finding and
`skills/finding/examples/access-control-finding.md` for a minimal valid finding.

Present the drafted content to the user for review before writing the file.

### 5. Write Finding File

Determine the target directory:
- `grimoire/findings/` for manual audit research (default)
- `grimoire/sigil-findings/` for automated tooling or sigil agents

Generate the filename per the filing conventions in the finding skill.

Write the complete finding file with frontmatter and all sections.

Validate by running:
```bash
bash skills/finding/scripts/validate-finding.sh <path-to-finding>
```

If validation fails, fix the issues and re-validate.

### 6. Suggest Follow-ups

Based on the finding:
- If no PoC exists: suggest [[write-poc]]
- If related findings may exist: suggest `/finding-dedup`
- If cartography is missing for affected flows: suggest [[cartography]]
- If the pattern could be generalized into a check: suggest [[checks]]
