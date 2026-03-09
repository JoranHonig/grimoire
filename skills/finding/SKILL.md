---
name: Finding
description: >-
  This skill should be used when the user says "draft a finding", "write a finding",
  "create a finding", "review finding", "review my finding", "deduplicate findings",
  "dedup findings", "compare findings", "document a vulnerability", "write up this bug",
  "finding template", "report a vulnerability", "/finding", "/finding-draft",
  "/finding-review", "/finding-dedup", or wants to construct, review, or deduplicate
  structured security findings. Findings are the core deliverable of security research — structured markdown
  files that prove a vulnerability exists and tell the recipient what to fix. This skill
  is NOT for general code review or ad-hoc vulnerability discussion.
user_invocable: true
---

# Finding

Draft, review, and deduplicate structured security findings — the core deliverable of
security research.

## Philosophy

Findings are what security research produces. A finding is not a code review comment or a
chat message — it is a standalone document that proves a vulnerability exists and tells the
recipient exactly what to fix. Every finding must be understandable by someone who has never
seen the codebase.

Three modes serve the finding lifecycle: **draft** creates findings from raw observations,
**review** hardens them against best practices and fact-checks claims, and **dedup** keeps
the finding set clean by identifying duplicates and overlaps. Each mode is independent — use
whichever fits your current need.

A finding should never suggest non-trivial code changes. Security researchers are external
reviewers; by suggesting complex implementations we become biased. If the fix requires
architectural redesign, say so and move on. The recommendation states *what* to fix, not
*how* to rewrite the code.

> **You are responsible for your findings.** Agents make mistakes. Always perform thorough
> review of references, proof of concepts, and claims before submitting.

## Workflow

When this skill is activated, create a todo list from the following steps. Mark each task
in_progress before starting it and completed when done.

```
- [ ] 0. Determine mode — draft, review, or dedup
- [ ] 1. (Draft) Gather context
- [ ] 2. (Draft) Construct title
- [ ] 3. (Draft) Estimate severity and classify type
- [ ] 4. (Draft) Draft sections
- [ ] 5. (Draft) Write finding file
- [ ] 6. (Draft) Suggest follow-ups
- [ ] 7. (Review) Load and validate finding
- [ ] 8. (Review) Analyze content
- [ ] 9. (Review) Present review and offer updates
- [ ] 10. (Dedup) Index and compare findings
- [ ] 11. (Dedup) Present duplicates and confirm actions
- [ ] 12. (Dedup) Execute and report
```

---

### 0. Determine Mode

Infer the mode from the user's request:

- **Draft** (steps 1-6) — user wants to create a new finding, mentions a vulnerability to
  document, or says "draft", "write", or "create" a finding
- **Review** (steps 7-9) — user provides a path to an existing finding, or says "review"
- **Dedup** (steps 10-12) — user says "dedup", "deduplicate", "compare findings", or wants
  to clean up overlapping findings

If ambiguous, ask the user which mode they need. Then skip to the relevant steps.

---

## Draft Mode

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

Build the title following the **where / how / what** rule:

- **Where** — the affected component, route, function, or contract
- **How** — the mechanism or flaw type (missing auth, reentrancy, unchecked return, etc.)
- **What** — the impact (account takeover, fund theft, DoS, etc.)

Good: `"Theft of deposited funds via reentrancy in Vault.withdraw() due to state update after external call"`

Bad: `"Missing check"`, `"Reentrancy"`, `"Incorrect implementation"`

See `references/finding-best-practices.md` for detailed title guidelines with more examples.

Present the candidate title to the user for confirmation.

### 3. Estimate Severity and Classify Type

**Severity** — propose one of: Critical, High, Medium, Low, Informational. Provide a
one-sentence justification. See `references/finding-format.md` for severity scale definitions.

**Type** — classify the flaw (e.g., reentrancy, access-control, dos, integer-overflow,
logic-error, memory-corruption, injection, information-disclosure). See
`references/finding-format.md` for the recommended type taxonomy.

**Context** — list the affected source files with optional line numbers. These populate the
`context` frontmatter field.

Present severity, type, and context to the user for confirmation.

### 4. Draft Sections

Write each section following the templates in `references/finding-format.md` and the
guidelines in `references/finding-best-practices.md`:

**## Description** (mandatory)
2-4 paragraphs. State the vulnerability, affected component, preconditions, and impact.
Written for someone unfamiliar with the codebase. Include code snippets where they help
comprehension. The description should stand alone — a reader must fully understand the
threat without reading other sections.

**## Details** (optional)
Include only when the vulnerability mechanism is non-obvious or the exploit involves
multiple steps. Technical walkthrough with code references. Omit if the Description already
covers the mechanism adequately.

**## Proof of Concept**
If a PoC file exists, insert `@path/to/poc-file` (path relative to project root). If no
PoC exists, note that one should be created with [[write-poc]] and leave a placeholder.

**## Recommendation** (mandatory)
Objective fix direction. One-sentence fixes are preferred. Never suggest non-trivial code
changes — security researchers are external reviewers. If the fix requires complex redesign,
state: *"The design space for a solution to this flaw is out of scope for this report."*

