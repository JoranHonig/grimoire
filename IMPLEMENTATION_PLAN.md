# Implementation Plan

Generated: 2026-03-09

## Priority Queue

Items with remaining work, sorted by priority (highest first).

### 1. skill:write-poc (structural improvements)
- **Status:** partial
- **Spec detail:** detailed
- **Spec:** `grimoire/skills/proof of concept.md`
- **Dependencies:** None
- **Tasks:**
  1. Add `user_invocable: true` to SKILL.md YAML frontmatter
  2. Add "Philosophy" section articulating opinionated structure, 90% one-shot success, core principles from spec
  3. Create `examples/` directory with 3-4 worked examples (smart contract fork test, web app XSS, race condition, config issue)
  4. Refactor workflow steps to explicitly tie vulnerability class to reference file selection in step 3
  5. Add explicit confirmation checkpoints at each numbered step (partially done, verify completeness)
  6. (Optional) Create `scripts/` with output validator (checks for destructive commands, hardcoded targets)

### 2. agent:librarian
- **Status:** not_implemented
- **Spec detail:** detailed
- **Spec:** `grimoire/agents/librarian.md`
- **Dependencies:** None (standalone, used on-demand by other agents)
- **Why priority:** Referenced by familiar, finding-review, checks, and many other future agents. Standalone with no dependencies. Implementing it early unblocks quality across the board.
- **Tasks:**
  1. Design agent prompt emphasizing reference-backed claims, no speculation
  2. Implement directed-question workflow (specific question → referenced answer)
  3. Implement generic-study workflow (async context priming)
  4. Set up integrations: solodit, exa, github CLI, web search
  5. Build reference tracking and citation system
  6. Create personal grimoire lookup for local knowledge

### 3. skill:review-cartography (supporting infrastructure)
- **Status:** shallow
- **Spec detail:** detailed
- **Spec:** `grimoire/skills/cartography.md`
- **Dependencies:** skill:cartography (implemented)
- **Tasks:**
  1. Create `references/cartography-format.md` (copy/symlink from cartography skill)
  2. Create `references/overlap-detection.md` formalizing >40% threshold, shared component detection
  3. Create `examples/cartography-review-example.md` showing before/after review cycle
  4. Create `scripts/validate-cartography.sh` (verify format, frontmatter, file existence, link reciprocity)
  5. Create `scripts/find-overlaps.sh` (compare flows, flag >40% overlap candidates)

### 4. skill:gc-cartography (supporting infrastructure)
- **Status:** shallow
- **Spec detail:** detailed
- **Spec:** `grimoire/skills/cartography.md`
- **Dependencies:** skill:cartography (implemented)
- **Tasks:**
  1. Create `references/merge-decisions.md` formalizing decision framework and >40% threshold
  2. Create `references/overlap-metrics.md` defining overlap calculation
  3. Create `examples/` with before/after GC pair showing actual merge
  4. Create `scripts/detect-overlaps.sh` (calculate and report flow overlap percentages)
  5. Create `scripts/merge-flows.sh` (automate merge of two files)
  6. Create `scripts/update-references.sh` (fix stale cartography links across repo)
  7. Create `scripts/validate-gc.sh` (verify merge result integrity)

### 5. agent:sigil
- **Status:** not_implemented
- **Spec detail:** detailed
- **Spec:** `grimoire/agents/sigil.md`
- **Dependencies:** skill:checks (done), agent:familiar (for triage)
- **Tasks:**
  1. Create sigil agent definition and prompt (single-context vulnerability hunter)
  2. Implement summon → sigil spawning logic
  3. Build check-based sigil abstraction for deterministic findings
  4. Implement variant-sigil for recurring bug patterns (post-finding)
  5. Implement super-sigil pattern (semgrep/slither runners spawning validation sigils)
  6. Design sigil → familiar triage coordination

### 6. agent:familiar
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

### 7. agent:scribe
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

### 8. concept:backpressure (enforcement in skills)
- **Status:** partial
- **Spec detail:** detailed
- **Spec:** `grimoire/concepts/backpressure.md`
- **Dependencies:** None
- **Tasks:**
  1. Create shared reference doc `backpressure-methods.md` listing when to use semgrep/codeql/slither
  2. Add to summon step 8: explicit check for backpressure before recommending autonomous findings
  3. Add to write-poc: "avoid unmeasurable claims" guidance

### 9. concept:the-original-sin + concept:leverage (explicit in skills)
- **Status:** partial (implicit)
- **Spec detail:** detailed
- **Dependencies:** None
- **Tasks:**
  1. Create shared reference doc `principles.md` covering human judgment, leverage, and the original sin
  2. Update write-poc philosophy section to reference human-directed hypothesis, not autonomous exploitation
  3. Update summon philosophy to emphasize researcher interprets crown jewels, agent only maps

### 10. concept:trivial-verifiability (explicit in skills)
- **Status:** partial
- **Spec detail:** detailed
- **Spec:** `grimoire/concepts/(trivial) verifiability.md`
- **Dependencies:** None
- **Tasks:**
  1. Add verifiability language to write-poc steps 2-3 (goal condition as testable hypothesis)
  2. Reference falsifiable vs verifiable distinction in summon step 8 and checks step 2

### 11. concept:hypothesis-generation (explicit in skills)
- **Status:** partial
- **Spec detail:** detailed
- **Spec:** `grimoire/concepts/hypothesis generation.md`
- **Dependencies:** None
- **Tasks:**
  1. Frame goal condition as "testable hypothesis" in write-poc
  2. Add seeded vs unseeded guidance to cartography exploration modes

