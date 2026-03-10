# Merge Decisions

When gc-cartography flags overlapping flows, the decision to merge is not automatic. This
reference formalizes the decision framework.

## Decision Criteria

### Merge When

- **Same activity, different perspectives.** Two flows document the same logical operation
  (e.g., "secret retrieval" and "vault read") from different starting points or at different
  granularities. Merging unifies the picture.

- **Strict subset.** One flow's components are entirely contained within another flow. The
  smaller flow adds no unique components — it's a slice of the larger flow. Absorb it.

- **>40% overlap with similar descriptions.** High component overlap combined with
  descriptions that describe the same activity (even in different words) strongly indicates
  duplication. The 40% threshold is calibrated against the overlap formula in
  `overlap-metrics.md`.

- **Overlap cluster.** Three or more flows form a chain (A overlaps B, B overlaps C) with
  each pair exceeding 40%. This usually means the flows grew organically from different
  starting investigations and should be consolidated.

### Keep Separate When

- **Shared infrastructure, different concerns.** Flows share components like auth middleware,
  database clients, or API gateways but investigate completely different security properties.
  A payment flow and a user registration flow might both pass through the same gateway — that
  shared infrastructure doesn't make them the same flow.

- **Different trust boundaries.** Even with high component overlap, if the flows cross
  different trust boundaries or represent different threat models, they serve distinct
  purposes. An admin API flow and a public API flow through the same handlers are separate
  security concerns.

- **User says so.** The researcher may have reasons that aren't apparent from the file
  contents. Never override the user's decision to keep flows separate.

## Choosing the Primary Flow

When merging, one flow keeps its filename (primary) and the other is absorbed. Choose the
primary based on:

1. **More components** — the larger flow is usually the more complete picture
2. **More security notes** — richer annotations indicate deeper investigation
3. **Broader scope** — a flow covering the full operation beats a partial view
4. **Established references** — if other files link to one flow more often, keep that one to
   minimize reference updates

If both flows are roughly equal, prefer the one created first (earlier `created` date) since
it's more likely to be referenced elsewhere.

## Merge Execution Principles

### Preserve All Security Notes

Security notes are the highest-value content in a cartography file. When merging:

- Keep every unique note from both files
- Deduplicate only when two notes say exactly the same thing
- When notes conflict, keep both and annotate the conflict for the researcher to resolve
- Never summarize or compress security notes — they are observations, not documentation

### Use Conditional Sections for Divergent Paths

When two flows share entry points and components but diverge in their sequences:

- Keep the primary flow's sequence as the main body
- Move the absorbed flow's divergent sequence into a conditional section
- Format: `## Conditional: [Sub-flow Name]` with a condition comment

This prevents context pollution — an agent loading the file gets the main flow by default
and only loads the conditional section when investigating that specific sub-flow.

### Update Scope Indicators

After absorbing a flow, the primary flow's scope may have broadened:

- Update `description` if the merged flow now covers more than the original described
- Merge `tags` as a union — keep all tags from both flows
- Merge `related` as a union — remove the absorbed flow's slug, add any new related flows
  the absorbed flow referenced
- Set `updated` to today's date

## Ambiguous Cases

When the decision isn't clear-cut, present both options to the user with:

1. The overlap percentage and shared components
2. What each flow contributes uniquely
3. A recommendation (merge or keep separate) with reasoning
4. What would be lost or gained by merging

Let the user decide. The cost of an unnecessary merge (lost context, harder to navigate) is
higher than the cost of keeping a borderline-redundant flow (slightly more files to manage).
