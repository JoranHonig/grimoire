# Sigil Types

Taxonomy of detection modules the Scribe can create, and guidance for selecting the right
type.

## Available Now

### Check

A markdown file in the checks skill format. Contains grep-able search patterns and
assessment criteria for an applying pass to follow.

- **Format:** YAML frontmatter + Patterns section + Assessment section
- **Location:** `grimoire/spells/checks/<slug>.md`
- **Applied by:** Running a helper pass per check via the checks skill (Mode 2)
- **Best for:** Patterns identifiable by grep that need context assessment, patterns where
  the applying pass can follow explicit criteria to determine true vs false positives
- **Reference:** `skills/checks/references/check-format.md`

### Knowledge Artifact

A reference markdown document encoding researcher knowledge for patterns that cannot be
automated. Not a detection module — a reminder to investigate.

- **Format:** YAML frontmatter (name, description, vulnerability-class, languages) + body
  describing what to look for, why it matters, known-bad patterns, assessment guidance
- **Location:** `grimoire/spells/knowledge/<slug>.md`
- **Surfaced by:** Scribe utilities (Mode 3) and during summon as manual review suggestions
- **Best for:** Business-logic-dependent patterns, design-level flaws, patterns requiring
  full-codebase reasoning

## Planned (not yet implementable)

### Semgrep Rule

A YAML rule for the Semgrep static analysis engine. AST-level pattern matching —
deterministic, fast, zero false positives for well-written rules.

- **Best for:** Syntactic patterns with clear bad/good code shapes
- **Depends on:** semgrep skill (not yet implemented)
- **Fallback:** Create a check with the grep patterns that a semgrep rule would formalize

### Slither Detector

A Python detector for the Slither static analysis framework (Solidity-specific). Control
flow, data flow, and inheritance analysis.

- **Best for:** Solidity-specific patterns involving state variable access ordering,
  inheritance resolution, or cross-contract interactions
- **Depends on:** slither skill (not yet implemented)
- **Fallback:** Create a check targeting Solidity-specific code shapes

### CodeQL Query

A QL query for the CodeQL analysis engine. Inter-procedural data flow and taint tracking.

- **Best for:** Complex data flow patterns across function boundaries, taint propagation
  from source to sink
- **Depends on:** codeql skill (not yet implemented)
- **Fallback:** Create a check with multi-file assessment criteria

## Decision Flowchart

```
Is the pattern syntactically matchable (specific strings/calls)?
├── Yes → Is most of the target language Solidity?
│   ├── Yes → Slither detector (planned). Fallback: check.
│   └── No → Semgrep rule (planned). Fallback: check.
└── No → Does it require reading context to assess matches?
    ├── Yes → Can matches be found by grep first?
    │   ├── Yes → Check (agentic, with assessment criteria).
    │   └── No → Does it require inter-procedural data flow?
    │       ├── Yes → CodeQL query (planned). Fallback: check.
    │       └── No → Knowledge artifact.
    └── No → Knowledge artifact.
```

When a planned type is the ideal choice but not yet available, create a check as a fallback
and note the ideal type in the check's body. When the corresponding skill becomes available,
these checks are candidates for upgrade.
