# Grimoire Implementation Plan

_Generated: 2026-03-19 · Updated: 2026-03-19 (implemented modify-library)_

---

## Priority Queue

### Tier 2: Shallow Skills (structural depth)

**2. `skill:scribe-distill` — shallow**
- Spec detail: detailed
- Evidence: `skills/scribe-distill/SKILL.md` + `references/` (2 files); no `examples/`, `scripts/`
- Tasks:
  - Add `examples/` with a worked end-to-end distillation: confirmed finding → check file
  - Add `scripts/validate-distill.sh` or reference `checks/scripts/validate-check.sh`
- Notes: Central to the automation workflow (finding → detector pipeline); highest-leverage shallow skill

**3. `skill:finding-draft` — shallow**
- Spec detail: detailed
- Evidence: `skills/finding-draft/SKILL.md` only; no supporting dirs
- Tasks:
  - SKILL.md delegates format/examples to `skills/finding/` — verify cross-references work
  - Add falsifiable-vs-verifiable framing note (concept:trivial-verifiability adoption)
- Notes: No urgent need for standalone `references/` since it fully delegates to base finding skill

**4. `skill:finding-review` — shallow**
- Spec detail: detailed
- Evidence: `skills/finding-review/SKILL.md` only; no supporting dirs
- Tasks:
  - Add `examples/` with a before/after review showing a finding improved by the skill

**5. `skill:finding-dedup` — shallow**
- Spec detail: detailed
- Evidence: `skills/finding-dedup/SKILL.md` only; no supporting dirs
- Tasks:
  - Verify SKILL.md reference to `finding/examples/dedup-scenario.md` works
  - No additional examples needed if that scenario is sufficient

**6. `skill:scribe-gc` — shallow**
- Spec detail: detailed
- Evidence: `skills/scribe-gc/SKILL.md` only; no supporting dirs
- Tasks:
  - Add `examples/` with a before/after GC scenario (overlapping sigils → merged result)

**7. `skill:scribe-utilities` — shallow**
- Spec detail: detailed
- Evidence: `skills/scribe-utilities/SKILL.md` only; no supporting dirs
- Tasks:
  - Add `examples/` showing sample output for list/stats/search operations

---

### Tier 3: Cross-Cutting Adoption Tasks

**8. `concept:backpressure` — partially adopted**
- Tasks:
  - Add a brief backpressure framing note to `checks/SKILL.md` philosophy section
  - Implement semgrep/slither when spec is ready (those are the remaining back-pressure mechanisms)

**9. `concept:hypothesis-generation` — not adopted**
- Tasks:
  - Add a brief note to `summon/SKILL.md` and `finding-draft/SKILL.md` about seeded vs. unseeded hypothesis generation

---

## Cross-Cutting Adoption

**`concept:backpressure`** — partially_adopted
- Touches: write-poc, checks, scribe-distill, semgrep (unbuilt), slither (unbuilt)
- Adopted: write-poc (PoC enforces verification), scribe-distill (produces runnable detectors)
- Gaps: `checks/SKILL.md` doesn't explicitly frame backpressure; semgrep/slither unbuilt
- Recommendation: Add backpressure framing to `checks/SKILL.md`; implement semgrep/slither when spec is ready

**`concept:trivial-verifiability`** — partially_adopted
- Touches: finding-draft, checks, write-poc, scribe-distill
- Adopted: write-poc (requires runnable PoC)
- Gaps: Not explicitly surfaced in finding-draft or checks
- Recommendation: Add falsifiable-vs-verifiable framing note to `finding-draft/SKILL.md`

**`concept:context-building`** — partially_adopted
- Touches: cartography, summon, librarian
- Adopted: cartography (flow maps), summon (GRIMOIRE.md)
- Gaps: Gadgets concept absent from any skill; no gadget indexing workflow
- Recommendation: Hold until spec author elaborates gadgets concept

**`concept:hypothesis-generation`** — not_adopted
- Touches: finding-draft, summon, sigil
- Gaps: No skill explicitly frames the researcher hypothesis loop
- Recommendation: Add seeded vs. unseeded hypothesis generation note to summon and finding-draft

**`concept:the-original-sin`** — partially_adopted
- Touches: all skills
- Adopted: philosophy sections in write-poc and checks resist cognitive offloading
- Acceptable: embedded in "verify before trusting" guidance throughout

**`concept:agent-context`** — adopted
- Subagent delegation used throughout write-poc, summon, cartography, finding-review

**`concept:dont-get-in-the-way`** — adopted
- Skills are minimal orchestration layers backed by focused references

**`concept:personal-grimoire`** — partially_adopted
- `~/.grimoire/sigils/` and `~/.grimoire/knowledge/` referenced in scribe-gc and scribe-utilities
- `~/.grimoire/librarian/` partially implemented (cache documented, library management skills pending)
- Recommendation: Implement librarian-initialize and modify-library skills

**`flow:finding-discovery`** — adopted
- write-poc → finding-draft → scribe-distill chain wired; all participants exist

**`flow:autonomous-discovery`** — adopted
- sigil → familiar → write-poc → finding chain present in summon step 9

---

## Implementation Debt

Skills with `shallow` status — SKILL.md files are thorough but lack the structural depth of peer skills:

