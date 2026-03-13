# Implementation Plan

Generated: 2026-03-13

## Priority Queue

Items with remaining work, sorted by priority (highest first).

### — Skills & Agents -
### 3. skill:semgrep
- **Status:** not_implemented
- **Spec detail:** partial
- **Spec:** `grimoire/skills/sigils/semgrep.md`
- **Dependencies:** None
- **Why #3:** Primary backpressure enforcement tool. Unblocks agent:sigil Mode 3 (super-sigil) — semgrep runners spawning validation sigils. Gnome agent already has a "build semgrep rule" mode providing a clear integration point.
- **Tasks:**
  1. Create `skills/semgrep/` directory with SKILL.md
  2. Build references covering rule anatomy, testing, and rule merging guidance
  3. Create worked examples of semgrep rules for common vuln patterns
  4. Wire into gnome Mode 2 (build semgrep rule) as the primary skill reference
  - *Cross-cutting:* Add backpressure guidance — when a check makes a completeness claim, suggest creating a semgrep rule for enforcement

### 4. skill:slither
- **Status:** not_implemented
- **Spec detail:** partial
- **Spec:** `grimoire/skills/sigils/slither.md`
- **Dependencies:** None
- **Tasks:**
  1. Create `skills/slither/` directory with SKILL.md
  2. Build references covering detector anatomy, documentation requirements, napalm integration
  3. Create worked examples
  4. Wire into gnome Mode 3 (build slither detector) as the primary skill reference

