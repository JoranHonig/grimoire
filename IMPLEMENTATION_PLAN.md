# Implementation Plan

Generated: 2026-03-09

## Priority Queue

Items with remaining work, sorted by priority (highest first).

### 1. agent:sigil
- **Status:** partial
- **Spec detail:** detailed
- **Spec:** `grimoire/agents/sigil.md`
- **Dependencies:** skill:checks (done), agent:familiar (for triage)
- **Tasks:**
  1. ~~Create sigil agent definition and prompt (single-context vulnerability hunter)~~ DONE
  2. ~~Implement summon → sigil spawning logic (requires summon update)~~ DONE — Added step 9 to summon workflow, reference doc `sigil-spawning.md` with subagent prompt template, `select-checks.sh` for language filtering, slug convention, user confirmation gate, batch-of-5 parallelism. Familiar triage deferred with explicit insertion point.
  3. ~~Build check-based sigil abstraction for deterministic findings~~ DONE (Mode 1 step 3)
  4. ~~Implement variant-sigil for recurring bug patterns (post-finding)~~ DONE (Mode 2)
  5. Implement super-sigil pattern (semgrep/slither runners spawning validation sigils) — blocked on semgrep/slither skills
  6. Design sigil → familiar triage coordination — blocked on agent:familiar

### 2. agent:familiar
- **Status:** not_implemented
- **Spec detail:** detailed
- **Spec:** `grimoire/agents/familiar.md`
- **Dependencies:** agent:sigil (provides findings to triage)
- **Tasks:**
  1. Design familiar agent prompt (skepticism, verification, honesty about limitations)
  2. Implement finding triage workflow (accepts hypothesis or sigil output)
  3. Build librarian invocation for external references
  4. Implement customization system (animal type, name)
  5. Add quality control helpers (accuracy checks, completeness estimates)
  6. Create PoC review and feedback workflow

### 3. agent:scribe
- **Status:** not_implemented
- **Spec detail:** detailed
- **Spec:** `grimoire/agents/scribe.md`
- **Dependencies:** skill:checks (done), agent:familiar (for triage)
- **Tasks:**
  1. Design scribe agent prompt (autonomous detection module builder)
  2. Implement scribe invocation from finding workflows
  3. Build enscribe skill (finding → static analysis module or knowledge artifact)
  4. Implement variant analysis workflow (run detector against rest of codebase)
  5. Create spellbook storage structure (detect/, rules/, modules/)
  6. Document scribe-summon integration for audit initialization

### 4. concept:backpressure (enforcement in skills)
- **Status:** partial
- **Spec detail:** detailed
- **Spec:** `grimoire/concepts/backpressure.md`
- **Dependencies:** None
- **Tasks:**
  1. Create shared reference doc `backpressure-methods.md` listing when to use semgrep/codeql/slither
  2. Add to summon step 8: explicit check for backpressure before recommending autonomous findings
  3. Add to write-poc: "avoid unmeasurable claims" guidance

### 5. concept:the-original-sin + concept:leverage (explicit in skills)
- **Status:** partial (implicit)
- **Spec detail:** detailed
- **Dependencies:** None
- **Tasks:**
  1. Create shared reference doc `principles.md` covering human judgment, leverage, and the original sin
  2. Update write-poc philosophy section to reference human-directed hypothesis, not autonomous exploitation
  3. Update summon philosophy to emphasize researcher interprets crown jewels, agent only maps

### 6. concept:trivial-verifiability (explicit in skills)
- **Status:** partial
- **Spec detail:** detailed
- **Spec:** `grimoire/concepts/(trivial) verifiability.md`
- **Dependencies:** None
- **Tasks:**
  1. Add verifiability language to write-poc steps 2-3 (goal condition as testable hypothesis)
  2. Reference falsifiable vs verifiable distinction in summon step 8 and checks step 2

### 7. concept:hypothesis-generation (explicit in skills)
- **Status:** partial
- **Spec detail:** detailed
- **Spec:** `grimoire/concepts/hypothesis generation.md`
- **Dependencies:** None
- **Tasks:**
  1. Frame goal condition as "testable hypothesis" in write-poc
  2. Add seeded vs unseeded guidance to cartography exploration modes

