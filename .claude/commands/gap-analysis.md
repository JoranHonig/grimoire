---
name: Gap Analysis
description: >-
  Identify gaps between the grimoire specification and the actual plugin
  implementation. Build or update a prioritized implementation plan.
user_invocable: true
---

# Gap Analysis

Compare the grimoire specification against the current plugin implementation to find gaps,
then build or update a prioritized implementation plan.

## Important Constraints

- The specification lives in the `grimoire/grimoire/` directory. These files are written by a
  human and are the source of truth.
- The implementation lives in everything else at the repo root (`skills/`, `marker-groups/`,
  `.claude-plugin/`, `README.md`, etc.) — everything outside `grimoire/grimoire/`.
- The solution is NEVER to change the specification. Always extend or update the plugin.
- Use subagents heavily to keep context clean and parallelize work.

## Subagent Tools

All subagents spawned during this workflow need the following tools to function:
- **Step 0.5 subagents** (pattern learning): `Read`, `Glob`
- **Step 1 subagents** (catalog): `Read`, `Glob`, `Grep`
- **Step 2 subagents** (analysis): `Read`, `Glob`, `Grep`
- **Step 6** (update plan): uses `Write` directly (not a subagent)

When spawning subagents, explicitly grant them these tools so they can read spec files and
search the implementation.

## Paths

Anchor all file references to the repo root at `grimoire/` (the git repository root, NOT
`grimoire/grimoire/`).

- **Spec directory:** `grimoire/grimoire/` — contains subdirectories `skills/`, `agents/`,
  `concepts/`, and files like `README.md`, `notes.md`
- **Implementation root:** `grimoire/` — contains `skills/`, `marker-groups/`,
  `.claude-plugin/plugin.json`, `README.md`
- **Implemented skills:** `grimoire/skills/*/SKILL.md` (each skill has its own directory)

These two trees are completely separate. Do not confuse `grimoire/grimoire/skills/` (spec)
with `grimoire/skills/` (implementation).

## Workflow

### 0. Study Existing Plan

Check whether `IMPLEMENTATION_PLAN.md` exists at the repo root (`grimoire/IMPLEMENTATION_PLAN.md`).
If it exists, read it to understand:
- What has already been identified as implemented or incomplete
- The current priority ordering
- Any prior context about blocked or deferred items
- File modification timestamps or hashes noted for incremental tracking

Use this as a starting point — not a constraint. The plan may be outdated or incorrect; the
gap analysis below is the source of truth. But reading it first avoids redundant discovery and
helps calibrate expectations.

Always perform a full analysis — do not skip items based on prior runs. The implementation may
have changed (features added, removed, or regressed) even when specs haven't, so every item
must be re-evaluated.

### 0.5. Learn Implementation Patterns

Before cataloging the spec, study 2-3 of the most mature implemented skills to learn what a
well-built skill looks like in this plugin. Spawn 2-3 subagents in parallel, one per skill
directory (pick skills with the most files in `grimoire/skills/`). Each subagent reads the
full skill directory and reports:

- **Directory structure** — what subdirectories exist (references/, examples/, scripts/)
- **SKILL.md conventions** — how the skill is structured (sections, frontmatter, instruction
  style, level of detail)
- **Reference depth** — how thorough the references are, how they support the skill
- **Example quality** — whether examples exist and how they demonstrate usage

Merge these reports into a **pattern profile** — a short description of what a complete,
high-quality skill implementation looks like in this repo. This profile is passed to every
Step 2 subagent so they can assess implementation quality, not just existence.

### 1. Catalog the Specification

Use up to 250 parallel subagents to read ALL files in the `grimoire/grimoire/` directory tree.
Spawn one subagent per spec file. Each subagent reads its assigned file and extracts every
distinct item described in it, returning a structured list.

Each item in a subagent's output must have:
- **id** — a short slug (e.g. `skill:cartography`, `agent:familiar`, `concept:backpressure`,
  `infra:directory-structure`)
