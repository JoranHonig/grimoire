# Example: Solidity Audit Annotations

A worked example showing annotation discovery across a Solidity codebase with mixed tag
types. Demonstrates both grep and tree-sitter output, tag filtering, and table format.

## Sample Source

Imagine a Solidity codebase with these annotated files:

**src/Vault.sol:**
```solidity
contract Vault {
    // @audit-high unchecked arithmetic in deposit calculation
    function deposit(uint256 amount) external {
        balances[msg.sender] += amount;
    }

    // @audit-ok checked: reentrancy guard present via modifier
    function withdraw(uint256 amount) external nonReentrant {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok);
    }

    // @audit-todo verify fee calculation matches whitepaper spec
    function calculateFee(uint256 amount) internal view returns (uint256) {
        return amount * feeRate / 10000;
    }
}
```

**src/Oracle.sol:**
```solidity
contract PriceOracle {
    // @audit-med stale price check uses 1 hour — is this too generous?
    function getPrice(address token) external view returns (uint256) {
        require(block.timestamp - lastUpdate[token] < 1 hours);
        return prices[token];
    }

    // @audit can this be manipulated via flash loan?
    function updatePrice(address token, uint256 price) external onlyReporter {
        prices[token] = price;
        lastUpdate[token] = block.timestamp;
    }
}
```

## Invocation — All Annotations

```bash
python3 skills/annotation/scripts/find-annotations.py ./src
```

### JSON Output (with tree-sitter)

```json
[
  {
    "file": "Vault.sol",
    "line": 2,
    "tag": "audit-high",
    "content": "unchecked arithmetic in deposit calculation",
    "context_type": "contract",
    "context_name": "Vault"
  },
  {
    "file": "Vault.sol",
    "line": 7,
    "tag": "audit-ok",
    "content": "checked: reentrancy guard present via modifier",
    "context_type": "contract",
    "context_name": "Vault"
  },
  {
    "file": "Vault.sol",
    "line": 15,
    "tag": "audit-todo",
    "content": "verify fee calculation matches whitepaper spec",
    "context_type": "function",
    "context_name": "calculateFee"
  },
  {
    "file": "Oracle.sol",
    "line": 2,
    "tag": "audit-med",
    "content": "stale price check uses 1 hour — is this too generous?",
    "context_type": "contract",
    "context_name": "PriceOracle"
  },
  {
    "file": "Oracle.sol",
    "line": 8,
    "tag": "audit",
    "content": "can this be manipulated via flash loan?",
    "context_type": "function",
    "context_name": "updatePrice"
  }
]
```

### JSON Output (grep fallback — no tree-sitter)

Same structure, but `context_type` and `context_name` are `"unknown"` for every entry:

```json
[
  {
    "file": "Vault.sol",
    "line": 2,
    "tag": "audit-high",
    "content": "unchecked arithmetic in deposit calculation",
    "context_type": "unknown",
    "context_name": "unknown"
  }
]
```

## Invocation — Filter by Tag

Find only high-severity annotations:

```bash
python3 skills/annotation/scripts/find-annotations.py ./src --tag audit-high
```

```json
[
  {
    "file": "Vault.sol",
    "line": 2,
    "tag": "audit-high",
    "content": "unchecked arithmetic in deposit calculation",
    "context_type": "contract",
    "context_name": "Vault"
  }
]
```

## Invocation — Table Format

```bash
python3 skills/annotation/scripts/find-annotations.py ./src --format table
```

```
FILE                                      LINE  TAG             CONTEXT                        CONTENT
------------------------------------------------------------------------------------------------------------------------
Vault.sol                                    2  audit-high      contract:Vault                 unchecked arithmetic in deposit calculation
Vault.sol                                    7  audit-ok        contract:Vault                 checked: reentrancy guard present via modifier
Vault.sol                                   15  audit-todo      function:calculateFee          verify fee calculation matches whitepaper spec
Oracle.sol                                   2  audit-med       contract:PriceOracle           stale price check uses 1 hour — is this too gen...
Oracle.sol                                   8  audit           function:updatePrice            can this be manipulated via flash loan?

Total: 5 annotation(s)
```

## Design Choices

- **One annotation per line.** Multi-line comments produce one entry at the line containing the `@audit` tag. The agent can read surrounding lines from the file if more context is needed.
- **Tag filtering is exact match.** `--tag audit` matches only bare `@audit`, not `@audit-high`. Run without `--tag` to get everything, then filter programmatically if needed.
- **Tree-sitter resolves to the innermost scope.** An annotation inside `calculateFee` within `Vault` reports `function:calculateFee`, not `contract:Vault`. Annotations at contract level (outside any function) report the contract.
- **Grep fallback is intentionally simple.** It may pick up `@audit` inside string literals. This is acceptable — agents can verify by reading the actual source line.