### 12. concept:context-building (gadgets gap)
- **Status:** partial
- **Spec detail:** detailed
- **Spec:** `grimoire/concepts/context building.md`
- **Dependencies:** None for concept; gadgets depend on proof-of-concept integration
- **Tasks:**
  1. Document gadget concept and catalog structure
  2. Add gadget awareness to write-poc workflow (check for applicable gadgets)

### 13. flow:finding-discovery
- **Status:** partial
- **Spec detail:** partial
- **Spec:** `grimoire/flows/finding discovery.md`
- **Dependencies:** skill:finding (done), agent:scribe
- **Tasks:**
  1. Document end-to-end flow once finding skill is built
  2. Wire PoC → finding → scribe pipeline

### 14. flow:autonomous-discovery
- **Status:** not_implemented
- **Spec detail:** partial
- **Spec:** `grimoire/flows/autonomous discovery.md`
- **Dependencies:** agent:sigil, agent:familiar, skill:finding (done)
- **Tasks:**
  1. Implement sigil → familiar → PoC → finding pipeline
  2. Wire librarian integration points
  3. Document the full autonomous discovery flow

### 15. skill:scribe-distill
- **Status:** not_implemented
- **Spec detail:** partial
- **Spec:** `grimoire/skills/scribe.md`
- **Dependencies:** agent:scribe
- **Tasks:**
  1. Create `skills/scribe-distill/` directory
  2. Draft SKILL.md with workflow (capture context → analyze for patterns → propose automation)
  3. Build examples of distillation for common vuln types
  4. Define trigger conditions and integration with scribe agent

### 16. concept:personal-grimoire
- **Status:** not_implemented
- **Spec detail:** partial
- **Spec:** `grimoire/concepts/personal grimoire.md`
- **Dependencies:** agent:scribe (manages it)
- **Tasks:**
  1. Define ~/.grimoire/ directory structure
  2. Implement sigil merge workflow (project → personal grimoire)

### 17. infra:spellbook (management)
- **Status:** partial
- **Spec detail:** partial
- **Spec:** `grimoire/agents/scribe.md`
- **Dependencies:** agent:scribe
- **Tasks:**
  1. Add user-facing explanation of spellbook concept
  2. Implement spellbook management workflow (depends on scribe)

### 18. infra:tomes (format guidance)
- **Status:** partial
- **Spec detail:** partial
- **Spec:** `grimoire/skills/summon.md`, `grimoire/ideas/todo.md`
- **Dependencies:** None
- **Tasks:**
  1. Create format guidance doc for tomes
  2. Add "when to create a tome" guidance to summon

## Implementation Debt

Items that work but need structural improvements.

### skill:review-cartography
- SKILL.md is complete (6,229 bytes) but has no supporting infrastructure
- No references/, examples/, or scripts/ directories
- See Priority Queue #3 for tasks

### skill:gc-cartography
- SKILL.md is complete (6,390 bytes) but has no supporting infrastructure
- No references/, examples/, or scripts/ directories
- See Priority Queue #4 for tasks

### skill:write-poc
- Missing `user_invocable: true` in frontmatter
- No examples/ or scripts/ directories
- No philosophy section
- See Priority Queue #1 for tasks

### concept:trivial-verifiability
- Enforced via PoC checklist but falsifiable vs verifiable framing absent from skill instructions
- See Priority Queue #10 for tasks

### concept:hypothesis-generation
- Partially reflected in PoC goal conditions and cartography exploration modes
- See Priority Queue #11 for tasks

### concept:backpressure
- Checks skill provides backpressure; no explicit enforcement mechanism in other skills
- See Priority Queue #8 for tasks

### infra:tomes
- Summon creates tomes/ directory; needs format guidance doc
- See Priority Queue #18

### infra:spellbook
- Summon creates spells/ directory; checks stores in grimoire/spells/checks/
- Needs user-facing explanation and management workflow (depends on scribe agent)

## Completed

- **skill:finding-draft** — Production-ready. Drafts structured security findings from vulnerability observations. SKILL.md with 6-step workflow. Uses shared resources in `skills/finding/`.
- **skill:finding-review** — Production-ready. Reviews existing findings against best practices (title, description, recommendation, severity, references). SKILL.md with 3-step workflow. Uses shared resources in `skills/finding/`.
- **skill:finding-dedup** — Production-ready. Identifies duplicate/similar findings and resolves overlaps with user confirmation. SKILL.md with 3-step workflow. Uses shared resources in `skills/finding/`.
- **skills/finding/ (shared resources)** — References (finding-format.md, finding-best-practices.md, finding-structure.md), examples (reentrancy, access-control, dedup-scenario), scripts (index-findings.sh, validate-finding.sh). Full spec coverage (55/55 requirements), familiar/librarian integrations stubbed. 0 debt.
- **infra:findings-structure** — Implemented as part of the finding skills. Frontmatter schema, filing conventions, cross-linking documented in skills/finding/references/.
- **skill:checks** — Production-ready. SKILL.md (3 modes: create/apply/manage), references/check-format.md + references/design-principles.md, 5 worked examples, scripts/index-checks.sh + scripts/validate-check.sh. Full spec coverage, 0 debt.
- **skill:summon** — Production-ready. 290-line SKILL.md, references/domain-crown-jewels.md, examples/grimoire-md-example.md. Full spec coverage, no debt.
- **skill:cartography** — Production-ready. SKILL.md + references/cartography-format.md + examples/cartography-example.md + scripts/index-cartography.sh. Full spec coverage, no debt.
- **concept:what-is-grimoire** — Covered by README.md and overall plugin design.
- **concept:agent-context** — Subagent patterns used throughout all implemented skills.
- **concept:dont-get-in-the-way** — Exploration-first approach in cartography and summon.
- **infra:audit-directory-structure** — Fully specified in summon SKILL.md step 2.
- **infra:cartography-directory** — Fully specified with format, indexing script, and examples.

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
