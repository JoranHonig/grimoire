---
name: scribe-distill
description: >-
  This skill should be used when the user says "distill this finding", "create
  a detection module", "encode this finding", "make a sigil from this",
  "automate detection for this", "build a sigil from this", "scribe distill",
  "/scribe-distill", or when
  a confirmed finding should be transformed into a reusable automated detection
  module. Analyzes a finding's vulnerability pattern, assesses automation
  feasibility, and creates a detection module (sigil) in the project spellbook.
user_invocable: true
---

# Scribe Distill

Transform confirmed findings into reusable automated detection modules.

## Philosophy

Every confirmed finding is a potential lesson for future audits. The Scribe's distill
workflow determines whether that lesson can be encoded as automated detection and, if so,
builds the detection module. Static analysis is always preferred — it is deterministic,
fast, and cheap. Agentic checks are a fallback for patterns that require reasoning. Some
findings simply cannot be automated; for those, encode the knowledge as a reference artifact
rather than letting it be forgotten.

A low false-positive rate is more important than coverage. A detection module that fires on
every audit but produces false positives is worse than one that misses edge cases but is
always right when it fires.

## Workflow

When this skill is activated, create a todo list from the following steps. Mark each task
in_progress before starting it and completed when done.

```
- [ ] 1. Load finding and context
- [ ] 2. Check for existing coverage
- [ ] 3. Extract generalizable pattern
- [ ] 4. Assess automation feasibility
- [ ] 5. Determine sigil type
- [ ] 6. Create detection module
- [ ] 7. Validate detection module
- [ ] 8. Assess variant analysis potential
- [ ] 9. Present results and suggest follow-ups
```

---

### 1. Load Finding and Context

Read the finding file. Extract:
- Title, severity, type
- Affected code locations (from `context` frontmatter field)
- Root cause (from Description and Details sections)
- Impact (from Description)

Read `GRIMOIRE.md` for codebase context — architecture, crown jewels, technology stack.

Check in with the user before continuing.

### 2. Check for Existing Coverage

Run `bash skills/checks/scripts/index-checks.sh grimoire/spells/checks/` to list existing
checks. Read any that might cover the same vulnerability class.

If a check already covers this exact pattern:
- Report the overlap to the user
- Stop unless the user wants a more specific variant or the existing check is too broad

If partial overlap exists, note which aspects are already covered so the new module can
focus on the gap.

If the directory does not exist, no existing checks exist — skip to step 3.

### 3. Extract Generalizable Pattern

Strip instance-specific details from the finding:
- Remove specific contract/class/function names unique to this codebase
- Remove hardcoded values, addresses, or identifiers
- Preserve the structural code shape and the invariant violation

Express the pattern as: "Code that does X without Y, in the context of Z."

Example: A reentrancy finding in `Vault.withdraw()` becomes "Functions that make external
calls before updating state in contracts holding user funds."

Check in with the user to confirm the generalized pattern captures the essence of the
vulnerability.

### 4. Assess Automation Feasibility

Consult `references/feasibility-criteria.md` for detailed guidance. Classify the pattern:

**Static-feasible** — The pattern is identifiable by searching for specific strings, function
calls, code shapes, or AST patterns. Proceed to check creation.

**Agentic-feasible** — The pattern is identifiable by grep but requires reading surrounding
context to assess whether a match is a real issue. Create a check with assessment criteria
that guide the applying agent.

**Not automatable** — The pattern requires deep business logic understanding, external state
knowledge, or full-codebase reasoning that cannot be reduced to a check. Create a knowledge
artifact instead.

Present the feasibility assessment to the user.

### 5. Determine Sigil Type

Consult `references/sigil-types.md` for the type taxonomy and decision flowchart.

For now, the only implementable types are:
- **Check** — a markdown file in checks format, applied by spawning a subagent
- **Knowledge artifact** — a reference doc for patterns that cannot be automated

If the pattern would be better served by semgrep, slither, or codeql, note this as a
future improvement but create a check as a fallback.

### 6. Create Detection Module

**For checks (static-feasible and agentic-feasible):**

Follow the check format from `skills/checks/references/check-format.md`:
- YAML frontmatter: name, description, languages, severity-default, confidence, tools, tags
- Body: Patterns section (grep-able search patterns), Assessment section (how to evaluate
  matches, severity adjustment, benign cases)

Create the file in `grimoire/spells/checks/` with a slugified filename. Consult
`skills/checks/examples/` for worked examples at different complexity levels.

**Gnome delegation:** Spawn a Gnome agent to build the check. Provide it with the
generalized pattern, target language(s), severity/confidence guidance, and assessment
criteria. The Gnome handles file creation, format compliance, and validation.

**For knowledge artifacts (not automatable):**

Create a markdown file in `grimoire/spells/knowledge/` (create directory with `mkdir -p` if
needed) with:
- YAML frontmatter: name, description, vulnerability-class, languages
- Body: what to look for (natural language), why it matters, known-bad patterns, assessment
  guidance

### 7. Validate Detection Module

For checks, run:
```bash
bash skills/checks/scripts/validate-check.sh <path-to-check>
```

If validation fails, fix the issues and re-validate.

For knowledge artifacts, verify: frontmatter is well-formed, description is clear and
actionable, the document is self-contained.

Check in with the user.

### 8. Assess Variant Analysis Potential

Consider whether the pattern is likely to recur elsewhere in the current codebase:
- How common is the code shape? (many similar components → high variant potential)
- Is this a systemic issue or a one-off mistake?
- How many files/contracts follow a similar structure?

If variant analysis is warranted, suggest spawning a variant sigil with the generalized
pattern from step 3.

### 9. Present Results and Suggest Follow-ups

Summarize what was created using the Scribe distill output format from
`agents/scribe.md`.

Suggest follow-ups:
- **Variant sigil** — if variant analysis is warranted (from step 8)
- **End-of-audit merge** — when wrapping up, promote generalizable sigils to the personal
  grimoire via scribe Mode 2a
- **Additional checks** — if the pattern has sub-variants not covered by this module
- **Sigil application** — run the new check immediately against the codebase via the
  checks skill (Mode 2: Apply)
