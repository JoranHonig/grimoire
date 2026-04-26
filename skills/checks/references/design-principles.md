# Check Design Principles

This reference covers the philosophy behind checks: why simplicity matters, how to manage
agent attention, and when to split checks.

## The Simplicity Principle

It is enticing to produce super complex checks that find lots of cool bugs. Resist this.

It is much more worthwhile having many simple checks that filter out common mistakes and bugs.

- A check that reliably finds one bug class is worth more than one that unreliably finds five.
- Complex checks exhaust agent attention and produce uncertain results.
- Simple checks compose: run 20 simple checks in parallel, get 20 focused results.
- Each check is a starting point, not a comprehensive analysis. The agent applies the check,
  produces findings, and those findings get triaged and investigated separately.

## Attention Management

Agent context is finite and degrades with length. Every extra line in a check dilutes the
agent's focus on the actual codebase.

**Checks should be limited in context.** The agent reading a check should spend most of its
attention on the codebase, not on understanding the check instructions.

### Context Isolation

Each check runs in its own subagent with its own context window. The subagent receives the
check body and the codebase — nothing else. This isolation is intentional:

- Prevents cross-contamination between checks
- Keeps each agent focused on one pattern
- Allows parallel execution without interference

Checks cannot depend on each other. If check B needs results from check A, they should be
merged into one check or the dependency should be handled at the workflow level.

### The 30-Line Rule

If the body of a check exceeds ~30 lines, it almost certainly needs splitting. This is a
soft limit, not a hard rule — but exceeding it should trigger a review. Long checks indicate
either:

1. Multiple patterns bundled together (split by pattern)
2. Complex assessment logic (split identification from assessment)
3. Extensive background (move to Librarian, keep the check focused)

## When to Split

Determining when a check should be split is difficult. These signals help:

### Multiple Independent Patterns

If a check says "look for A" and also "look for B" where A and B are unrelated patterns,
split into two checks. Each agent should hunt one thing.

**Example:** A check that covers both "unchecked return values" and "missing null checks" should
be two checks — the patterns are different, the assessment is different, and the agent's search
strategy is different.

### Complex Assessment

If identifying the pattern is easy but assessing whether it is problematic requires deep
reasoning, separate identification from assessment.

**Example from the spec — rounding errors:**

- **Check 1 (rounding-direction):** Identify where rounding occurs and in which direction.
  Severity: informational. Confidence: high. This is a scanning check.
- **Check 2 (rounding-inflation-attack):** For vault-like contracts with share/asset math,
  assess whether rounding could enable a vault inflation attack. Severity: high. Confidence:
  low. This is an assessment check.

The reasoning for "is this rounding exploitable via inflation attack" is substantial. Bundling
it with basic rounding identification would dilute the agent's attention on both tasks.

### Multiple Languages

If a pattern manifests differently in different languages, create per-language checks. The
search patterns, assessment criteria, and severity defaults may all differ.

**Example:** "Unchecked return values" in C (ignored return from `malloc`) vs Go (discarded
`error` with `_`) are different checks with different patterns and different severity profiles.

### Body Length

If the body exceeds ~30 lines after writing, split. This is the simplest signal and serves
as a backstop for the other criteria.

## Starting Points, Not Conclusions

Checks are starting points based on common mistakes and best practices. They identify *where
to look*, not *what the conclusion is*.

- The agent applies the check and produces findings
- Findings get triaged (by the researcher, or by Familiar when implemented)
- Confirmed findings get investigated further (write-poc, cartography)
- Validated patterns get automated (by Scribe when implemented)

Checks that try to do deep analysis themselves will produce unreliable results. Keep the
check simple, let downstream workflows handle depth.

## Future Considerations

The spec notes that Grimoire might implement coordination between checks or hierarchical checks
for token efficiency. This is not currently implemented. For now:

- Checks are independent units
- No check assumes results from another check
- The `related-checks` frontmatter field provides a lightweight connection for human navigation
  but has no runtime effect
