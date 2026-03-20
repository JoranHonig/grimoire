# Check File Format

This reference defines the format for check files stored in `grimoire/spells/checks/`.

## File Location

All check files live in `grimoire/spells/checks/` with a slugified filename derived from the
check name: `grimoire/spells/checks/debug-assertions.md`.

## Frontmatter

Every check file starts with YAML frontmatter:

```yaml
---
name: debug assertions
description: Flags security critical debug assertions which should be regular assertions.
languages: rust
severity-default: low
confidence: medium
tools: [Grep, Read]
tags: [assertions, invariants]
related-checks: [unchecked-panic-paths]
attribution-name: Rust Security Advisory
attribution-url: https://example.com/advisory/123
---
```

| Field             | Required | Description                                                        |
|-------------------|----------|--------------------------------------------------------------------|
| `name`            | yes      | Short check name. Used in the index and for display.               |
| `description`     | yes      | One-line description of what the check detects.                    |
| `languages`       | yes      | Target language(s). Single value or YAML list.                     |
| `severity-default`| yes      | Default severity: `critical`, `high`, `medium`, `low`, `informational`. |
| `confidence`      | yes      | Expected confidence the finding is valid: `high`, `medium`, `low`. |
| `tools`           | yes      | YAML list of tools the check needs (e.g., `Grep`, `Read`, `Bash`).|
| `tags`            | no       | Freeform categorization tags for filtering.                        |
| `related-checks`  | no       | List of related check slugs (without `.md`).                       |
| `attribution-name`| no       | Name of the person, org, or resource that inspired the check.      |
| `attribution-url` | no       | URL to the source material (must start with `http://` or `https://`).|

**Constraint:** `name` and `description` must each be a single line. The indexing script relies
on this for parsing.

### Severity Levels

| Level           | Meaning                                                     |
|-----------------|-------------------------------------------------------------|
| `critical`      | Direct path to funds loss, RCE, or full system compromise   |
| `high`          | Significant impact, exploitable with moderate effort         |
| `medium`        | Real impact but requires specific conditions or chaining     |
| `low`           | Minor impact or theoretical, worth documenting               |
| `informational` | Observation, best-practice deviation, no direct impact       |

Agents adjust `severity-default` based on context. The default is a starting point, not final.

### Confidence Levels

| Level    | Meaning                                                          |
|----------|------------------------------------------------------------------|
| `high`   | Pattern match is almost always a real issue (e.g., hardcoded key)|
| `medium` | Pattern match needs context assessment to confirm                |
| `low`    | Pattern is a starting point; many matches will be benign         |

### Tools

The `tools` field declares what the applying agent needs. Common values:

- `Grep` — search for patterns in code
- `Read` — read files to assess context around matches
- `Bash` — run shell commands (e.g., for tool-specific queries)

Agents should restrict themselves to the declared tools when applying the check. This keeps
context focused and prevents scope creep during application.

## Body Structure

The body follows the closing `---` of the frontmatter. It contains two logical sections:

### Patterns

What to look for. Should contain:

- **Concrete search patterns** — literal strings, function names, import statements that can be
  grepped for directly
- **Structural patterns** — code shapes that require reading and understanding context
  (e.g., "a function that takes user input and passes it to an eval-like sink")

Keep patterns grep-able where possible. The agent uses the tools in the `tools` field.

### Assessment

How to evaluate matches:

- **Categories** — classify matches into types (e.g., "asserting invariant" vs "validating input")
- **Severity adjustment** — when and how to change severity from the default
- **Benign cases** — what makes a match NOT a finding, so the agent can dismiss quickly

### Body Constraints

- **Maximum ~30 lines.** If longer, the check should be split. See
  `references/design-principles.md` for splitting criteria.
- **No extensive background.** Don't explain the vulnerability class in depth. The agent can use
  the Librarian for additional context if needed.
- **No code snippets** unless they are the exact pattern to search for.
- **Imperative voice.** "Look for...", "Check whether...", "If X, adjust severity to..."
- **Self-contained.** Each check must be understandable without reading other checks, even if
  `related-checks` are listed.

## Example

See `examples/debug-assertions.md` for a minimal check, and `examples/rounding-direction.md` +
`examples/rounding-inflation-attack.md` for a split check pair.