- **type** — one of: skill, agent, concept, infrastructure
- **name** — human-readable name
- **spec_files** — which `grimoire/grimoire/` files describe this item (absolute paths)
- **summary** — 1-2 sentence description of what the spec says this item should do
- **dependencies** — other items this depends on or collaborates with
- **spec_detail** — one of: `detailed` (enough to implement), `partial` (some detail, some
  gaps), `sketch` (mentioned but too vague to implement directly)

One subagent should specifically handle `grimoire/grimoire/notes.md` for roadmap items. Items
only mentioned in notes.md without their own spec file should be marked as `sketch` detail level.

Important: every skill, agent, concept, and piece of infrastructure described gets its own
entry. If a single file describes multiple items (e.g. `scribe.md` describes both the scribe
skill and sub-skills like distill, gc, indexing), each gets a separate entry.

After all subagents complete, merge their results into a single deduplicated flat list. If
multiple subagents report the same item (e.g. referenced across files), merge their spec_files
lists and keep the most detailed summary.

Return ONLY the structured list, not prose.

### 2. Spawn Per-Item Analysis Subagents

For EACH item returned in step 1, spawn a separate subagent. Launch all subagents in
parallel.

Each subagent receives:
- The item's id, type, name, summary, dependencies, spec_detail, and spec_files from the
  catalog
- The task of determining implementation status
- The paths section from this skill (so it knows where to look)

Each subagent must:

1. **Read the spec** — Read the spec_files listed for this item to understand what's
   specified. This intentional re-read ensures each subagent has full isolated context.

2. **Search the implementation** — Search the plugin codebase OUTSIDE `grimoire/grimoire/`
   for corresponding implementation. Specifically:
   - For **skills**: look in `grimoire/skills/*/SKILL.md`, check for matching `references/`,
     `examples/`, `scripts/` directories within each skill
   - For **agents**: look for agent definitions, prompt templates, or agent-spawning logic
     anywhere in `grimoire/skills/` (agents may be invoked from within skill instructions)
   - For **concepts**: check whether the concept is actively referenced or enforced in
     implemented skill/agent instructions. A concept is "implemented" when skills or agents
     incorporate its principles in their instructions (e.g. backpressure is implemented if
     skills instruct agents to produce verifiable artifacts; trivial verifiability is
     implemented if skills guide question framing). Search for keywords in SKILL.md files.
   - For **infrastructure**: check whether the described directory structures, file formats,
     cross-linking conventions, or tooling integrations actually exist. Look at
     `grimoire/.claude-plugin/plugin.json`, `grimoire/marker-groups/`, scripts, and the
     directory layout of implemented skills.
   - Also check `grimoire/README.md` for what's described as shipped.

3. **Scan for implementation debt** — In every implementation file found, grep for `TODO`,
   `FIXME`, `PLACEHOLDER`, `STUB`, `HACK`, and `XXX`. Note any hits. Also check whether the
   skill has `references/`, `examples/`, and `scripts/` directories — compare against the
   pattern profile from Step 0.5 to flag missing structure that peer skills have.

