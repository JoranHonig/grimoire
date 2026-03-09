---
name: Finding Dedup
description: >-
  This skill should be used when the user says "deduplicate findings", "dedup findings",
  "compare findings", "find duplicate findings", "merge findings", "clean up findings",
  "/finding-dedup", or wants to identify and resolve duplicate or overlapping security
  findings in a project. Classifies finding pairs as duplicate (can delete one) or similar
  (different scope, may merge). This skill is NOT for drafting new findings (use
  /finding-draft) or reviewing individual findings (use /finding-review).
user_invocable: true
---

# Finding Dedup

Identify and resolve duplicate or overlapping security findings — keeping the finding set
clean without losing information.

## Philosophy

During an audit, it is common to document the same issue from different angles, or to find
overlapping vulnerabilities that could be consolidated. This skill systematically compares
all findings and classifies them into two categories:

- **Duplicate** — identical root cause, same component, same impact. One can be deleted
  without losing any information.
- **Similar** — overlapping root cause or component but different scope or impact. Cannot
  delete without information loss. May benefit from merging or cross-referencing.

The researcher always decides. This skill proposes actions but never deletes or merges
without explicit confirmation.

## Workflow

When this skill is activated, create a todo list from the following steps. Mark each task
in_progress before starting it and completed when done.

```
- [ ] 1. Index and compare findings
- [ ] 2. Present duplicates and confirm actions
- [ ] 3. Execute and report
```

---

### 1. Index and Compare Findings

Run the indexing script to get the full finding set:
```bash
bash skills/finding/scripts/index-findings.sh
```

If fewer than 2 findings exist, report that there is nothing to deduplicate and stop.

For each pair of findings, compare title, type, context (affected files), and description.
Classify each pair as:

- **Duplicate** — same root cause, same affected component, same impact. One can be deleted
  without losing information.
- **Similar** — overlapping root cause or component but different scope or impact. Cannot
  delete without information loss. May benefit from cross-referencing or merging.
- **Distinct** — no meaningful overlap. No action needed.

If the finding set is large (>10 findings), group by `type` first and only compare within
groups. Use subagents for parallel comparison if needed.

See `skills/finding/examples/dedup-scenario.md` for a worked example showing duplicate vs
similar classification and the resolution workflow.

### 2. Present Duplicates and Confirm Actions

Present results:
- Table of **duplicate pairs** with recommendation (which to keep, which to delete)
- Table of **similar pairs** with recommendation (merge, cross-reference, or leave as-is)
- List of **distinct findings** — no action needed

For each duplicate pair: *"Delete `<file>`? [y/n]"*
For each similar pair: *"Merge into `<file>`? [y/n/skip]"*

Never delete or merge without explicit user confirmation.

### 3. Execute and Report

Perform confirmed deletions and merges. When merging:
- Keep the more complete finding as the base
- Incorporate unique content from the other finding
- Present the merged result for user approval before deleting the source

Re-run the index to show the updated finding set:
```bash
bash skills/finding/scripts/index-findings.sh
```

Suggest `/finding-review` on any merged findings to verify quality.

---

## Guidelines

- **Duplicate vs similar is about information loss.** Can you delete one without losing
  anything? Duplicate. Would you lose scope, detail, or a different perspective? Similar.
- **User confirms every action.** No automated deletion or merging. The skill proposes,
  the researcher decides.
- **The more complete finding survives.** When deleting a duplicate, keep the one with
  better documentation, a PoC reference, or more detailed explanation.
- **Merged findings need review.** Always suggest `/finding-review` after a merge.
- **Group by type first.** For large finding sets, only compare within the same type
  to avoid false matches across unrelated vulnerability classes.
