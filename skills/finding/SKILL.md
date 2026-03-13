---
name: finding
description: >-
  This skill should be used when the user asks about findings, finding structure,
  finding format, finding best practices, "how should a finding look", "what goes in a
  finding", "/finding", or wants to understand how security findings are structured and
  written. Teaches the format, best practices, and conventions for security findings.
  For specific workflows use /finding-draft, /finding-review, or /finding-dedup.
user_invocable: true
---

# Finding

Security findings are the core deliverable of security research — structured markdown files
that prove a vulnerability exists and tell the recipient what to fix.

## Philosophy

A finding is not a code review comment or a chat message. It is a standalone document that
must be understandable by someone who has never seen the codebase. Every finding must be
self-contained, fact-checked, and verifiable.

A finding should never suggest non-trivial code changes. Security researchers are external,
unbiased reviewers. By suggesting complex implementations we become biased. If the fix
requires architectural redesign, say so and move on. The recommendation states *what* to
fix, not *how* to rewrite the code.

> **You are responsible for your findings.** Agents make mistakes. Always perform thorough
> review of references, proof of concepts, and claims before submitting.

## Finding Structure

Every finding is a markdown file with YAML frontmatter:

```yaml
---
title: Theft of deposited funds via reentrancy in Vault.withdraw()
severity: High
type: reentrancy
context:
  - src/Vault.sol:142-158
  - src/interfaces/IVault.sol:23
---
```

| Field      | Required | Description                                                    |
|------------|----------|----------------------------------------------------------------|
| `title`    | yes      | Concise title following the where/how/what rule                |
| `severity` | yes      | Critical, High, Medium, Low, or Informational                  |
| `type`     | yes      | Flaw classification (reentrancy, access-control, dos, etc.)    |
| `context`  | yes      | YAML list of affected files with optional line numbers/ranges  |

### Sections

| Section              | Required | Purpose                                             |
|----------------------|----------|-----------------------------------------------------|
| `## Description`     | yes      | Explains the vulnerability and its impact            |
| `## Details`         | no       | Technical deep dive for complex mechanisms           |
| `## Proof of Concept`| no       | References the PoC artifact via `@path/to/poc`       |
| `## Recommendation`  | yes      | Concise, objective fix direction                     |
| `## References`      | no       | Numbered citations to standards, prior art, docs     |

For complete format specification see `references/finding-format.md`.

## Title Best Practices

The title must convey **where** (component), **how** (mechanism), and **what** (impact):

**Good:** `"Theft of deposited funds via reentrancy in Vault.withdraw() due to state update after external call"`

**Bad:** `"Missing check"`, `"Reentrancy"`, `"Incorrect implementation"`

For detailed guidelines with more examples see `references/finding-best-practices.md`.

## Recommendation Best Practices

- **Objective voice.** State what needs to change, not how you would rewrite the code.
- **One-sentence fixes preferred.** If you can express the fix in one sentence, do so.
- **Never suggest non-trivial code changes.** Acceptable: add a check, use a different
  function, add comments, reorder operations. Not acceptable: full reimplementations.
- **Out of scope escape hatch.** If no simple fix exists: *"The design space for a
  solution to this flaw is out of scope for this report."*

## Filing Conventions

- **Manual audit findings:** `grimoire/findings/<slug>.md`
- **Automated / sigil findings:** `grimoire/sigil-findings/<slug>.md`
- **Filenames:** kebab-case from title, `.md` extension, max 60 characters
- **Collision handling:** append numeric suffix (`-2`, `-3`)

For directory layout details see `references/finding-structure.md`.

## Severity Scale

| Level         | Criteria                                                            |
|---------------|---------------------------------------------------------------------|
| Critical      | Direct path to fund loss, RCE, or full compromise. Minimal preconditions. |
| High          | Significant impact, exploitable with moderate effort or conditions.  |
| Medium        | Real but conditional impact. Requires chaining or elevated privileges.|
| Low           | Minor or theoretical impact. Worth documenting for defense in depth.  |
| Informational | Best-practice deviation with no direct exploitable impact.           |

Severity is always an estimate, not a formal CVSS score. Justify with one sentence.

## Key Principles

- **Self-contained.** A reader must fully understand the issue from the finding alone.
- **Fact-checked.** Never refer to a best practice, standard, or prior finding that does
  not exist. All cited references must be real and verifiable.
- **Benign payloads only.** PoCs use `alert(1)`, `sleep()`, `id` — never destructive.
- **Parameterized targets.** Localhost and variables, never hardcoded production URLs.
- **Use `@path` for PoC references.** Never inline large code blocks. Reference the file.
- **Validate.** Run `scripts/validate-finding.sh` on every new or modified finding.

## Examples

- `examples/reentrancy-finding.md` — complete finding with all sections (smart contract)
- `examples/access-control-finding.md` — minimal valid finding (web app, no Details section)
- `examples/dedup-scenario.md` — duplicate vs similar classification walkthrough

## Workflows

Use the specific workflow skills for finding operations:
- `/finding-draft` — create a new finding from a vulnerability observation
- `/finding-review` — review an existing finding against best practices
- `/finding-dedup` — identify and resolve duplicate or overlapping findings
