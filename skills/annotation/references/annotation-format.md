# Annotation Format

Reference for `@audit` annotation types, the JSON output schema, and the two-tier
language support model.

## Annotation Types

| Tag | Meaning | When to use |
|-----|---------|-------------|
| `@audit` | General annotation | Comments, questions, observations, anything worth flagging |
| `@audit-ok` | Checked — not an issue | Code verified safe for a specific concern; documents due diligence |
| `@audit-info` | Informational finding | Design note or non-security observation worth reporting |
| `@audit-low` | Low severity finding | Minor issue with limited impact |
| `@audit-med` | Medium severity finding | Meaningful issue requiring attention |
| `@audit-high` | High severity finding | Serious vulnerability with significant impact |
| `@audit-crit` | Critical severity finding | Exploitable vulnerability with severe impact |
| `@audit-todo` | Action item | Something to investigate, verify, or follow up on |
| `@audit-<custom>` | User-defined tag | Any `@audit-` prefix followed by a word — the taxonomy is extensible |

The regex pattern `@audit(?:-([\w]+))?` matches all of these, including custom tags.

## JSON Output Schema

The script outputs a JSON array. Each element has these fields:

```json
{
  "file": "src/vault/Vault.sol",
  "line": 42,
  "tag": "audit-high",
  "content": "unchecked arithmetic in balance calculation",
  "context_type": "function",
  "context_name": "calculateBalance"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `file` | string | Path relative to the scanned directory |
| `line` | integer | 1-indexed line number |
| `tag` | string | Tag without the `@` prefix — `audit`, `audit-ok`, `audit-high`, etc. |
| `content` | string | Text following the tag on the same line (comment-closing tokens stripped) |
| `context_type` | string | Enclosing scope type or `"unknown"` if grep-scanned |
| `context_name` | string | Enclosing scope name or `"unknown"` if grep-scanned |

## Context Resolution

**Grep tier (all languages):** Finds annotations reliably but cannot resolve the enclosing
scope. Both `context_type` and `context_name` are `"unknown"`. May produce false positives
if `@audit` appears inside string literals rather than comments.

**Tree-sitter tier (Rust and Solidity):** Parses the file into an AST and only matches
annotations inside comment nodes — no false positives from strings. Walks up the AST to
find the innermost enclosing scope:

| Language | Supported context types |
|----------|------------------------|
| Rust | `function`, `impl`, `trait`, `module` |
| Solidity | `function`, `modifier`, `constructor`, `contract`, `library`, `interface` |

If tree-sitter dependencies are not installed, Rust and Solidity files are scanned with the
grep fallback automatically. Install dependencies from `scripts/requirements.txt` for full
context resolution.

## File Filtering

The scanner skips:

- Directories: `.git`, `node_modules`, `target`, `build`, `out`, `dist`, `__pycache__`, `.venv`, `venv`
- Binary file extensions: images, archives, compiled artifacts, lock files
- Files larger than 1 MB
