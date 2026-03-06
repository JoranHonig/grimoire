---
name: Review Cartography
description: >-
  This skill should be used when the user says "review a flow",
  "improve a flow", "verify a flow", "refine cartography",
  "/review-cartography", "check a cartography file", "update a flow map",
  "verify flow accuracy", or wants to verify and improve an existing
  cartography file against the actual codebase. It cross-references
  documented flows with real code, fills gaps, adds related flow links,
  and introduces conditional sections where needed.
user_invocable: true
---

# Review Cartography

Verify and refine an existing cartography file against the actual codebase. Fill gaps, fix
inaccuracies, add cross-references, and introduce conditional sections where needed.

## Philosophy

**First drafts are starting points.** A cartography file created during initial exploration
captures what was found, not everything that exists. Code changes, flows evolve, and initial
exploration misses things. Review is how cartography files become reliable navigation maps that
agents can trust.

## Workflow

When this skill is activated, create a todo list from the following steps. Mark each task
in_progress before starting it and completed when done.

```
- [ ] 1. Select flow — run index, identify target cartography file
- [ ] 2. Verify against codebase — spawn subagents to check each section independently
- [ ] 3. Extend missing pieces — add what subagents found missing
- [ ] 4. Cross-reference related flows — compare with index, add reciprocal related links
- [ ] 5. Add conditional sections — separate independent sub-flows if file is too large
- [ ] 6. Update file and index — write changes, update date, re-run index
```

---

### 1. Select Flow

Run the indexing script to list available flows:

```bash
bash skills/cartography/scripts/index-cartography.sh grimoire/cartography/
```

If the user specified a flow, match it against the index. If not, present the list and ask
which flow to review.

Read the target cartography file in full.

### 2. Verify Against Codebase

Spawn subagents to independently verify each section of the cartography file against the actual
codebase. Each subagent should check one area:

**Entry points subagent:** For each listed entry point, verify:
- Does the file exist?
- Does the symbol (function/method/handler) exist in that file?
- Are there other entry points into this flow that were missed?

**Key components subagent:** For each listed component, verify:
- Does the file exist?
- Is the one-line role description accurate?
- Are there other files that participate in this flow but aren't listed?

**Flow sequence subagent:** Trace the documented sequence through the code:
- Does execution actually follow the documented order?
- Are there steps missing between documented steps?
- Are file references at each step correct?

**Security notes subagent:** Review the security observations:
- Are the noted trust boundaries still accurate?
- Have any validation gaps been fixed since the file was written?
- Are there new security-relevant observations to add?

Collect all subagent results before proceeding.

### 3. Extend Missing Pieces

Based on subagent findings, update the cartography file:

- Add missing entry points, components, or sequence steps
- Fix incorrect file paths or symbol names
- Remove references to files or symbols that no longer exist
- Add new security notes discovered during verification

Maintain the format defined in the cartography skill's
`references/cartography-format.md`. Keep entries as pointers — don't add code explanations.

### 4. Cross-Reference Related Flows

Compare the current flow against all other flows in the index:

- Read the frontmatter of all other cartography files
- Identify flows that share components, entry points, or security concerns
- Add missing entries to the `related` field in frontmatter
- Add `[[cartography/...]]` links in the Related Flows section
- **Make links reciprocal** — if flow A references flow B, update flow B to reference flow A

If significant overlap is detected (>40% shared components between two flows), note this to
the user and suggest [[gc-cartography]] for potential merging.

### 5. Add Conditional Sections

If the cartography file body exceeds ~80 lines, look for opportunities to separate independent
sub-flows into conditional sections:

- Identify parts of the flow that are only relevant for specific investigations
- Extract them into `## Conditional: [Sub-flow Name]` sections
- Add a `<!-- condition: load only when [topic] -->` comment
- Move the sub-flow's entry points, components, sequence, and security notes under the
  conditional section

The condition comment should describe when an agent should load this section. Be specific
enough that an agent can match it against a user's question.

If the file is already lean (<80 lines body), skip this step.

### 6. Update File and Index

Write all changes to the cartography file:

- Update the `updated` field in frontmatter to today's date
- Preserve the original `created` date

Re-run the indexing script:

```bash
bash skills/cartography/scripts/index-cartography.sh grimoire/cartography/
```

Present to the user:
- A summary of what was changed (added, removed, corrected)
- Any security notes that were added or updated
- Any related flow links that were added
- Suggest [[gc-cartography]] if overlap with other flows was detected

---

## Guidelines

- **Independent verification.** Subagents should check the code themselves, not just validate
  that file paths exist. Read the actual code to confirm role descriptions and flow sequences.
- **Don't bloat the file.** Review should make the file more accurate, not longer. If adding
  new content pushes the file past ~80 lines, use conditional sections.
- **Reciprocal links.** Every `related` reference should go both ways. If you add flow B to
  flow A's related list, also add flow A to flow B's.
- **Preserve security notes.** Never remove a security note unless you can confirm the issue
  has been resolved in the code. When in doubt, keep it.
- **Update, don't recreate.** This skill refines existing files. If the flow needs to be
  rewritten from scratch, use [[cartography]] instead.
