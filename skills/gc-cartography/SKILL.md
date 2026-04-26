---
name: gc-cartography
description: >-
  This skill should be used when the user says "clean up flows",
  "merge flows", "gc cartography", "garbage collect flows",
  "deduplicate flows", "consolidate cartography", "too many flow files",
  "overlapping flows", "duplicate cartography", "reduce flow count",
  or wants to identify and merge overlapping cartography files, remove
  stale references, and reduce duplication in the grimoire/cartography/
  directory.
---

# GC Cartography

## Codex Execution Note

Only use Codex workers when the user explicitly asks for delegation or parallel agent work. Otherwise, run the same workflow locally with focused `rg` searches, batched file reads, and concise checkpoints.


Identify overlapping or duplicated cartography files, merge them where appropriate, and clean
up stale cross-references. Garbage collection for your flow maps.

## Philosophy

**Cartography files accumulate.** As a security engagement progresses, researchers map flows
independently. Over time this creates overlap — two files documenting slightly different views
of the same flow, or three files that share most of their components. This bloat degrades agent
performance by splitting context across multiple files. GC consolidates without losing signal.

## Workflow

When this skill is activated, create a todo list from the following steps. Mark each task
in_progress before starting it and completed when done.

```
- [ ] 1. Inventory all flows — run index, read all files, track referenced paths per flow
- [ ] 2. Detect overlap — compare component sets, flag pairs with significant overlap
- [ ] 3. Propose merge plan — present candidates to user with rationale
- [ ] 4. Execute merges — combine files, deduplicate, create conditional sections
- [ ] 5. Clean up cross-references — fix stale links in all files
- [ ] 6. Update index — re-run script, present before/after summary
```

---

### 1. Inventory All Flows

Run the indexing script:

```bash
bash skills/cartography/scripts/index-cartography.sh grimoire/cartography/
```

Read every cartography file in `grimoire/cartography/`. For each file, extract:
- The `name` and `description` from frontmatter
- The list of file paths referenced in Entry Points, Key Components, and Flow Sequence
- The `related` and `tags` fields from frontmatter

Build an in-memory map of flow → referenced file paths.

### 2. Detect Overlap

Run `scripts/gc-cartography/scripts/detect-overlaps.sh` or compare manually. Consult
`references/overlap-metrics.md` for the overlap formula and tier thresholds.

Flag pairs that meet any of these criteria:

- **Component overlap >40%** — more than 40% of one flow's referenced file paths also appear
  in the other flow
- **Similar descriptions** — descriptions that describe the same activity in different words
- **Subset flows** — one flow's components are entirely contained within another flow's
  components

For each flagged pair, note:
- Which files are shared vs unique to each flow
- Whether the flows represent the same activity from different angles, or genuinely different
  activities that happen to share infrastructure

### 3. Propose Merge Plan

Consult `references/merge-decisions.md` for the merge-vs-keep decision framework.

Present merge candidates to the user. For each candidate pair:
- Show both flow names and descriptions
- Show the overlap percentage and shared components
- Explain why merging makes sense (or flag if it's ambiguous)
- Suggest which flow should be the primary (keep its filename) and which should be absorbed

**Never auto-merge.** Always present the plan and wait for user approval. The user may have
reasons to keep flows separate that aren't apparent from the file contents alone.

If no overlaps are detected, report a clean bill of health and skip to step 6.

### 4. Execute Merges

For each approved merge:

1. **Combine frontmatter** — keep the primary flow's `name`. Merge `tags` (union). Merge
   `related` (union, removing references to the absorbed flow). Update `description` if the
   merged flow's scope has broadened. Set `updated` to today's date.

2. **Merge Entry Points** — union of both flows' entry points, deduplicated.

3. **Merge Key Components** — union of both flows' components. Where both flows list the same
   file, keep the more descriptive role annotation.

4. **Merge Flow Sequence** — this is the hardest part. If both flows describe the same sequence
   with minor variations, unify into one sequence. If they describe genuinely different paths
   through shared components, keep the primary flow's sequence as the main body and move the
   absorbed flow's sequence into a conditional section.

5. **Merge Security Notes** — union of all security notes. Preserve every note from both files.
   Deduplicate only when two notes say exactly the same thing.

6. **Unique content becomes conditional** — any content from the absorbed flow that doesn't
   fit naturally into the primary flow's main body should become a conditional section.

7. **Delete the absorbed flow's file** after confirming the merge is correct.

Consult `skills/cartography/references/cartography-format.md` for format details.

### 5. Clean Up Cross-References

After merges, scan all remaining cartography files for stale references:

- Find `[[cartography/...]]` links that point to deleted files
- Update them to point to the merged flow's file
- Check `related` fields in frontmatter for deleted slugs and update them
- Ensure all `related` references are reciprocal

Also check `GRIMOIRE.md` and files in `grimoire/tomes/` for stale cartography links.

### 6. Update Index

Re-run the indexing script:

```bash
bash skills/cartography/scripts/index-cartography.sh grimoire/cartography/
```

Present to the user:
- **Before:** number of flows, list of names
- **After:** number of flows, list of names
- Which flows were merged and which were kept
- Any stale references that were fixed

Suggest [[review-cartography]] to verify the merged flows are accurate and complete.

---

## Guidelines

- **Never auto-merge.** Always present the plan and get user approval. Merging destroys
  information if done carelessly.
- **Preserve all security notes.** When merging, keep every security observation from both
  files. Security notes are the highest-value content in a cartography file.
- **Use conditional sections for divergent paths.** When two flows share entry points and
  components but diverge in their sequences, use conditional sections rather than trying to
  force them into one linear sequence.
- **Check beyond cartography/.** Stale `[[cartography/...]]` links can appear in GRIMOIRE.md,
  tomes, and other documents. Clean them all up.
- **Overlap is not always bad.** Two flows might legitimately share 50% of their components
  and still be better as separate files. Respect the user's judgment on what to merge.