| Skill | Missing Structure |
|-------|-------------------|
| `skill:finding-draft` | no `references/`, `examples/`, `scripts/` |
| `skill:finding-review` | no `references/`, `examples/`, `scripts/` |
| `skill:finding-dedup` | no `references/`, `examples/`, `scripts/` |
| `skill:scribe-distill` | has `references/`; missing `examples/`, `scripts/` |
| `skill:scribe-gc` | no `references/`, `examples/`, `scripts/` |
| `skill:scribe-utilities` | no `references/`, `examples/`, `scripts/` |
| `skill:librarian-clean-cache` | no `references/`, `examples/`, `scripts/` (low priority — simple skill) |

---

## Needs Spec Work

**`skill:semgrep`** (sketch)
- Questions for spec author:
  - What language domains should be covered (Solidity, Rust, Go, all)?
  - One file per rule, or rules grouped by vulnerability class?
  - What output format when rules produce findings?
  - How does this integrate with super-sigil running in `agent:sigil`?

**`skill:slither`** (sketch)
- Questions for spec author:
  - What is the napalm integration pattern — does the skill install napalm or assume it's present?
  - Expected detector format: Python class subclassing AbstractDetector, or standalone script?
  - Should the skill cover writing both detectors and printers?
  - Storage location for slither detectors — `grimoire/spells/` alongside checks?

**`infra:tomes`** (sketch, flagged in `ideas/todo.md`)
- Questions for spec author:
  - What frontmatter fields do tome files use?
  - What distinguishes a cartography file from a tome?
  - How does compaction work (when to create vs extend vs replace a tome)?
  - How does the librarian surface relevant tomes to other agents?

**`skill:librarian-initialize`** — ~~all questions resolved; skill implemented~~
- ~~Should the skill also create `cache/`?~~ Resolved: Yes.
- ~~Should it detect an already-initialized directory?~~ Resolved: Yes, upgrade in place.
- ~~What constitutes a "library structure upgrade"?~~ Resolved: Check all four components (root, library/, cache/, libraries.yaml) individually; create only absent ones. No versioning needed.

**`skill:modify-library`** — ~~all questions resolved; skill implemented~~
- ~~Single skill or split?~~ **Resolved:** Single skill.
- ~~Git URL validation approach?~~ **Resolved:** `git ls-remote` — lightweight network check, no clone needed.

---

## Completed

Items with status `implemented` and no remaining tasks:

- `skill:modify-library` — `skills/modify-library/`: 4-step workflow (parse intent → validate → apply → report), handles add/remove/change operations on `libraries.yaml`. Validates git URLs via `git ls-remote` and symlink paths via `test -d`. Guards against missing/corrupt YAML, duplicate names, and absent entries. Includes `examples/add-git-library.md` and `examples/add-symlink-library.md`. Git validation resolved as `git ls-remote` (lightweight, no clone).

- `skill:librarian-initialize` — `skills/librarian-initialize/`: 4-step workflow (detect state → plan → apply missing → report), handles fresh install and upgrade-in-place, never overwrites existing `libraries.yaml`. Includes `examples/fresh-install.md` and `examples/upgrade-run.md`. "Upgrade" resolved as: check all four expected components individually and create only absent ones.

- `agent:librarian` — `agents/librarian.md`: fixed cache path, added Local Knowledge Bases section (libraries.yaml format, git pull freshness, library vs cache distinction), Cache Management section documenting the two-directory model and referencing `librarian-clean-cache`
- `skill:librarian-clean-cache` — `skills/librarian-clean-cache/SKILL.md`: 4-step workflow (inspect → confirm → remove → report), edge case handling for missing/empty cache, safety guidelines (never touches library/)
- `infra:librarian-cache` + `infra:librarian-library` — Documented in `agents/librarian.md`: `~/.grimoire/librarian/` layout, `libraries.yaml` format (type: git, source: url), cache (transient) vs library (maintained) distinction

- `skill:write-poc` — Full structure (SKILL.md + 4 examples + 10 references + 1 script)
- `skill:summon` — Full structure (SKILL.md + examples + references + scripts); 9-step workflow
- `skill:cartography` — Full structure (SKILL.md + 2 examples + 1 reference + 1 script)
- `skill:review-cartography` — Full structure (SKILL.md + 1 example + 1 reference + 2 scripts)
- `skill:gc-cartography` — Full structure (SKILL.md + 1 example + 2 references + 4 scripts)
- `skill:annotation` — Full structure (SKILL.md + 1 example + 1 reference + 3 scripts; Python CLI)
- `skill:finding` — Full structure (SKILL.md + 3 examples + 3 references + 2 scripts; base skill)
- `skill:checks` — Full structure (SKILL.md + 5 examples + 2 references + 2 scripts)
- `agent:familiar` — `agents/familiar.md`; triage modes; referenced in finding-review, write-poc, summon
- `agent:gnome` — `agents/gnome.md`; worker agent; referenced in write-poc, scribe-distill
- `agent:scribe` — `agents/scribe.md`; distill + GC + utilities modes
- `agent:sigil` — `agents/sigil.md`; single-context vulnerability hunter
- `infra:personal-grimoire` — `~/.grimoire/sigils/` + `~/.grimoire/knowledge/` referenced in skills
- `infra:spellbook` — `grimoire/spells/checks/` created by summon
- `infra:directory-structure` — Full `grimoire/` layout created by summon step 2
