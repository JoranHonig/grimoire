# Finding File Format

This reference defines the format for finding files stored in `grimoire/findings/` and
`grimoire/sigil-findings/`.

## File Location

- **Manual audit findings:** `grimoire/findings/<slug>.md`
- **Automated / sigil findings:** `grimoire/sigil-findings/<slug>.md`

Filenames are kebab-case, derived from the finding title, with `.md` extension. Maximum 60
characters. Must be unique within the target directory. If a collision occurs, append a
numeric suffix (`-2`, `-3`).

## Frontmatter

Every finding file starts with YAML frontmatter:

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

| Field      | Required | Description                                                        |
|------------|----------|--------------------------------------------------------------------|
| `title`    | yes      | Concise vulnerability title following the where/how/what rule.     |
| `severity` | yes      | Severity estimate: Critical, High, Medium, Low, or Informational.  |
| `type`     | yes      | Flaw classification for search and indexing.                       |
| `context`  | yes      | YAML list of affected files, optionally with line numbers/ranges.  |

### Context Field Format

Each entry in the `context` list is a file path relative to the project root. Optionally
append a colon and line number or range:

```yaml
context:
  - src/Vault.sol                   # whole file
  - src/Vault.sol:142               # specific line
  - src/Vault.sol:142-158           # line range
  - src/routes/user.js:45-67
```

### Severity Scale

| Level           | Criteria                                                        |
|-----------------|-----------------------------------------------------------------|
| Critical        | Direct path to fund loss, RCE, or full system compromise. Minimal preconditions. |
| High            | Significant impact, exploitable with moderate effort or conditions. |
| Medium          | Real impact but requires specific conditions, chaining, or elevated privileges. |
| Low             | Minor impact or largely theoretical. Worth documenting.          |
| Informational   | Observation or best-practice deviation with no direct exploitable impact. |

Severity is always an estimate. Agents adjust based on context but should justify the
assessment in the Description section.

### Type Taxonomy

Recommended (non-exhaustive) type values:

| Type                    | Description                                              |
|-------------------------|----------------------------------------------------------|
| `reentrancy`            | State modification after external call                   |
| `access-control`        | Missing or insufficient authorization checks             |
| `dos`                   | Denial of service through resource exhaustion or revert  |
| `integer-overflow`      | Arithmetic overflow or underflow                         |
| `logic-error`           | Incorrect business logic or state machine flaw           |
| `memory-corruption`     | Buffer overflow, use-after-free, or similar              |
| `injection`             | SQL, command, XSS, or other injection vectors            |
| `information-disclosure`| Leaking sensitive data through logs, errors, or responses|
| `race-condition`        | TOCTOU, front-running, or concurrency issues             |
| `cryptographic`         | Weak randomness, broken primitives, or key management    |
| `configuration`         | Insecure defaults, missing hardening, or misconfiguration|
| `supply-chain`          | Dependency vulnerabilities or compromised packages       |

Any non-empty string is accepted. Use the taxonomy above when a standard term fits. For
novel flaw types, use a descriptive kebab-case value.

## Sections

The body follows the closing `---` of the frontmatter:

| Section              | Required | Purpose                                                 |
|----------------------|----------|---------------------------------------------------------|
| `## Description`     | yes      | Explains the vulnerability and its impact.              |
| `## Details`         | no       | Technical deep dive for complex mechanisms.             |
| `## Proof of Concept`| no       | References the PoC artifact file.                       |
| `## Recommendation`  | yes      | Concise, objective fix direction.                       |
| `## References`      | no       | Numbered citations to standards, prior art, docs.       |

### Description

2-4 paragraphs. Must be self-contained — a reader unfamiliar with the codebase should
fully understand the vulnerability from this section alone. Cover:

1. What component is affected
2. What the flaw is (mechanism)
3. What preconditions exist (privileges, timing, configuration)
4. What the impact is (what an attacker can achieve)

Include code snippets where they aid comprehension.

### Details

Optional. Include when:
- The exploit involves multiple steps
- The mechanism is non-obvious
- Code walkthrough is needed to understand the flaw

Omit when the Description already covers the mechanism adequately.

### Proof of Concept

Reference format: `@path/to/poc-file` where the path is relative to the project root.

```markdown
## Proof of Concept

@grimoire/pocs/reentrancy-vault-poc.t.sol
```

If no PoC exists yet, note this explicitly and suggest creating one with [[write-poc]].

### Recommendation

Objective fix direction. Preferred format: one or two sentences stating what to change.

**Acceptable:** "Update the contract balance state before performing the external call
(checks-effects-interactions pattern)."

**Acceptable:** "Add authentication middleware to the `/user` PUT endpoint."

**Acceptable:** "The design space for a solution to this flaw is out of scope for this
report."

**Not acceptable:** Multi-paragraph implementation with code blocks rewriting the contract.

### References

Numbered citations:

```markdown
## References

[1] SWC-107: Reentrancy — https://swcregistry.io/docs/SWC-107
[2] Checks-Effects-Interactions pattern — Solidity docs
```

All cited references must be real and verifiable. Never fabricate citations.

## Example

See `examples/reentrancy-finding.md` for a complete finding and
`examples/access-control-finding.md` for a minimal valid finding.
