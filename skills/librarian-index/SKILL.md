---
name: librarian-index
description: >-
  Use this skill when the user says "index the library", "index my libraries",
  "build the search index", "index the librarian", "rebuild the index",
  "update the search index", "index library content", "index for semantic
  search", "run librarian-index", or wants to make library content searchable
  via semantic/vector search. Reads all registered libraries from
  libraries.yaml, chunks their files, and stores them in the local Qdrant
  vector database so the librarian workflow can do semantic search.
---

# Librarian Index

## Codex Execution Note

Only use Codex workers when the user explicitly asks for delegation or parallel agent work. Otherwise, run the same workflow locally with focused `rg` searches, batched file reads, and concise checkpoints.


Build or rebuild the semantic search index over all registered libraries.

## Philosophy

Text-based grep finds exact strings. Vector search finds *meaning*. When a
researcher asks "how does reentrancy work in pull-payment patterns?" a grep
for `reentrancy` may miss a file that discusses it under a different term. By
storing library content as vector embeddings, the librarian can retrieve
relevant chunks even when the exact words don't match.

The indexing pipeline is a single Python script (`scripts/index.py`) that:

1. Reads `~/.grimoire/librarian/library/libraries.yaml`
2. Walks each library's files, chunking by heading (markdown) or line window (code)
3. Embeds chunks locally via FastEmbed (no API key, no network)
4. Upserts into the local Qdrant database at `~/.grimoire/librarian/qdrant/`

Chunks get deterministic IDs derived from their content hash, so re-running
the index **overwrites** rather than duplicates. This makes the skill fully
idempotent.

## Dependencies

Dependencies are declared inline in the script via PEP 723 metadata. Running
with `uv run` handles everything automatically — no manual `pip install`
needed. Since the plugin already requires `uvx` (for MCP servers), `uv` is
guaranteed to be available.

## Workflow

When this skill is activated, create a todo list from the following steps:

```
- [ ] 1. Run the indexer — execute index.py via uv run
- [ ] 2. Report — relay the script's output to the user
```

---

### 1. Run the indexer

The script is located at `skills/librarian-index/scripts/index.py` inside the
plugin directory.

**Index all libraries (default):**

```bash
uv run /path/to/grimoire/skills/librarian-index/scripts/index.py index
```

**Index a single library:**

```bash
uv run /path/to/grimoire/skills/librarian-index/scripts/index.py index_library \
    <library_dir> <library_name> <source_url>
```

**Optional flags (apply to both commands):**

| Flag | Default | Description |
|------|---------|-------------|
| `--qdrant_path` | `~/.grimoire/librarian/qdrant` | Path to local Qdrant database |
| `--collection` | `grimoire-library` | Qdrant collection name |
| `--embedding_model` | `sentence-transformers/all-MiniLM-L6-v2` | FastEmbed model |
| `--extensions` | `.md,.sol,.py,.js,.ts,.rs,.go,.txt` | File extensions to include |
| `--max_file_size_kb` | `200` | Skip files larger than this |

The first run will download the embedding model (~80 MB). Subsequent runs
reuse the cached model.

### 2. Report

Relay the script's stdout to the user. The script prints a per-library
summary and a total chunk count. If errors occurred (missing directories,
unknown library types), they appear at the bottom.

Remind the user to run `librarian-index` again after adding or updating
libraries with `modify-library`.

## Guidelines

- **Read-only with respect to library files.** The script never modifies
  `libraries.yaml` or any file inside the libraries.
- **Deterministic IDs make re-indexing safe.** The same content always
  produces the same vector point ID, so upserts overwrite cleanly.
- **Skip large files.** Files over 200 KB are likely binary or generated
  artifacts. The script skips them automatically.
- **Markdown gets heading-based splits, code gets line-window splits.** Each
  chunk is prefixed with `[library-name] path/to/file` so search results
  self-identify their origin.
