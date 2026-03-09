# Example: Reentrancy Finding

A complete finding for a classic reentrancy vulnerability in a Solidity vault contract.
Demonstrates all frontmatter fields, all required sections, and an optional Details section
with a multi-step exploit walkthrough.

## Finding File

```markdown
---
title: Theft of deposited funds via reentrancy in Vault.withdraw() due to state update after external call
severity: High
type: reentrancy
context:
  - src/Vault.sol:142-158
  - src/interfaces/IVault.sol:23
---

## Description

The `Vault` contract allows users to deposit and withdraw ETH. The `withdraw()` function
at `src/Vault.sol:142` sends ETH to the caller via a low-level `call` before updating the
internal `balances` mapping. An attacker can deploy a contract with a `receive()` function
that re-enters `withdraw()` during the ETH transfer, draining the vault of all deposited
funds.

Any user who has deposited at least 1 wei can exploit this. The attack requires no special
privileges and can be executed in a single transaction. The impact is loss of all ETH held
by the Vault contract.

## Details

The exploit proceeds in four steps:

1. The attacker deposits a small amount of ETH into the Vault via `deposit()`.
2. The attacker calls `withdraw()`, which checks `balances[msg.sender] > 0` (line 143) and
   sends ETH via `(bool success, ) = msg.sender.call{value: amount}("")` (line 150).
3. The attacker's `receive()` function re-enters `withdraw()`. Because the balance update
   `balances[msg.sender] = 0` at line 155 has not yet executed, the check at line 143
   passes again.
4. Steps 2-3 repeat until the Vault is drained. The balance is only set to zero after the
   final call returns.

The vulnerable code sequence:

```solidity
function withdraw() external {
    uint256 amount = balances[msg.sender];  // line 143
    require(amount > 0, "No balance");

    (bool success, ) = msg.sender.call{value: amount}("");  // line 150
    require(success, "Transfer failed");

    balances[msg.sender] = 0;  // line 155 — too late
}
```

## Proof of Concept

@grimoire/pocs/reentrancy-vault-poc.t.sol

## Recommendation

Update the contract balance state before performing the external call, following the
checks-effects-interactions pattern. Specifically, set `balances[msg.sender] = 0` before
the `call` on line 150.

## References

[1] SWC-107: Reentrancy — https://swcregistry.io/docs/SWC-107
[2] Checks-Effects-Interactions pattern — Solidity documentation
```

## Why This Finding Works

- **Title.** Contains where (Vault.withdraw), how (reentrancy, state update after external
  call), and what (theft of deposited funds).
- **Severity justification.** High is appropriate: direct fund loss, minimal preconditions
  (any depositor), single transaction.
- **Self-contained Description.** A reader who has never seen the Vault contract understands
  what it does, what the flaw is, what preconditions exist, and what the impact is.
- **Details add value.** The four-step walkthrough and code snippet explain a mechanism that
  is not obvious from the Description alone.
- **Recommendation is minimal.** States what to change (reorder operations) and names the
  pattern (CEI). Does not provide a rewritten contract.
- **References are real.** SWC-107 is a real registry entry. The Solidity documentation
  genuinely covers the CEI pattern.
- **Context field.** Lists the exact file and line range, plus the interface for completeness.
