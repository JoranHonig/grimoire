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
user_invocable: true
---

# Cartography

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
and trace the flow from there. Read the seeded files, identify callees, follow the execution
path.

**Unseeded exploration** — the user describes a flow but doesn't point to specific files (e.g.,
"map how secrets are retrieved"). Spawn subagents to search for relevant code:
- One subagent per likely search term (function names, module names, keywords from the flow
  description)
- Subagents should search for entry points, handlers, and key symbols related to the flow
- Collect results and identify the most relevant files

In both modes, gather:
- **Entry points** — where execution begins for this flow (endpoints, handlers, CLI commands)
- **Key components** — modules and files that participate, with a one-line role description
- **Flow sequence** — numbered steps tracing execution through the system, with file references
- **Security notes** — trust boundaries, validation gaps, TOCTOU windows, crypto observations,
  anything security-relevant

Use subagents to parallelize exploration. Keep the main context focused on assembling the map
rather than reading every file in detail.

Consult `references/cartography-format.md` for the exact format specification and
`examples/cartography-example.md` for a worked example.

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
7. **Conditional sections** — if the flow has independent sub-flows that would pollute context
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

## Guidelines

- **Subagents for exploration.** Use subagents to search for relevant code in parallel. This
  keeps the main context clean and speeds up discovery.
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
