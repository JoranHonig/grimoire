# Example: Dedup Scenario

An annotated walkthrough of the duplicate detection workflow, showing how to classify
finding pairs and what actions to take for each classification.

## Scenario: Four Findings in an Audit

The `grimoire/findings/` directory contains four findings:

| File | Title | Type | Severity |
|------|-------|------|----------|
| `reentrancy-vault-withdraw.md` | Theft of deposited funds via reentrancy in Vault.withdraw() | reentrancy | High |
| `unsafe-external-call-vault.md` | Unsafe external call in Vault.withdraw() allows reentrancy | reentrancy | High |
| `missing-auth-admin-panel.md` | Unauthorized access to admin panel via missing role check | access-control | Critical |
| `privilege-escalation-admin-routes.md` | Privilege escalation through unprotected admin API routes | access-control | High |

## Classification

### Pair 1: Duplicate

**reentrancy-vault-withdraw.md** vs **unsafe-external-call-vault.md**

| Criterion | Finding A | Finding B |
|-----------|-----------|-----------|
| Root cause | State update after external call in withdraw() | External call before state update in withdraw() |
| Affected component | Vault.sol:142-158 | Vault.sol:142-158 |
| Impact | Theft of all deposited funds | Reentrancy enabling fund drainage |

**Classification: Duplicate.** Same root cause (CEI violation in withdraw), same affected
code, same impact. The two findings describe the identical issue in different words.

**Action:** Keep the more complete finding. In this case, `reentrancy-vault-withdraw.md` has
a detailed exploit walkthrough and PoC reference. Delete `unsafe-external-call-vault.md`.

**Confirmation prompt:** *"Delete `unsafe-external-call-vault.md`? It duplicates
`reentrancy-vault-withdraw.md` (same root cause: CEI violation in Vault.withdraw). [y/n]"*

### Pair 2: Similar

**missing-auth-admin-panel.md** vs **privilege-escalation-admin-routes.md**

| Criterion | Finding C | Finding D |
|-----------|-----------|-----------|
| Root cause | Missing role check on admin panel route | Multiple admin API routes lack authorization |
| Affected component | src/routes/admin.js:12 (panel endpoint) | src/routes/admin.js:12-89 (all admin routes) |
| Impact | Unauthorized admin panel access | Full admin privilege escalation |

**Classification: Similar.** Related root cause (missing authorization on admin routes) but
different scope. Finding C covers one specific endpoint. Finding D covers the entire admin
route file. Deleting either loses information.

**Options:**
1. **Merge** — combine into a single finding covering all admin routes, using Finding D as
   the base (broader scope) and incorporating Finding C's specific detail about the panel
   endpoint.
2. **Cross-reference** — keep both, add a note in each referencing the other.
3. **Leave as-is** — if the user considers them distinct enough to report separately.

**Confirmation prompt:** *"Findings C and D both cover admin authorization gaps. Merge into
`privilege-escalation-admin-routes.md` (broader scope)? [y/n/skip]"*

## After Dedup

Assuming the user confirms both actions:

| File | Title | Type | Severity |
|------|-------|------|----------|
| `reentrancy-vault-withdraw.md` | Theft of deposited funds via reentrancy in Vault.withdraw() | reentrancy | High |
| `privilege-escalation-admin-routes.md` | Privilege escalation through unprotected admin API routes (includes admin panel) | access-control | Critical |

Two findings reduced to two, but cleaner: one duplicate removed, one pair merged with no
information loss.

The merged finding should be reviewed with `/finding-review` to ensure the incorporated
content reads well and the severity is still appropriate (promoted from High to Critical
since the merged scope includes the critical panel access).

## Why This Workflow Works

- **Duplicate vs similar is about information loss.** Can you delete one without losing
  anything? Duplicate. Would you lose scope, detail, or a different perspective? Similar.
- **User confirms every action.** No automated deletion or merging. The skill proposes,
  the researcher decides.
- **The more complete finding survives.** When deleting a duplicate, keep the one with
  better documentation, a PoC reference, or more detailed explanation.
- **Merged findings need review.** Combining content from two findings can introduce
  inconsistencies. Always suggest `/finding-review` after a merge.
- **Grouping by type first.** The reentrancy findings were only compared to each other,
  and the access-control findings were only compared to each other. This prevents false
  matches across unrelated vulnerability classes.