### 8. concept:context-building (gadgets gap)
- **Status:** partial
- **Spec detail:** detailed
- **Spec:** `grimoire/concepts/context building.md`
- **Dependencies:** None for concept; gadgets depend on proof-of-concept integration
- **Tasks:**
  1. Document gadget concept and catalog structure
  2. Add gadget awareness to write-poc workflow (check for applicable gadgets)

### 9. flow:finding-discovery
- **Status:** partial
- **Spec detail:** partial
- **Spec:** `grimoire/flows/finding discovery.md`
- **Dependencies:** skill:finding (done), agent:scribe
- **Tasks:**
  1. Document end-to-end flow once finding skill is built
  2. Wire PoC → finding → scribe pipeline

### 10. flow:autonomous-discovery
- **Status:** not_implemented
- **Spec detail:** partial
- **Spec:** `grimoire/flows/autonomous discovery.md`
- **Dependencies:** agent:sigil, agent:familiar, skill:finding (done)
- **Tasks:**
  1. Implement sigil → familiar → PoC → finding pipeline
  2. Wire librarian integration points
  3. Document the full autonomous discovery flow

### 11. skill:scribe-distill
- **Status:** not_implemented
- **Spec detail:** partial
- **Spec:** `grimoire/skills/scribe.md`
- **Dependencies:** agent:scribe
- **Tasks:**
  1. Create `skills/scribe-distill/` directory
  2. Draft SKILL.md with workflow (capture context → analyze for patterns → propose automation)
  3. Build examples of distillation for common vuln types
  4. Define trigger conditions and integration with scribe agent

### 12. concept:personal-grimoire
- **Status:** not_implemented
- **Spec detail:** partial
- **Spec:** `grimoire/concepts/personal grimoire.md`
- **Dependencies:** agent:scribe (manages it)
- **Tasks:**
  1. Define ~/.grimoire/ directory structure
  2. Implement sigil merge workflow (project → personal grimoire)

### 13. infra:spellbook (management)
- **Status:** partial
- **Spec detail:** partial
- **Spec:** `grimoire/agents/scribe.md`
- **Dependencies:** agent:scribe
- **Tasks:**
  1. Add user-facing explanation of spellbook concept
  2. Implement spellbook management workflow (depends on scribe)

### 14. infra:tomes (format guidance)
- **Status:** partial
- **Spec detail:** partial
- **Spec:** `grimoire/skills/summon.md`, `grimoire/ideas/todo.md`
- **Dependencies:** None
- **Tasks:**
  1. Create format guidance doc for tomes
  2. Add "when to create a tome" guidance to summon

## Implementation Debt

Items that work but need structural improvements.

### concept:trivial-verifiability
- Enforced via PoC checklist but falsifiable vs verifiable framing absent from skill instructions
- See Priority Queue #7 for tasks

### concept:hypothesis-generation
- Partially reflected in PoC goal conditions and cartography exploration modes
- See Priority Queue #8 for tasks

### concept:backpressure
- Checks skill provides backpressure; no explicit enforcement mechanism in other skills
- See Priority Queue #5 for tasks

### infra:tomes
- Summon creates tomes/ directory; needs format guidance doc
- See Priority Queue #15

### infra:spellbook
- Summon creates spells/ directory; checks stores in grimoire/spells/checks/
- Needs user-facing explanation and management workflow (depends on scribe agent)

## Completed

