# Finding Best Practices

Quality guidelines for drafting and reviewing security findings. Used by both draft mode
(to write well) and review mode (to evaluate quality).

## Title Guidelines

The title must convey **where**, **how**, and **what** (impact):

- **Where** — the affected component, route, function, or contract
- **How** — the mechanism or flaw type
- **What** — the impact or consequence

### Good Titles

| Title | Why it works |
|-------|-------------|
| "Theft of deposited funds via reentrancy in Vault.withdraw() due to state update after external call" | Where (Vault.withdraw), How (reentrancy + state after call), What (theft of funds) |
| "Account takeover enabled by lack of authentication in backend route UPDATE /user" | Where (UPDATE /user), How (no auth), What (account takeover) |
| "Denial of service in token transfer via unbounded loop over holder array" | Where (token transfer), How (unbounded loop), What (DoS) |

### Bad Titles

| Title | Problem |
|-------|---------|
| "Missing authentication" | No where, no what. Which route? What can an attacker do? |
| "Account takeover" | No where, no how. What component? What mechanism? |
| "Incorrect backend implementation" | Vague. Says nothing specific about the flaw. |
| "Reentrancy" | No where, no what. Which function? What is the impact? |
| "Bug in Vault.sol" | No how, no what. What kind of bug? What does it enable? |

### Common Anti-patterns

- **Too short** — missing one or more of where/how/what
- **Too long** — more than ~120 characters; move detail to Description
- **Impact-only** — states what happens but not where or how
- **Location-only** — states where but not what an attacker gains
- **Jargon without context** — assumes the reader knows project-specific terms

## Description Guidelines

The description is the most important section. Self-containment test: *Could someone who
has never opened this repo understand the vulnerability from this section alone?*

### Structure

1. **What is the component?** One sentence establishing context.
2. **What is the flaw?** The mechanism — what goes wrong and why.
3. **What are the preconditions?** Privileges required, timing, configuration needed.
4. **What is the impact?** What an attacker can achieve. Be specific.

### Tips

- Include code snippets when they clarify the mechanism. Keep them short — just the
  relevant lines.
- State severity cues explicitly: "Any unauthenticated user can...", "An attacker with
  admin access could...", "Under specific timing conditions..."
- Do not reference other findings. Each finding stands alone.
- Keep it concise. If you need more than 4 paragraphs, move technical detail to the
  Details section.

## Details Guidelines

### When to Include

- The exploit involves multiple steps (e.g., flash loan + swap + withdrawal)
- The mechanism requires a code walkthrough to understand
- There are edge cases or timing windows that need explanation

### When to Omit

- The Description already covers the mechanism adequately
- The flaw is straightforward (e.g., missing authorization on one route)
- The PoC demonstrates the issue clearly enough on its own

### Tips

- Use numbered steps for multi-step exploits
- Reference specific code lines with `file:line` format
- Do not repeat content from the Description

## Recommendation Guidelines

### Principles

- **Objective voice.** State what needs to change, not how you would rewrite the code.
- **One-sentence fixes preferred.** If you can express the fix in one sentence, do so.
- **Never suggest non-trivial code changes.** Security researchers are external, unbiased
  reviewers. Suggesting complex implementations introduces bias.
- **Acceptable suggestions:** Add a check, use a different function, add comments, reorder
  operations, add rate limiting, validate input.
- **Not acceptable:** Full reimplementations, architectural redesigns, multi-file refactors.

### The "Out of Scope" Escape Hatch

If the vulnerability has no simple fix, state:

> *"The design space for a solution to this flaw is out of scope for this report."*

This is honest and appropriate. Not every finding has a one-line fix.

### Tips

- Reference established patterns when applicable (e.g., "checks-effects-interactions",
  "principle of least privilege")
- If suggesting a function change, name the function but do not write the implementation

## Severity Estimation

### Factors to Consider

| Factor | Higher severity | Lower severity |
|--------|----------------|----------------|
| **Exploitability** | No authentication needed, simple to trigger | Requires admin access, complex setup |
| **Impact scope** | All users, all funds, full compromise | Single user, limited data, partial |
| **Preconditions** | None or minimal | Specific config, timing, privilege |
| **Reversibility** | Irreversible (fund loss, data deletion) | Recoverable (temporary DoS) |
| **Likelihood** | Common scenario, easy to discover | Edge case, requires specific knowledge |

### Guidelines

- **Critical** — direct, unconditional path to maximum impact. No reasonable preconditions.
- **High** — significant impact with moderate preconditions or effort.
- **Medium** — real but conditional impact. Requires chaining, specific config, or elevated
  privileges.
- **Low** — minor or largely theoretical impact. Worth documenting for defense in depth.
- **Informational** — deviation from best practice. No direct exploitation path.

Severity is an estimate, not a formal CVSS score. Justify with one sentence in the finding.
Do not overstate confidence.

## References and Fact-Checking

- Every cited reference must be real and verifiable
- Never fabricate CVEs, SWC entries, blog posts, or documentation links
- When referencing a concept (e.g., reentrancy), provide background for readers who may
  not know the term — do not assume universal knowledge
- Prefer primary sources: official documentation, specification documents, registry entries
- When the librarian agent becomes available, it will assist with reference discovery

## Common Mistakes Checklist

Use this during review to catch frequent issues:

- [ ] Title missing impact (what)
- [ ] Title missing location (where)
- [ ] Description not self-contained — references external context
- [ ] Recommendation suggests non-trivial code changes
- [ ] Severity estimate does not match described impact
- [ ] PoC reference points to nonexistent file
- [ ] References cite fabricated sources
- [ ] Code snippets included without file/line attribution
- [ ] Preconditions not stated (assumes the reader knows requirements)
- [ ] Uses project-specific jargon without explanation
