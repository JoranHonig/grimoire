---
name: cartography
description: >-
  This skill should be used when the user says "build context on a flow",
  "trace a flow", "map how X works", "cartography", "/cartography",
  "document a flow", "create a flow map", "trace how authentication works",
  "map the data flow", or wants to explore and document how a specific
  code flow works so that context can be quickly rebuilt on future visits.
  This is the primary skill for creating cartography files in
  grimoire/cartography/.
---

# Cartography

## Codex Execution Note

Only use Codex workers when the user explicitly asks for delegation or parallel agent work. Otherwise, run the same workflow locally with focused `rg` searches, batched file reads, and concise checkpoints.


Explore a code flow, document which parts of the codebase are relevant, and create a cartography
file so context can be rebuilt quickly on future visits.

## Philosophy

**Context is expensive to build and cheap to store.** Security researchers repeatedly need to
understand the same flows — authentication, data pipelines, permission checks. Building this
context from scratch each time wastes tokens and time. Cartography files are lightweight pointers
that document *where* to look, not *what the code does*. They enable any agent to rebuild flow
context in seconds instead of minutes.

## Workflow

When this skill is activated, create a todo list from the following steps. Mark each task
in_progress before starting it and completed when done.

```
- [ ] 1. Verify infrastructure — confirm grimoire/cartography/ exists
- [ ] 2. Check index for existing flows — run index script, present matches
- [ ] 3. Explore the flow — discover entry points, components, sequence, security notes
- [ ] 4. Document the flow — create cartography file following format spec
- [ ] 5. Update index — re-run index script, verify new flow appears
- [ ] 6. Present to user — summary and suggest follow-up skills
```

---

### 1. Verify Infrastructure

Check that the `grimoire/` directory and `grimoire/cartography/` subdirectory exist.

- If `grimoire/cartography/` exists, proceed.
- If `grimoire/` exists but `cartography/` does not, create `grimoire/cartography/`.
- If `grimoire/` does not exist, warn the user that Grimoire has not been summoned on this
  codebase. Suggest running [[summon]] first to set up the workspace. If the user wants to
  proceed anyway, create both `grimoire/` and `grimoire/cartography/`.

### 2. Check Index for Existing Flows

Run the indexing script to see what flows already exist:

```bash
bash skills/cartography/scripts/index-cartography.sh grimoire/cartography/
```

If the index returns results:
- Present the list to the user.
- Check whether any existing flow matches or overlaps with what the user is asking about.
- If a match exists, offer to load that flow's context instead of creating a new one. If the
  user wants to refine an existing flow, suggest [[review-cartography]] instead.

If the index is empty or the user's flow is new, proceed to exploration.

### 3. Explore the Flow

There are two exploration modes depending on what the user provides:

**Seeded exploration** — the user provides starting files or hints (e.g., "trace how
authentication works starting from `gateway/src/middleware/auth.ts`"). Use these as entry points
and trace the flow by following the callgraph:

1. Read the seeded files carefully
2. Identify all function/method calls made from the entry point
3. For each callee, open its definition and repeat — follow the callgraph depth-first along the
   flow's execution path
4. At each hop, note: the file, the symbol, and its role in the flow (one line)
5. Stop when you reach leaf functions (no further relevant calls), external service boundaries,
   or when the flow loops back to already-visited code
6. Use helper passes for branches — if the callgraph forks into independent paths (e.g., an async
   side-effect vs. the main return path), trace each branch as a separate pass; delegate only if
   explicitly authorized

Use `path/to/file:symbol` notation to track each hop. This directly becomes the Flow Sequence
and Key Components in the cartography file.

**Unseeded exploration** — the user describes a flow but doesn't point to specific files (e.g.,
"map how secrets are retrieved"). Run a broad search fan-out:

1. Study the user's flow description. Ask clarifying questions if the scope is ambiguous.
2. Generate search queries — brainstorm function names, module names, class names, route
   patterns, config keys, error messages, log strings, and domain-specific keywords related to
   the flow. Aim for broad coverage; breadth matters more than precision at this stage.
3. Run searches in parallel where practical. Each helper pass gets one search query and should:
   - Search for the term across the codebase (file names, symbols, content)
   - For each match, read enough context to assess relevance (a few lines around the match)
   - Return: file path, symbol, one-line relevance assessment, confidence (high/medium/low)
4. Collect all results. Deduplicate by file. Rank by frequency (files appearing in multiple
   helper pass results are more likely to be core to the flow) and confidence.
5. From the top-ranked files, switch to **callgraph-following** (as in seeded mode) to trace the
   actual execution path and build the flow sequence.

The fan-out casts a wide net; the callgraph pass refines it into a coherent flow. Don't skip
step 5 — a bag of search results is not a flow map.