### 5. agent:sigil-super (Mode 3)
- **Status:** not_implemented
- **Spec detail:** sketch
- **Spec:** `grimoire/agents/sigil.md` ("Super Sigils" section)
- **Dependencies:** skill:semgrep (#3), skill:slither (#4)
- **Tasks:**
  1. Implement super-sigil pattern: tool runner that runs semgrep/slither once, then spawns individual validation sigils per finding

### 6. skill:summon — terminology reconciliation
- **Status:** implemented (terminology drift)
- **Spec detail:** detailed
- **Spec:** `grimoire/skills/summon.md`
- **Dependencies:** None
- **Tasks:**
  1. Resolve `sigils/` vs `spells/` terminology drift between spec and implementation directory structure
  2. Make `select-checks.sh` gracefully handle missing `index-checks.sh` dependency (currently fails if checks skill absent)
  3. Add `tomes/` to the spec's directory structure if it is intended to be canonical
  4. Consider auto-including personal grimoire sigils in the swarm (currently only suggests scribe-gc)

### 7. infra:personal-grimoire — full structure
- **Status:** partial (referenced via mkdir -p, no initialization)
- **Spec detail:** sketch
- **Spec:** `grimoire/concepts/personal grimoire.md`, `grimoire/agents/scribe.md`
- **Dependencies:** agent:scribe (done)
- **Tasks:**
  1. Define full `~/.grimoire/` directory structure: `sigils/`, `knowledge/`, `sigils/archived/`
  2. Create initialization workflow (currently relies on scattered `mkdir -p` across skills)
  3. Implement end-of-audit merge as a concrete workflow step in scribe-distill or standalone skill

### 8. infra:spellbook — terminology reconciliation
- **Status:** partial (conceptual alias for personal grimoire)
- **Spec detail:** partial
- **Spec:** `grimoire/agents/scribe.md`
- **Dependencies:** agent:scribe (done)
- **Tasks:**
  1. Clarify terminology: is "spellbook" the umbrella concept (project-local + personal grimoire) or specifically the personal grimoire?
  2. Add user-facing explanation of spellbook concept to a shared reference

### 9. infra:tomes — content lifecycle
- **Status:** partial (directory created by summon, no management skill)
- **Spec detail:** sketch
- **Spec:** `grimoire/skills/summon.md`, `grimoire/ideas/todo.md`
- **Dependencies:** None
- **Tasks:**
  1. Define tomes format (frontmatter, content structure)
  2. Create tomes management guidance (when to create, fact-checking before adding)
  3. Add "when to create a tome" guidance to summon and cartography
  4. Consider librarian integration for surfacing relevant tomes

### — Flows —

### 10. flow:finding-discovery — wire scribe→variant loop
- **Status:** partially_adopted
- **Spec detail:** partial
- **Spec:** `grimoire/flows/finding discovery.md`
- **Dependencies:** agent:scribe (done), skill:scribe-distill (done), agent:sigil (done)
- **Tasks:**
  1. Update finding-draft step 6 to more strongly recommend the scribe-distill → checks → sigil pipeline
  2. Wire scribe-distill output to variant sigil spawn prompt (steps 8-9)
  3. Add explicit "run new check against codebase immediately" step to scribe-distill
  4. Consider post-finding hook that prompts researcher to distill the pattern

### 11. flow:autonomous-discovery — standalone sigil invocation
- **Status:** partially_adopted (wired in summon step 9, but no mid-engagement access)
- **Spec detail:** partial
- **Spec:** `grimoire/flows/autonomous discovery.md`
- **Dependencies:** agent:sigil (done), agent:familiar (done), agent:gnome (done)
- **Tasks:**
  1. Implement a standalone sigil-invocation skill for mid-engagement use (e.g., "run sigils on this directory")
  2. Wire familiar → variant sigil spawn after confirming a finding
  3. Document full autonomous-discovery cycle as a reference

### — Concepts —

### 12. concept:context-building — gadgets implementation
- **Status:** not_implemented (gadgets concept completely absent)
- **Spec detail:** partial
- **Spec:** `grimoire/concepts/context building.md`
- **Dependencies:** None for concept; gadgets integration depends on write-poc, sigil
- **Tasks:**
  1. Document gadget concept and catalog structure (format, frontmatter, indexing)
  2. Add gadget awareness to write-poc phase 2 (check for applicable gadgets during exploit flow construction)
  3. Add gadget surfacing to sigil output format ("interesting gadget patterns discovered")
  4. Add gadget collection section to GRIMOIRE.md template in summon
  5. Extend scribe-distill to produce gadget entries alongside checks and knowledge artifacts
  6. Consider gadget storage location: `grimoire/tomes/gadgets/` or `~/.grimoire/gadgets/`

### 13. concept:backpressure — enforcement guidance
- **Status:** adopted (sigil agent uses it as core principle), partial (enforcement tooling)
- **Spec detail:** detailed
- **Spec:** `grimoire/concepts/backpressure.md`
- **Dependencies:** skill:semgrep (#3), skill:slither (#4) for full enforcement
- **Tasks:**
  1. Create shared reference doc `backpressure-methods.md` listing when to use semgrep/codeql/slither vs agentic checks
  2. Add to checks design-principles: warning that grep results are not exhaustive; suggest static analysis rule when making completeness claims
  3. Add to summon: explicit backpressure check before recommending autonomous findings

### 14. concept:trivial-verifiability — falsifiable vs verifiable distinction
- **Status:** adopted (core principle), partial (nuanced distinction)
- **Spec detail:** detailed
- **Spec:** `grimoire/concepts/(trivial) verifiability.md`
- **Dependencies:** None
- **Tasks:**
  1. Add falsifiable vs verifiable distinction to checks design-principles (warn against treating grep as exhaustive)
  2. Add to cartography/summon: guidance on using non-verifiable queries as exploration tools while treating output as radioactive
  3. Frame goal condition as "testable hypothesis" in write-poc steps 2-3

### 15. concept:hypothesis-generation — seeded/unseeded guidance
- **Status:** adopted (core), partial (associative mode absent)
- **Spec detail:** detailed
- **Spec:** `grimoire/concepts/hypothesis generation.md`
- **Dependencies:** None
- **Tasks:**
  1. Frame cartography security notes as testable hypotheses (e.g., "Hypothesis: trust boundary at X can be bypassed via Y")
  2. Add seeded vs unseeded guidance to cartography exploration modes
  3. Add to sigil: "If you discover tangential issues, note briefly and suggest spawning a separate sigil"
  4. Consider lightweight hook in write-poc/cartography that surfaces related vulnerability patterns from spellbook

### 16. concept:original-sin — explicit in skills
- **Status:** adopted (implicit through confirmation gates)
- **Spec detail:** detailed
- **Dependencies:** None
- **Tasks:**
  1. Add brief philosophy note to cartography family reminding that these tools surface data but don't replace judgment
  2. Consider shared preamble or cross-reference for the original-sin principle

## Cross-Cutting Adoption

| Concept/Flow | Adoption | Touches | Recommendations |
|---|---|---|---|
| **concept:trivial-verifiability** | adopted | write-poc, familiar, sigil, checks | Add falsifiable-vs-verifiable distinction (#14) |
| **concept:agent-context** | adopted | All agents | Context hygiene thoroughly practiced |
| **concept:what-is-grimoire** | adopted | Plugin design broadly | Consider orientation mechanism for new users |
| **concept:personal-grimoire** | adopted | scribe, scribe-distill, summon | End-of-audit merge not concrete (#7) |
| **concept:don't-get-in-the-way** | adopted | All skills/agents | "Exploration over stored summaries" not explicitly stated |
| **concept:the-original-sin** | partially_adopted | All skills/agents | Not named; missing from mechanical skills (#16) |
| **concept:backpressure** | partially_adopted | sigil (core principle), checks, write-poc | Semgrep/slither needed for enforcement (#13) |
| **concept:hypothesis-generation** | partially_adopted | write-poc, cartography, sigil, familiar | No associative surfacing; no ralph loop (#15) |
| **concept:context-building** | partially_adopted | summon, cartography, sigil, write-poc | **Gadgets completely missing** (#12) |
| **flow:autonomous-discovery** | partially_adopted | sigil, familiar, librarian, gnome, scribe | No standalone mid-engagement sigil invocation (#11) |
| **flow:finding-discovery** | partially_adopted | finding-draft, scribe-distill, sigil | scribe→variant loop not wired (#10) |

## Implementation Debt

Skills that work but lack structural depth compared to mature peers (write-poc, checks, cartography pattern: SKILL.md + references/ + examples/ + scripts/).

| Skill | Has | Missing | Priority |
|-------|-----|---------|----------|
| **scribe-distill** | SKILL.md, references/ (2 files) | examples/, scripts/ | Medium |
| **scribe-gc** | SKILL.md | references/, examples/, scripts/ | Low |
| **scribe-utilities** | SKILL.md | references/, examples/, scripts/ | Low |

Note: finding-draft, finding-review, and finding-dedup are SKILL.md-only but deliberately delegate to the base `finding` skill for shared references/examples/scripts. This is architecturally sound — not debt.

## Needs Spec Work

Items with `sketch` spec detail requiring answers before implementation.

### skill:codeql
- No spec file exists at `grimoire/skills/sigils/codeql.md`
- Which languages to support initially?
- What query patterns to focus on?
- How does it relate to the existing checks format?

### skill:triage
- Mentioned in roadmap (`grimoire/ideas/notes.md`)
- What is triage as a skill vs familiar agent triage? Is this absorbed by the familiar?
- What specific assessment framework beyond familiar's verify/dismiss/adjust?

### agent:imp
- Spec: brief mention in `grimoire/ideas/notes.md` and `grimoire/ideas/todo.md`
- Manual (user supplies audits) or automated (crawl audit DBs)?
- What external audit sources? (Solodit, Code4rena, OpenZeppelin?)
- How does imp differ from librarian? (imp = adversarial audit analysis, librarian = general reference?)

### concept:gadgets (partial — enough to start, but questions remain)
- How should gadgets be cataloged? Relationship to spellbook?
- What's the indexing/retrieval mechanism during PoC development?
- Can gadgets be expressed as unit tests? What format?

### infra:alchemy
- Mentioned in `grimoire/ideas/notes.md`
- What is "pi" extensibility framework? What are "alloyed agents"?
- Needs full architecture spec before any implementation

### infra:grimoire-guide
- Mentioned in `grimoire/ideas/notes.md`
- Target audience? Format (single guide vs blog series)?
- Content scope (all skills or beginner subset)?

### Sketch-only roadmap items (no spec files)
- skill:identify, skill:context, skill:scoping, skill:flow, skill:report, skill:enscribe
- These appear in `grimoire/ideas/notes.md` as roadmap bullets with no further detail

## Completed

Items with status `implemented` and no remaining tasks.

- **skill:write-poc** — 5-phase workflow, 10 reference docs, 4 examples, validation script. Exceeds spec. 0 debt.
- **skill:finding** — Base knowledge skill. SKILL.md + 3 references + 3 examples + 2 scripts. Full spec coverage.
- **skill:finding-draft** — 7-step workflow. Delegates to finding base for references. 0 debt.
- **skill:finding-review** — 4-step workflow. All 5 review dimensions from spec covered. 0 debt.
- **skill:finding-dedup** — 4-step workflow. Extends spec with 3-class model. 0 debt.
- **skill:finding-utilities** — Absorbed into finding/scripts/ (index-findings.sh, validate-finding.sh). 0 debt.
- **skill:checks** — 8-step workflow, 2 references, 5 examples, 2 scripts. Full pattern profile. 0 debt.
- **skill:cartography** — 6-step workflow, 1 reference, 2 examples, 1 script. Swarm exploration (100 subagents), callgraph-following, context rebuild, conditional load/skip criteria. Full spec coverage. 0 debt.
- **skill:review-cartography** — 6-step workflow, references, examples, scripts. 0 debt.
- **skill:gc-cartography** — 6-step workflow, 2 references, 1 example, 4 scripts. Most robust skill. 0 debt.
- **agent:librarian** — External research agent. 2 modes, MCP tools (claudit) wired, citation-backed. Auto-discovered.
- **agent:familiar** — QA gatekeeper. 3 modes (finding triage, batch triage, PoC review). Skeptical verifier. Auto-discovered.
- **agent:scribe** — Detection module builder. 3 modes (distill, spellbook management, query). Auto-discovered.
- **agent:gnome** — Worker agent. 4 modes (check, semgrep rule, slither detector, PoC). Auto-discovered.
- **agent:sigil** — Vulnerability hunter. 2 modes (single-target hunt, variant analysis). Backpressure as core principle. Auto-discovered.
- **infra:audit-directory-structure** — Fully specified in summon SKILL.md step 2.
- **infra:cartography-files** — Format spec, indexing script, conditional sections. Complete.
- **infra:finding-files** — Frontmatter schema, filing conventions, validation script. Complete.
- **infra:check-files** — Format spec, design principles, validation script. Complete.
- **infra:grimoire-file-format** — Living document format with bloat check. Complete.
- **infra:cartography-indexing** — Index script with edge case handling. Complete.
- **concept:what-is-grimoire** — Covered by README.md and plugin design.
- **concept:agent-context** — Subagent patterns used throughout all implemented skills/agents.
- **concept:don't-get-in-the-way** — Exploration-first approach in cartography and summon.
- **skill:annotation** — Python CLI (python-fire + tree-sitter) for @audit annotation discovery. SKILL.md + 1 reference + 1 example + find-annotations.py script. First tool-backed skill. Full spec coverage. Establishes the Python CLI pattern for future tool-backed skills.
