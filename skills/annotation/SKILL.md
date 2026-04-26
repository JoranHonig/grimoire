---
name: annotation
description: >-
  This skill should be used when the user says "find annotations", "list audit
  tags", "show @audit comments", "compile annotations", "/annotation",
  "find todos", "find audit comments", "what did I annotate", "annotation
  summary", "list audit findings", "what's annotated",
  or wants to discover, list, or filter @audit-* comment annotations
  scattered throughout a codebase. This skill is for annotation discovery only —
  how annotations are used downstream (running helper passes, cross-referencing
  findings, etc.) is out of scope.
---

# Annotation

## Codex Execution Note

Only use Codex workers when the user explicitly asks for delegation or parallel agent work. Otherwise, run the same workflow locally with focused `rg` searches, batched file reads, and concise checkpoints.


Find `@audit` annotations in a codebase and return them as structured JSON.

## Workflow

1. Determine the target directory — the project root, a `src/` subdirectory, or whatever the user specified.
2. Run the discovery script against the target directory.
3. Present results to the user in their requested format (JSON for programmatic use, table for overview).

## Invocation

```
uv run skills/annotation/scripts/find-annotations.py <directory> [--tag TAG] [--format json|table]
```

- `directory` — path to scan (usually the project root or `src/`)
- `--tag` — filter to a specific tag, exact match (e.g., `audit-high`, `audit-todo`)
- `--format` — `json` (default) or `table` for human-readable output

## Output

Each annotation is returned with six fields:

| Field | Description |
|-------|-------------|
| `file` | Relative path from the scanned directory |
| `line` | Line number (1-indexed) |
| `tag` | Tag name — `audit`, `audit-ok`, `audit-high`, `audit-todo`, etc. |
| `content` | Text after the tag on the same line |
| `context_type` | Enclosing scope type (`function`, `contract`, `trait`, etc.) or `unknown` |
| `context_name` | Name of the enclosing scope or `unknown` |

## Language Support

The script has two tiers of support:

- **All languages** — grep-based discovery. Finds annotations in any text file. Context fields are `unknown`.
- **Rust and Solidity** — tree-sitter parsing resolves `context_type` and `context_name` to the enclosing function, contract, trait, impl, or module. Falls back to grep if tree-sitter dependencies are not installed.


## Annotation Types

Refer to `references/annotation-format.md` for the full taxonomy of supported `@audit` tag types.
