# Example Check: ERC-4626 Vault Compliance

A checklist-style check for a specific standard. Demonstrates how to cover multiple items
for one component type without violating the simplicity principle — each item is a quick
assessment, not deep reasoning.

## Check File

```markdown
---
name: erc4626 compliance
description: Checks ERC-4626 vault implementations for common deviations and security issues.
languages: solidity
severity-default: medium
confidence: medium
tools: [Grep, Read]
tags: [erc4626, vault, defi, standard]
attribution-name: EIP-4626 Tokenized Vault Standard
attribution-url: https://eips.ethereum.org/EIPS/eip-4626
---

Identify contracts implementing ERC-4626 (look for `deposit`, `mint`, `withdraw`, `redeem`,
`totalAssets`, `convertToShares`, `convertToAssets`).

For each vault implementation, check:

1. Does `maxDeposit` return 0 when deposits should be paused?
2. Does `maxWithdraw` account for available liquidity (not just user balance)?
3. Does `previewDeposit` match actual `deposit` behavior (no hidden fees)?
4. Does `previewRedeem` match actual `redeem` behavior?
5. Are `totalAssets` manipulable via direct token transfer?
6. Does the vault handle rebasing or fee-on-transfer tokens?

For each deviation found, report the specific function and expected vs actual behavior.
Adjust severity based on whether the deviation could lead to loss of funds.
```

## Why This Check Works

- **Checklist, not essay.** Each item is a yes/no question the agent can evaluate quickly.
  The check doesn't explain ERC-4626 in depth — that's what the Librarian is for.
- **Single component type.** All items apply to one kind of contract (ERC-4626 vault).
  The agent doesn't need to context-switch between different code patterns.
- **Borderline length.** At ~15 lines body, this is well within the 30-line limit. If more
  items were needed (e.g., covering ERC-4626 + ERC-20 interactions), it should be a separate
  check.