**## References** (optional)
Numbered citations: `[1] description — URL or source`. Include relevant standards, prior
findings, documentation. *(Librarian agent not yet available — note that reference discovery
was skipped. The user can add references manually.)*

Present the drafted content to the user for review before writing the file.

### 5. Write Finding File

Determine the target directory:
- `grimoire/findings/` for findings from manual audit research (default)
- `grimoire/sigil-findings/` for findings from automated tooling or sigil agents

Generate the filename: kebab-case derived from the title, `.md` extension. If the filename
already exists in the target directory, append a numeric suffix (`-2`, `-3`, etc.).

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

---

## Review Mode

### 7. Load and Validate Finding

Read the target finding file. Parse frontmatter and sections.

Run structural validation:
```bash
bash skills/finding/scripts/validate-finding.sh <path-to-finding>
```

Report any schema violations — missing frontmatter fields, missing required sections,
invalid severity values.

### 8. Analyze Content

Evaluate the finding against each guideline in `references/finding-best-practices.md`:

**Title** — does it satisfy the where/how/what rule? If not, propose an improved title.

**Description** — is it self-contained? Could a reader unfamiliar with the codebase
understand the vulnerability from this section alone? Is impact clearly stated?

**Details** — if present, does it add value beyond the description? If absent, should it
be added?

**Recommendation** — is it objective? Does it avoid non-trivial code suggestions? Is it
actionable by a project maintainer?

**Severity** — is the estimate reasonable given the described impact, exploitability,
and preconditions?

**PoC reference** — does the `@`-referenced file exist? Is it correctly formatted?

**References** — are all cited references real and relevant? Are claims fact-checked?

**Familiar agent check** — *(Not yet available. Note: "Issue validity check skipped —
familiar agent not yet implemented.")*

**Librarian agent check** — *(Not yet available. Note: "Reference discovery skipped —
librarian agent not yet implemented.")*

### 9. Present Review and Offer Updates

Present the review in structured sections:

- **Passes** — what the finding does well
- **Warnings** — non-critical issues worth addressing
- **Failures** — violations of required guidelines
- **Recommendations** — specific suggested improvements

Each item should cite the guideline it checks against.

Ask the user: *"Apply recommended changes? [y/n]"*

If yes, apply edits to the finding file. Re-run validation. Present the updated finding.

Suggest follow-ups:
- `/finding-dedup` if the project has multiple findings
- [[write-poc]] if the PoC section has a placeholder

---

## Dedup Mode

### 10. Index and Compare Findings

Run the indexing script to get the full finding set:
```bash
bash skills/finding/scripts/index-findings.sh
```

If fewer than 2 findings exist, report that there is nothing to deduplicate and stop.

For each pair of findings, compare title, type, context (affected files), and description.
Classify each pair as:

- **Duplicate** — same root cause, same affected component, same impact. One can be deleted
  without losing information.
- **Similar** — overlapping root cause or component but different scope or impact. Cannot
  delete without information loss. May benefit from cross-referencing or merging.
- **Distinct** — no meaningful overlap. No action needed.

If the finding set is large (>10 findings), group by `type` first and only compare within
groups. Use subagents for parallel comparison if needed.

### 11. Present Duplicates and Confirm Actions

Present results:
- Table of **duplicate pairs** with recommendation (which to keep, which to delete)
- Table of **similar pairs** with recommendation (merge, cross-reference, or leave as-is)
- List of **distinct findings** — no action needed

For each duplicate pair: *"Delete `<file>`? [y/n]"*
For each similar pair: *"Merge into `<file>`? [y/n/skip]"*

Never delete or merge without explicit user confirmation.

### 12. Execute and Report

Perform confirmed deletions and merges. When merging:
- Keep the more complete finding as the base
- Incorporate unique content from the other finding
- Present the merged result for user approval before deleting the source

Re-run the index to show the updated finding set:
```bash
bash skills/finding/scripts/index-findings.sh
```

Suggest `/finding-review` on any merged findings to verify quality.

---

## Guidelines

- **Self-contained findings.** Every finding must be understandable without access to the
  codebase or other findings.
- **Severity is an estimate.** Do not overstate confidence. Justify with one sentence.
- **Recommendations for maintainers, not researchers.** State what to fix, not how to
  rewrite the code. Never suggest non-trivial implementations.
- **Out of scope is acceptable.** If the fix requires complex redesign, say so.
- **Use `@path` for PoC references.** Never inline large code blocks in findings. Reference
  the PoC file instead.
- **Degrade gracefully.** Familiar and librarian integrations are stubs. Note what was
  skipped, never pretend it was done.
- **Audit vs sigil findings.** Manual research goes in `grimoire/findings/`. Automated tool
  output goes in `grimoire/sigil-findings/`. Sigil findings often need human refinement via
  review mode.
- **Unique filenames.** Kebab-case derived from title, unique within the target directory.
- **Validate before committing.** Run `scripts/validate-finding.sh` on every new or modified
  finding.
- **Fact-check everything.** Never refer to a best practice, standard, or prior finding
  that does not actually exist.
