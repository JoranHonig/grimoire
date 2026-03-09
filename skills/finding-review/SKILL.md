---
name: Finding Review
description: >-
  This skill should be used when the user says "review finding", "review my finding",
  "check my finding", "fact check finding", "improve finding", "/finding-review", or
  provides a path to an existing finding file and wants it evaluated for quality. Reviews
  findings against best practices for title clarity, description completeness, recommendation
  objectivity, severity accuracy, and reference validity. This skill is NOT for drafting
  new findings (use /finding-draft) or deduplicating findings (use /finding-dedup).
user_invocable: true
---

# Finding Review

Review and harden existing security findings against best practices — checking clarity,
accuracy, fact-correctness, and guideline conformance.

## Philosophy

Even experienced researchers benefit from systematic review. This skill catches common
mistakes: titles that miss the impact, descriptions that assume reader context,
recommendations that are too prescriptive, and references that don't exist. The review is
structured and checklist-driven, not subjective.

> **You are responsible for your findings.** Agents make mistakes. Always perform thorough
> review of references, proof of concepts, and claims before submitting.

## Workflow

When this skill is activated, create a todo list from the following steps. Mark each task
in_progress before starting it and completed when done.

```
- [ ] 1. Load and validate finding
- [ ] 2. Analyze content
- [ ] 3. Present review and offer updates
```

---

### 1. Load and Validate Finding

Read the target finding file. Parse frontmatter and sections.

Run structural validation:
```bash
bash skills/finding/scripts/validate-finding.sh <path-to-finding>
```

Report any schema violations — missing frontmatter fields, missing required sections,
invalid severity values. Consult `skills/finding/references/finding-format.md` for the
complete schema specification.

### 2. Analyze Content

Evaluate the finding against each guideline in
`skills/finding/references/finding-best-practices.md`:

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

### 3. Present Review and Offer Updates

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

## Guidelines

- **Self-contained findings.** Every finding must be understandable without access to the
  codebase or other findings.
- **Severity is an estimate.** Do not overstate confidence. Justify with one sentence.
- **Recommendations for maintainers, not researchers.** State what to fix, not how to
  rewrite the code. Never suggest non-trivial implementations.
- **Out of scope is acceptable.** If the fix requires complex redesign, say so.
- **Degrade gracefully.** Familiar and librarian integrations are stubs. Note what was
  skipped, never pretend it was done.
- **Fact-check everything.** Never refer to a best practice, standard, or prior finding
  that does not actually exist.
- **Validate after changes.** Re-run `skills/finding/scripts/validate-finding.sh` after
  applying any updates.
