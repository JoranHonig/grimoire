---
description: >-
  Identify gaps between the grimoire specification and the actual plugin
  implementation. Build or update a prioritized implementation plan.
---

# /gap-analysis

Compare the grimoire specification against the current plugin implementation to find gaps,
then build or update a prioritized implementation plan.

## Codex Delegation Note

Only use Codex workers when the user explicitly asks for delegation or parallel agent work.
Otherwise, perform the same steps locally with focused `rg` searches, batched file reads, and
item-by-item notes.

## Important Constraints

- The specification lives in the `grimoire/grimoire/` directory. These files are written by a
  human and are the source of truth.
- The implementation lives in everything else at the repo root (`skills/`, `marker-groups/`,
  `.codex-plugin/`, `README.md`, etc.) — everything outside `grimoire/grimoire/`.
- The solution is NEVER to change the specification. Always extend or update the plugin.
- Use local batching to keep context clean; delegate only when explicitly authorized.

## Helper Passes

When delegation is explicitly authorized, helper passes need the following Codex-native scopes:
- **Step 0.5 helper passes** (pattern learning): read mature skill directories and summarize structure.
- **Step 1 helper passes** (catalog): read assigned spec files and search related references.
- **Step 2 helper passes** (analysis): search with `rg` and inspect implementation files for each item.
- **Step 6** (update plan): update `IMPLEMENTATION_PLAN.md`.

When working locally, treat this list as the file-read/search scope for each pass.

## Paths

Anchor all file references to the repo root at `grimoire/` (the git repository root, NOT
`grimoire/grimoire/`).

- **Spec directory:** `grimoire/grimoire/` — contains subdirectories `skills/`, `agents/`,
  `concepts/`, and files like `README.md`, `notes.md`
- **Implementation root:** `grimoire/` — contains `skills/`, `marker-groups/`,
  `.codex-plugin/plugin.json`, `README.md`
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
well-built skill looks like in this plugin. Run 2-3 helper passes in parallel when authorized, one per skill
directory (pick skills with the most files in `grimoire/skills/`). Each helper pass reads the
full skill directory and reports:

- **Directory structure** — what subdirectories exist (references/, examples/, scripts/)
- **SKILL.md conventions** — how the skill is structured (sections, frontmatter, instruction
  style, level of detail)
- **Reference depth** — how thorough the references are, how they support the skill
- **Example quality** — whether examples exist and how they demonstrate usage

Merge these reports into a **pattern profile** — a short description of what a complete,
high-quality skill implementation looks like in this repo. This profile is passed to every
Step 2 helper pass so they can assess implementation quality, not just existence.

### 1. Catalog the Specification

Use up to 250 parallel helper passes to read ALL files in the `grimoire/grimoire/` directory tree.
Assign one helper pass per spec file when authorized; otherwise process files in batches. Each pass reads its assigned file and extracts every
distinct item described in it, returning a structured list.

There are two categories of spec items with fundamentally different roles:

**Implementable items** (skills, agents, infrastructure) — things that get built as discrete
components in the plugin. Each has a corresponding implementation artifact.

