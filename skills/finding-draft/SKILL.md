---
name: Finding Draft
description: >-
  This skill should be used when the user says "draft a finding", "write a finding",
  "create a finding", "document a vulnerability", "write up this bug", "finding template",
  "report a vulnerability", "/finding-draft", "/finding", or wants to construct a new
  structured security finding from a vulnerability observation. Findings are the core
  deliverable of security research — structured markdown files that prove a vulnerability
  exists and tell the recipient what to fix. This skill is NOT for reviewing existing
  findings (use /finding-review) or deduplicating findings (use /finding-dedup).
user_invocable: true
---

# Finding Draft

Draft structured security findings from vulnerability observations — transforming raw
research into reviewable, verifiable finding files.

## Philosophy

Findings are what security research produces. A finding is not a code review comment or a
chat message — it is a standalone document that proves a vulnerability exists and tells the
recipient exactly what to fix. Every finding must be understandable by someone who has never
seen the codebase.

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
- [ ] 1. Gather context
- [ ] 2. Construct title
- [ ] 3. Estimate severity and classify type
- [ ] 4. Draft sections
- [ ] 5. Write finding file
- [ ] 6. Suggest follow-ups
```

---

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

See `skills/finding/references/finding-best-practices.md` for detailed title guidelines with
more examples.

Present the candidate title to the user for confirmation.

### 3. Estimate Severity and Classify Type

**Severity** — propose one of: Critical, High, Medium, Low, Informational. Provide a
one-sentence justification. See `skills/finding/references/finding-format.md` for severity
scale definitions.

**Type** — classify the flaw (e.g., reentrancy, access-control, dos, integer-overflow,
logic-error, memory-corruption, injection, information-disclosure). See
`skills/finding/references/finding-format.md` for the recommended type taxonomy.

**Context** — list the affected source files with optional line numbers. These populate the
`context` frontmatter field.

Present severity, type, and context to the user for confirmation.

### 4. Draft Sections

Write each section following the templates in `skills/finding/references/finding-format.md`
and the guidelines in `skills/finding/references/finding-best-practices.md`:

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

Consult `skills/finding/examples/reentrancy-finding.md` for a complete finding with all
sections, and `skills/finding/examples/access-control-finding.md` for a minimal valid
finding.

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
  output goes in `grimoire/sigil-findings/`.
- **Unique filenames.** Kebab-case derived from title, unique within the target directory.
- **Validate before committing.** Run `skills/finding/scripts/validate-finding.sh` on every
  new finding.
- **Fact-check everything.** Never refer to a best practice, standard, or prior finding
  that does not actually exist.
