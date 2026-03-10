# Overlap Metrics

Formalization of how gc-cartography measures overlap between cartography flows. Extends the
detection thresholds defined in review-cartography's `overlap-detection.md` with merge-specific
metrics.

## Core Overlap Formula

```
overlap = shared_components / max(components_A, components_B)
```

- **shared_components**: count of file paths appearing in both flows' Key Components sections
- **components_A / components_B**: total component count for each flow
- **max()**: using the larger count catches subset flows where a small flow is entirely
  contained within a larger one

Only Key Components paths are counted. Entry Points and Flow Sequence file references are
excluded because they represent access patterns, not flow identity.

### Path Matching

Paths are compared as exact strings after stripping the `:symbol` suffix. This means:

- `core/src/crypto/kms_client.rs:unwrap_key` and `core/src/crypto/kms_client.rs:wrap_key`
  both resolve to `core/src/crypto/kms_client.rs` and count as a match
- Relative vs absolute path differences would not match — but cartography files should
  consistently use project-relative paths

## Overlap Tiers

| Tier | Range | Interpretation | GC Action |
|------|-------|----------------|-----------|
| Low | <20% | Normal shared infrastructure | No action |
| Notable | 20-40% | Significant overlap worth noting | Report as informational |
| High | >40% | Likely duplication | Flag as merge candidate |
| Subset | 100% of smaller flow | One flow entirely within another | Strong merge candidate |

## Subset Detection

A flow is a **strict subset** when every one of its components appears in another flow:

```
subset = (shared_components == components_smaller_flow)
```

Subsets are always merge candidates regardless of the percentage from the larger flow's
perspective. A 5-component flow entirely contained in a 20-component flow is only 25% overlap
by the standard formula, but it's still a strict subset.

## Cluster Detection

An **overlap cluster** exists when three or more flows form a connected graph where each edge
represents >40% overlap:

```
A --52%--> B --45%--> C
```

Clusters indicate that a single logical flow was mapped multiple times from different starting
points. The merge strategy for clusters:

1. Identify the flow with the most components as the primary
2. Absorb flows one at a time, starting with the highest-overlap pair
3. Re-check overlap after each merge — the merged flow's component set changes

## Metric Limitations

### False Positives

High overlap does not always mean duplication:

- **Hub components**: Files like `auth/middleware.rs` or `db/connection.rs` appear in many
  flows. If two flows share only hub components, they're probably independent flows through
  shared infrastructure.
- **Same area, different concerns**: Two flows in the same codebase area investigating
  different vulnerability classes (e.g., access control vs injection) may share components
  but serve distinct purposes.

### False Negatives

Low overlap does not always mean independence:

- **Renamed files**: If the codebase refactored between mapping sessions, the same logical
  components may have different paths.
- **Different granularity**: One flow may reference `src/auth/` while another references
  individual files within that directory.

These cases require human judgment — the metrics provide candidates, not decisions.

## Script Integration

The `scripts/detect-overlaps.sh` script implements these metrics by wrapping
review-cartography's `find-overlaps.sh` and adding:

- Subset detection (flags when smaller flow is 100% contained)
- Cluster detection (groups connected overlapping pairs)
- Primary flow suggestion based on component count and security note count