4. **Classify the gap** — Return a structured report with:
   - **id** — the item id from the catalog
   - **spec_detail** — carried forward from the catalog (do NOT re-determine this)
   - **status** — one of:
     - `implemented` — a corresponding feature exists and covers the spec
     - `partial` — something exists but is missing described behaviors
     - `shallow` — implementation exists but lacks supporting structure (references, examples,
       scripts) that peer skills have, OR contains significant TODOs/placeholders
     - `stale` — implementation exists but doesn't match the current spec (spec has evolved
       past what was built)
     - `not_implemented` — described in spec but nothing corresponding in the plugin
   - **evidence** — which implementation files were found (or "none found")
   - **debt** — any TODO/FIXME/PLACEHOLDER markers found, and any structural gaps compared
     to the pattern profile (e.g. "no references/ directory", "no examples/", "3 TODOs in
     SKILL.md")
   - **missing** — for `partial`/`shallow`/`stale` items: specific behaviors/features
     described in spec but absent from implementation. For `not_implemented`: what would
     need to be built.
   - **tasks** — a list of specific, actionable tasks needed to bring the implementation
     fully in line with the spec. This applies to ALL statuses including `implemented` —
     even a fully implemented skill may have tasks if the spec describes behaviors or
     features not yet covered. Each task should be concrete enough to act on (e.g. "add
     reference doc for reentrancy patterns" not "improve references"). Items with no
     remaining work should have an empty tasks list.
   - **notes** — any relevant observations (e.g. "spec mentions codeql but no codeql
     integration exists anywhere in the plugin")

Note: `spec_detail` of `sketch` does not change the status classification. A sketch-level
item can still be `not_implemented`. The distinction matters in step 4 where sketch items
are deprioritized for recommendation.

Each subagent should be thorough but focused only on its single item. It should NOT attempt
to analyze other items.

### 3. Collect and Assemble

Collect all subagent reports. Assemble them into a gap summary table with columns:
- Item (id + name)
- Type
- Spec Detail
- Status
- Tasks (count of remaining tasks)
- Debt (TODO count, missing structure)
- Key gaps / notes

### 4. Prioritize

Sort all items that have remaining tasks into a prioritized implementation order. This includes
`not_implemented`, `partial`, `shallow`, `stale`, and `implemented` items with non-empty task
lists. Items with spec_detail `sketch` go in a separate unprioritized bucket — they need spec
work before they can be planned.

For the remaining items, evaluate and sort by:

1. **Clarity** — Is the spec detailed enough to implement without guessing? Prefer items
   where the grimoire/ spec clearly describes what the skill/agent should do.

2. **Impact** — Does this unlock other features or fill a critical gap in the workflow?
   Consider dependencies: if skill A depends on agent B, implementing B first has higher
   leverage.

3. **Implementability** — Can this be built as a skill/agent within the current plugin
   architecture? Prefer tasks that fit the existing patterns (SKILL.md + references/ +
   examples/).

4. **Independence** — Can this be implemented without requiring other unimplemented features
   first?

### 5. Present Results

Show the user:

1. **Gap summary table** — all items, sorted by status (not_implemented first, then stale,
   then partial, then shallow, then implemented), with spec_detail and debt columns visible
   so sketch items and implementation debt are clearly marked
2. **Prioritized implementation plan** — the ordered list from step 4, with a brief
   rationale for the top 3 items explaining why they rank highest
3. **Spec gaps** — for every item with spec_detail `sketch` or `partial`, list specific
   questions whose answers would make the item implementable. Frame these as actionable
   prompts for the spec author (e.g. "cartography: what output format should the map use?
   what level of detail per node?"). This is more useful than a generic "Needs Spec Work"
   label.

Keep the output scannable. Use tables and bullet points, not paragraphs.

### 6. Update Implementation Plan

Create or update `IMPLEMENTATION_PLAN.md` at the repo root (`grimoire/IMPLEMENTATION_PLAN.md`).

The plan is a prioritized bullet point list of items with remaining work, sorted by priority
(highest first). Each entry should include:
- The item id and name
- Current status
- The specific tasks identified for this item
- Dependencies on other items, if any
- Spec detail level (`detailed`, `partial`, or `sketch`)

Items with status `implemented` that have NO remaining tasks should be listed in a separate
"Completed" section at the bottom so progress is visible.

Items with status `implemented` that DO have remaining tasks (spec describes features or
behaviors not yet covered by the implementation) should appear in the main prioritized list
with their tasks clearly described. An implemented skill can still have work to do.

Items with spec_detail `sketch` should be listed in a "Needs Spec Work" section with the
specific questions from Step 5's spec gaps output — not just "needs spec work" but the actual
questions that need answers before implementation can begin.

Items with status `shallow` should be listed in an "Implementation Debt" section — they work
but need structural improvements (missing references, examples, or contain TODOs).

If an existing `IMPLEMENTATION_PLAN.md` was read in step 0, preserve any human-added notes or
context that still applies. Do not discard information that isn't contradicted by the fresh
analysis.

The plan should be concise and actionable — someone reading it should immediately understand what
to work on next and why.