- **skill:write-poc** — Production-ready. SKILL.md with Philosophy section, `user_invocable: true`, 5-step workflow with confirmation checkpoints at every step, vuln-class-to-reference lookup table in step 3. 10 reference files covering 7+ vulnerability classes. 4 worked examples (ssrf-curl, sqli-python, reentrancy-foundry, price-oracle-fork-test) demonstrating all 4 PoC approaches. scripts/validate-poc.sh for structural validation. Full spec coverage, 0 debt. Thin references (crypto-vulns, config-issues, general-principles) noted as future content improvement opportunity.
- **skill:finding** — Base knowledge skill. Teaches finding structure, format, best practices, severity scale, filing conventions. SKILL.md + references (finding-format.md, finding-best-practices.md, finding-structure.md) + examples (reentrancy, access-control, dedup-scenario) + scripts (index-findings.sh, validate-finding.sh). Full spec coverage, 0 debt.
- **skill:finding-draft** — Workflow skill. 6-step draft workflow. Loads base finding skill first.
- **skill:finding-review** — Workflow skill. 3-step review workflow. Loads base finding skill first.
- **skill:finding-dedup** — Workflow skill. 3-step dedup workflow. Loads base finding skill first.
- **infra:findings-structure** — Implemented in skill:finding. Frontmatter schema, filing conventions, cross-linking documented in skills/finding/references/.
- **skill:checks** — Production-ready. SKILL.md (3 modes: create/apply/manage), references/check-format.md + references/design-principles.md, 5 worked examples, scripts/index-checks.sh + scripts/validate-check.sh. Full spec coverage, 0 debt.
- **skill:summon** — Production-ready. 290-line SKILL.md, references/domain-crown-jewels.md, examples/grimoire-md-example.md. Full spec coverage, no debt.
- **skill:cartography** — Production-ready. SKILL.md + references/cartography-format.md + examples/cartography-example.md + scripts/index-cartography.sh. Full spec coverage, no debt.
- **concept:what-is-grimoire** — Covered by README.md and overall plugin design.
- **concept:agent-context** — Subagent patterns used throughout all implemented skills.
- **concept:dont-get-in-the-way** — Exploration-first approach in cartography and summon.
- **infra:audit-directory-structure** — Fully specified in summon SKILL.md step 2.
- **infra:cartography-directory** — Fully specified with format, indexing script, and examples.
- **skill:review-cartography** — Production-ready. SKILL.md (6-step workflow with subagent decomposition for independent verification). references/cartography-format.md (symlink to cartography skill), references/overlap-detection.md (>40% threshold formalization, 3-tier overlap classification). examples/cartography-review-example.md (before/after review cycle with 4 common issues). scripts/validate-cartography.sh (frontmatter, sections, file existence, reciprocal link checks) + scripts/find-overlaps.sh (pairwise component comparison with configurable threshold). Full spec coverage, 0 debt.
- **skill:gc-cartography** — Production-ready. SKILL.md (6-step workflow with user confirmation gates) updated with explicit pointers to reference docs and explicit file paths. references/merge-decisions.md (decision framework: merge-when/keep-separate criteria, primary flow selection, ambiguous case handling) + references/overlap-metrics.md (overlap formula, 4-tier classification, subset detection, cluster detection, metric limitations). examples/gc-before-after.md (complete worked example: two overlapping vault flows merged with conditional section, cross-reference cleanup). scripts/detect-overlaps.sh (wraps review-cartography's find-overlaps.sh, adds subset/cluster detection and primary flow suggestion) + scripts/merge-flows.sh (structural merge: frontmatter union, section merging, conditional section generation) + scripts/update-references.sh (stale link replacement with reciprocal link checking) + scripts/validate-gc.sh (post-merge integrity: runs validate-cartography.sh, checks dangling references, verifies completeness). Full spec coverage (6/6), 0 debt.
- **agent:sigil (core + summon integration)** — Single-context vulnerability hunter agent. `agents/sigil.md` with agent frontmatter (name, description with trigger phrases, tools: Read/Grep/Glob/Bash). System prompt covers three modes: Mode 1 (single sigil — 7-step hypothesis-driven hunt with GRIMOIRE.md consultation, check integration, finding output), Mode 2 (variant sigil — pattern generalization and full-codebase scan), Mode 3 (super sigil — stubbed, blocked on semgrep/slither skills). Strategy section covers hypothesis-driven hunting, check integration, external context via librarian, and scope discipline. Output format with per-finding detail and hunt summary. Constraints enforce evidence-only assertions, one-vector-per-invocation, benign payloads, parameterized targets. Summon integration: step 9 added to summon workflow with check indexing, language filtering (`select-checks.sh`), user confirmation gate, batch-of-5 subagent spawning, result aggregation, GRIMOIRE.md update. Reference doc `sigil-spawning.md` provides subagent prompt template, parallelism rationale, and familiar integration roadmap. Summon step 2 updated to create `sigil-findings/` and `tmp/` directories per spec. 18/24 spec requirements covered; 6 deferred (familiar triage, scribe/gnome integration, super-sigil tooling). Remaining tasks: super-sigil (#5), familiar coordination (#6).
- **agent:librarian** — External research agent. `agents/librarian.md` with agent frontmatter (name, description with trigger phrases, tools: Read/Grep/Glob/Bash/WebSearch/WebFetch). System prompt covers two modes (directed question, generic study), 6-tier source priority (specs → repos → security KBs → audits → local grimoire → web), citation format, and constraints (no file mods, no code gen, citation required). Plugin.json updated with `"agents": "auto"`. Placeholder references updated in finding-draft, finding-review, checks, and finding-best-practices. context7/exa omitted (MCP services not bundled; WebSearch covers same ground). 12/16 spec requirements covered; 4 gaps are low-severity (familiar/autonomous-discovery agents not yet implemented, context7/exa are environment-specific MCP configs).

## Needs Spec Work

Items with `sketch` spec detail requiring answers before implementation.

### skill:semgrep
- Spec: 7 lines in `grimoire/skills/sigils/semgrep.md`
- What specific aspects of semgrep usage to teach? Rule anatomy? Testing? CI integration?
- How detailed should the skill be vs "just teach the agent the basics"?
- Should it include rule merging guidance (noted in spec)?

### skill:slither
- Spec: 5 lines in `grimoire/skills/sigils/slither.md`
- What napalm integration patterns should be covered?
- How to handle documentation requirements for detection modules?
- What detector anatomy to teach?

### skill:codeql
- No spec file exists at `grimoire/skills/sigils/codeql.md`
- Which languages to support initially?
- What query patterns to focus on?

### skill:enscribe
- No dedicated spec file. Referenced in `grimoire/skills/scribe.md`
- What are the handlers per tool type (semgrep YAML, slither detector, CodeQL query)?
- What's the validation workflow for generated modules?

### skill:scribe-utilities
- Brief mention in `grimoire/skills/scribe.md`
- What specific utilities? Index, search, stats?
- What information is useful to surface about sigils?

### skill:scribe-gc
- Brief mention in `grimoire/skills/scribe.md`
- What constitutes "duplication" across different tool types (semgrep vs slither vs codeql)?
- How to handle project-specific vs generalizable sigils?

### agent:gnome
- Spec: `grimoire/agents/gnome.md` (partial)
- What model tier is appropriate (Opus for code gen vs Sonnet for simple rewrites)?
- What's the task handoff protocol? How does context get passed?
- What reporting format for completion status?

### agent:imp
- Spec: brief mention in `grimoire/ideas/notes.md` and `grimoire/ideas/todo.md`
- Manual (user supplies audits) or automated (crawl audit DBs)?
- What external audit sources? (Solodit, Code4rena, OpenZeppelin?)
- How does imp differ from librarian? (imp = adversarial audit analysis, librarian = general reference?)

### concept:gadgets
- Described in `grimoire/concepts/context building.md`
- How should gadgets be cataloged? Relationship to spellbook?
- What's the indexing/retrieval mechanism during PoC development?
- Can gadgets be expressed as unit tests? What format?

### concept:personal-grimoire
- Spec: 4 lines in `grimoire/concepts/personal grimoire.md`
- How does project state merge with personal grimoire? Conflict resolution?
- What directory structure within ~/.grimoire/?
- How do teams share spellbook content?

### infra:alchemy
- Mentioned in `grimoire/ideas/notes.md`
- What is "pi" extensibility framework? What are "alloyed agents"?
- Needs full architecture spec before any implementation

### infra:grimoire-guide
- Mentioned in `grimoire/ideas/notes.md`
- Target audience? Format (single guide vs blog series)?
- Content scope (all skills or beginner subset)?