**Cross-cutting items** (concepts, flows) — these do NOT map to discrete implementations.
Concepts describe principles and aspects that should be woven into multiple skills/agents
(e.g. backpressure isn't a skill to build — it's a principle skills should embody). Flows
describe activities showing how agents/skills interact (e.g. autonomous discovery isn't a
feature — it's a process description of how sigil, familiar, librarian, etc. collaborate).

#### Implementable items

Each implementable item in a helper pass's output must have:
- **id** — a short slug (e.g. `skill:cartography`, `agent:familiar`, `infra:directory-structure`)
- **type** — one of: skill, agent, infrastructure
- **name** — human-readable name
- **spec_files** — which `grimoire/grimoire/` files describe this item (absolute paths)
- **summary** — 1-2 sentence description of what the spec says this item should do
- **dependencies** — other items this depends on or collaborates with
- **spec_detail** — one of: `detailed` (enough to implement), `partial` (some detail, some
  gaps), `sketch` (mentioned but too vague to implement directly)

#### Cross-cutting items

Each concept or flow in a helper pass's output must have:
- **id** — a short slug (e.g. `concept:backpressure`, `flow:autonomous-discovery`)
- **type** — one of: concept, flow
- **name** — human-readable name
- **spec_files** — which `grimoire/grimoire/` files describe this item (absolute paths)
- **summary** — what this concept prescribes or what this flow describes
- **touches** — which implementable items (skills/agents) should reflect this concept or
  participate in this flow

One helper pass should specifically handle `grimoire/grimoire/ideas/` for roadmap items. Items
only mentioned in ideas/ without their own spec file should be marked as `sketch` detail level.

Important: every skill, agent, concept, flow, and piece of infrastructure described gets its
own entry. If a single file describes multiple items (e.g. `scribe.md` describes both the
scribe skill and sub-skills like distill, gc, indexing), each gets a separate entry.

After all helper passes complete, merge their results into two deduplicated lists: one for
implementable items, one for cross-cutting items. If multiple helper passes report the same item
(e.g. referenced across files), merge their spec_files lists and keep the most detailed summary.

Return ONLY the structured lists, not prose.

### 2. Run Per-Item Analysis Passes

Launch two groups of helper passes in parallel: one for implementable items, one for cross-cutting
items.

#### 2a. Implementable Item Subagents

For EACH implementable item (skills, agents, infrastructure) returned in step 1, run a
separate helper pass. Launch all helper passes in parallel.

Each helper pass receives:
- The item's id, type, name, summary, dependencies, spec_detail, and spec_files from the
  catalog
- The task of determining implementation status
- The paths section from this skill (so it knows where to look)

Each helper pass must:

1. **Read the spec** — Read the spec_files listed for this item to understand what's
   specified. This intentional re-read ensures each helper pass has full isolated context.

2. **Search the implementation** — Search the plugin codebase OUTSIDE `grimoire/grimoire/`
   for corresponding implementation. Specifically:
   - For **skills**: look in `grimoire/skills/*/SKILL.md`, check for matching `references/`,
     `examples/`, `scripts/` directories within each skill
   - For **agents**: look for agent definitions, prompt templates, or delegation logic
     anywhere in `grimoire/skills/` (agents may be invoked from within skill instructions)
   - For **infrastructure**: check whether the described directory structures, file formats,
     cross-linking conventions, or tooling integrations actually exist. Look at
    `grimoire/.codex-plugin/plugin.json`, `grimoire/marker-groups/`, scripts, and the
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

Each helper pass should be thorough but focused only on its single item. It should NOT attempt
to analyze other items.

#### 2b. Cross-Cutting Item Subagents

For EACH concept and flow from step 1, run a separate helper pass. Launch in parallel only when authorized.

Concepts and flows do NOT have their own implementation — they describe principles and
activities that should be reflected across skills and agents. The goal is to assess
**adoption**, not existence.

Each helper pass receives:
- The item's id, type, name, summary, spec_files, and touches list from the catalog
- The full list of implementable items (so it knows what exists)
- The paths section from this skill

Each helper pass must:

1. **Read the spec** — Read the spec_files to understand what the concept prescribes or
   what the flow describes.

2. **Assess adoption** — For each implementable item in the touches list that is actually
   implemented, check whether the implementation reflects the concept or supports the flow:
   - For **concepts**: search SKILL.md files and agent definitions for evidence that the
     principle is incorporated. For example, backpressure is adopted if skills instruct
     agents to produce verifiable artifacts; "don't get in the way" is adopted if skills
     are minimal and let the model work.
   - For **flows**: check whether the participating agents/skills exist and whether their
     implementations describe the interactions the flow specifies. A flow is supported when
     its participants exist and their instructions reference or enable the described activity
     sequence.

3. **Return an adoption report** with:
   - **id** — the item id
   - **adoption** — one of:
     - `adopted` — the principle/activity is well-reflected across relevant implementations
     - `partially_adopted` — some implementations reflect it, others don't
     - `not_adopted` — the principle/activity is not reflected in implementations
     - `blocked` — the implementations it touches don't exist yet, so adoption can't be
       assessed
   - **evidence** — which implementations reflect (or fail to reflect) this item, with
     specific references
   - **gaps** — where adoption is missing: which skills/agents should reflect this concept
     or support this flow but don't
   - **recommendations** — concrete suggestions for improving adoption in existing or
     planned implementations (e.g. "add backpressure guidance to write-poc phase 3",
     "cartography should reference context building principles")

### 3. Collect and Assemble

Collect all helper pass reports. Assemble two separate outputs:

**Implementable items table** with columns:
- Item (id + name)
- Type
- Spec Detail
- Status
- Tasks (count of remaining tasks)
- Debt (TODO count, missing structure)
- Key gaps / notes

**Cross-cutting adoption table** with columns:
- Item (id + name)
- Type (concept / flow)
- Adoption (adopted / partially_adopted / not_adopted / blocked)
- Gaps (which skills/agents are missing adoption)
- Key recommendations

### 4. Prioritize

Sort all implementable items that have remaining tasks into a prioritized implementation
order. This includes `not_implemented`, `partial`, `shallow`, `stale`, and `implemented`
items with non-empty task lists. Items with spec_detail `sketch` go in a separate
unprioritized bucket — they need spec work before they can be planned.

For the remaining items, apply a two-level sort:

**First: sort by item type tier.** Skills and agents always come before flows, and flows
always come before concepts. This reflects that concrete, buildable components are more
actionable than workflow descriptions, which in turn are more actionable than design
principles. Infrastructure items are sorted alongside the tier of their closest dependency
(e.g. infrastructure supporting a skill sorts with skills).

**Second: within each tier, sort by:**

1. **Clarity** — Is the spec detailed enough to implement without guessing? Prefer items
   where the grimoire/ spec clearly describes what the skill/agent should do.

2. **Impact** — Does this unlock other features or fill a critical gap in the workflow?
   Consider dependencies: if skill A depends on agent B, implementing B first has higher
   leverage. Also consider cross-cutting adoption: if implementing agent X would unblock
   adoption of concept Y across multiple skills, that increases X's impact.

3. **Implementability** — Can this be built as a skill/agent within the current plugin
   architecture? Prefer tasks that fit the existing patterns (SKILL.md + references/ +
   examples/).

4. **Independence** — Can this be implemented without requiring other unimplemented features
   first?

Cross-cutting items (concepts and flows) that have remaining adoption tasks ARE included in
the priority queue, but always after all skills/agents (and after flows, for concepts). Their
adoption recommendations should also be folded into the tasks of the implementable items they
touch. For example, if concept:backpressure recommends "add backpressure guidance to write-poc
phase 3", that becomes BOTH a task on skill:write-poc AND appears as a standalone entry in the
concept tier of the priority queue.

### 5. Present Results

Show the user:

1. **Implementable items table** — all skills, agents, and infrastructure, sorted by status
   (not_implemented first, then stale, then partial, then shallow, then implemented), with
   spec_detail and debt columns visible so sketch items and implementation debt are clearly
   marked
2. **Cross-cutting adoption table** — all concepts and flows with their adoption status,
   gaps, and key recommendations
3. **Prioritized implementation plan** — the ordered list from step 4 (implementable items
   only), with a brief rationale for the top 3 items explaining why they rank highest.
   Cross-cutting adoption recommendations should be visible as tasks on the relevant
   implementable items.
4. **Spec gaps** — for every implementable item with spec_detail `sketch` or `partial`, list
   specific questions whose answers would make the item implementable. Frame these as
   actionable prompts for the spec author (e.g. "cartography: what output format should the
   map use? what level of detail per node?"). This is more useful than a generic "Needs Spec
   Work" label.

Keep the output scannable. Use tables and bullet points, not paragraphs.

### 6. Update Implementation Plan

Create or update `IMPLEMENTATION_PLAN.md` at the repo root (`grimoire/IMPLEMENTATION_PLAN.md`).

The plan has the following sections:

#### Priority Queue

A prioritized bullet point list of implementable items with remaining work, sorted by priority
(highest first). Each entry should include:
- The item id and name
- Current status
- The specific tasks identified for this item (including any cross-cutting adoption tasks
  folded in from concepts/flows that touch this item)
- Dependencies on other items, if any
- Spec detail level (`detailed`, `partial`, or `sketch`)

Items with status `implemented` that DO have remaining tasks (spec describes features or
behaviors not yet covered by the implementation) should appear here with their tasks clearly
described. An implemented skill can still have work to do.

#### Cross-Cutting Adoption

A summary of concepts and flows with their adoption status. For each:
- The item id and name
- Adoption status (adopted / partially_adopted / not_adopted / blocked)
- Which implementable items it touches
- Specific recommendations for improving adoption

This section is informational — it tracks whether the plugin's design principles and intended
workflows are reflected in the implementation. Recommendations from this section are folded
into the tasks of implementable items in the Priority Queue.

#### Implementation Debt

Items with status `shallow` — they work but need structural improvements (missing references,
examples, or contain TODOs).

#### Needs Spec Work

Items with spec_detail `sketch` — listed with the specific questions from Step 5's spec gaps
output. Not just "needs spec work" but the actual questions that need answers before
implementation can begin.

#### Completed

Items with status `implemented` that have NO remaining tasks. Listed so progress is visible.

---

If an existing `IMPLEMENTATION_PLAN.md` was read in step 0, preserve any human-added notes or
context that still applies. Do not discard information that isn't contradicted by the fresh
analysis.

The plan should be concise and actionable — someone reading it should immediately understand what
to work on next and why.
