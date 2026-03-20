#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "qdrant-client[fastembed]",
#     "fire",
# ]
# ///
"""
search.py — semantic search across indexed grimoire library content.

Run via: uv run search.py <query> [--limit N] [--library <name>]

Queries the local Qdrant vector database built by librarian-index and prints
results as a JSON array to stdout.
"""

import json
import os
import sys

import fire
from qdrant_client import QdrantClient

DEFAULT_QDRANT_PATH = "~/.grimoire/librarian/qdrant"
DEFAULT_COLLECTION = "grimoire-library"
DEFAULT_EMBEDDING_MODEL = "sentence-transformers/all-MiniLM-L6-v2"


def _open_qdrant(qdrant_path):
    path = os.path.expanduser(qdrant_path)
    if not os.path.isdir(path):
        print(
            json.dumps(
                {"error": f"Qdrant database not found at {path}. Run librarian-index first."}
            )
        )
        sys.exit(1)
    return QdrantClient(path=path)


def search(
    query,
    limit=5,
    library=None,
    qdrant_path=DEFAULT_QDRANT_PATH,
    collection=DEFAULT_COLLECTION,
    embedding_model=DEFAULT_EMBEDDING_MODEL,
):
    """Semantic search across indexed library content.

    Args:
        query:           Natural language query string.
        limit:           Maximum number of results to return.
        library:         Optional library name to filter results.
        qdrant_path:     Path to local Qdrant database.
        collection:      Qdrant collection name.
        embedding_model: FastEmbed model (must match what was used for indexing).
    """
    client = _open_qdrant(qdrant_path)
    client.set_model(embedding_model)

    query_filter = None
    if library:
        from qdrant_client.models import FieldCondition, Filter, MatchValue

        query_filter = Filter(
            must=[FieldCondition(key="library", match=MatchValue(value=library))]
        )

    results = client.query(
        collection_name=collection,
        query_text=query,
        limit=limit,
        query_filter=query_filter,
    )

    client.close()

    output = []
    for point in results:
        output.append(
            {
                "score": point.score,
                "content": point.metadata.pop("document", ""),
                "metadata": point.metadata,
            }
        )

    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    fire.Fire(search)