In both modes, gather:
- **Entry points** — where execution begins for this flow (endpoints, handlers, CLI commands)
- **Key components** — modules and files that participate, with a one-line role description
- **Flow sequence** — numbered steps tracing execution through the system, with file references
- **Security notes** — trust boundaries, validation gaps, TOCTOU windows, crypto observations,
  anything security-relevant

Use helper passes to partition exploration. Keep the main context focused on assembling the map
rather than reading every file in detail; use Codex workers only when explicitly authorized.

Consult `references/cartography-format.md` for the exact format specification and the examples:
- `examples/cartography-example.md` — single-service flow, one conditional section
- `examples/cross-service-auth-example.md` — cross-service flow, multiple conditionals

### 4. Document the Flow

Create a cartography file at `grimoire/cartography/<slug>.md` where `<slug>` is a URL-friendly
version of the flow name (lowercase, hyphens, no spaces).

The file must follow the format defined in `references/cartography-format.md`:

1. **Frontmatter** — `name`, `description`, `created`, `updated`, `tags`, `related`
2. **Overview** — 2-3 sentences, security relevance
3. **Entry Points** — `path/to/file:symbol` notation
4. **Key Components** — files with one-line role descriptions
5. **Flow Sequence** — numbered steps with file references
6. **Security Notes** — trust boundaries, gaps, observations
7. **Conditional sections** — for sub-flows that are independently useful but would pollute
   context if always loaded. Use when: the main body exceeds ~80 lines, or a sub-flow is only
   relevant for specific investigations. Write the `<!-- condition: ... -->` comment as a
   concrete, matchable topic description — a Codex session reads this comment and decides whether to
   load the section based on the user's current question. **Load** when the user's question
   directly matches the condition topic. **Skip** when the user is focused on the main flow and
   the conditional topic hasn't been mentioned.
8. **Related Flows** — cross-links to other cartography files

**Key constraint:** the file documents *where* to look, not *what the code does*. If you find
yourself writing detailed code explanations, stop. Add the file path and a one-line role
description instead.

Set `created` and `updated` to today's date.

### 5. Update Index

Re-run the indexing script:

```bash
bash skills/cartography/scripts/index-cartography.sh grimoire/cartography/
```

Verify the new flow appears in the output. If it doesn't, check that the frontmatter has
valid `name` and `description` fields on single lines.

### 6. Present to User

Show the user:
- A summary of the flow that was documented
- The file path where the cartography file was created
- The entry points and key components discovered
- Any security notes worth highlighting

Suggest follow-up actions:
- **[[review-cartography]]** — to verify and refine the flow against the actual codebase
- **[[gc-cartography]]** — if there are many flows, to clean up overlap and duplication

---

## Context Rebuild

Cartography files exist so that Codex sessions do not repeat expensive exploration. When a Codex session needs
to understand a flow that has already been mapped, it should **rebuild context from the
cartography file** rather than re-exploring from scratch:

1. **Load the cartography file** — read the frontmatter, overview, and entry points to confirm
   this is the right flow.
2. **Evaluate conditional sections** — read each `<!-- condition: ... -->` comment. If the
   user's current question matches the condition topic, load that section. If not, skip it.
   When in doubt, skip — loading unnecessary conditionals wastes context.
3. **Open the referenced files** — use the Key Components and Flow Sequence as a reading list.
   Open these files in the order the flow sequence specifies. This is where actual understanding
   is built — the cartography file is the map, the source files are the territory.
4. **Check freshness** — if the `updated` date is old or the referenced files have changed
   significantly since the cartography file was written, the map may be stale. Consider running
   [[review-cartography]] to update it before relying on it.
5. **Follow cross-links** — if the investigation touches Related Flows, load those cartography
   files too (repeating steps 1-3 for each).

An agent that follows this process gets to a working understanding of the flow in seconds,
using tokens only on reading source files rather than searching for them.

---

## Guidelines

- **Helper passes for exploration.** Use helper passes to search for relevant code. This keeps
  the main context clean and speeds up discovery.
- **Pointers, not content.** Cartography files should never contain code snippets or detailed
  logic explanations. They are navigation maps.
- **One flow per file.** Don't combine unrelated flows. Use the `related` field and
  `[[cartography/...]]` links to connect them.
- **Conditional sections for complexity.** If a flow has sub-paths that are only sometimes
  relevant (e.g., shared vault access within a general retrieval flow), use conditional sections
  to keep the main flow lean.
- **Security lens.** Every flow should have security notes. If you can't think of any, you
  haven't looked hard enough. Trust boundaries, validation gaps, and crypto operations are
  always worth noting.
- **Check existing flows first.** Always run the index before creating a new file. Duplicate
  flows create confusion and get in each other's way.
