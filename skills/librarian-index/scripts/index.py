#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "qdrant-client[fastembed]",
#     "pyyaml",
#     "fire",
# ]
# ///
"""
index.py — index grimoire library content into a local Qdrant vector database.

Run via: uv run index.py <command>

Commands:
    index             Index all libraries from libraries.yaml
    index_library     Index a single library by name or path
    chunk_file        Chunk a single file (JSON to stdout, no Qdrant writes)
    chunk_library     Chunk all files in a library (JSON to stdout, no Qdrant writes)
"""

import glob
import hashlib
import json
import os
import re
import sys

import fire
import yaml
from qdrant_client import QdrantClient

DEFAULT_QDRANT_PATH = "~/.grimoire/librarian/qdrant"
DEFAULT_COLLECTION = "grimoire-library"
DEFAULT_EMBEDDING_MODEL = "sentence-transformers/all-MiniLM-L6-v2"
DEFAULT_EXTENSIONS = ".md,.sol,.py,.js,.ts,.rs,.go,.txt"
DEFAULT_MAX_FILE_SIZE_KB = 200
LIBRARIES_YAML = "~/.grimoire/librarian/library/libraries.yaml"


# ---------------------------------------------------------------------------
# Chunking
# ---------------------------------------------------------------------------


def _make_chunk(text, lib_name, rel_path, source_url, idx, chunks):
    """Append a chunk to *chunks* if it meets the minimum length threshold."""
    text = text.strip()
    if len(text) < 80:
        return
    chunks.append(
        {
            "content": f"[{lib_name}] {rel_path}\n\n{text}",
            "metadata": {
                "library": lib_name,
                "file": rel_path,
                "chunk_idx": idx,
                "source_url": source_url,
            },
        }
    )


def _chunk_content(content, ext, lib_name, rel_path, source_url):
    """Split *content* into chunks using the strategy appropriate for *ext*."""
    chunks = []
    if ext == ".md":
        sections = re.split(r"\n(?=#{1,4} )", content)
        for i, section in enumerate(sections):
            if len(section) <= 2500:
                _make_chunk(section, lib_name, rel_path, source_url, i, chunks)
            else:
                for j in range(0, len(section), 1800):
                    _make_chunk(
                        section[j : j + 2500],
                        lib_name,
                        rel_path,
                        source_url,
                        i * 1000 + j,
                        chunks,
                    )
    else:
        lines = content.splitlines()
        if len(lines) <= 80:
            _make_chunk(content, lib_name, rel_path, source_url, 0, chunks)
        else:
            size, overlap = 80, 15
            i, idx = 0, 0
            while i < len(lines):
                _make_chunk(
                    "\n".join(lines[i : i + size]),
                    lib_name,
                    rel_path,
                    source_url,
                    idx,
                    chunks,
                )
                i += size - overlap
                idx += 1
    return chunks


# ---------------------------------------------------------------------------
# File discovery
# ---------------------------------------------------------------------------


def _collect_files(library_dir, extensions, max_file_size_kb):
    """Return a list of (abs_path, rel_path) pairs for indexable files."""
    exts = {e.strip() for e in extensions.split(",") if e.strip()}
    max_bytes = max_file_size_kb * 1024
    files = []
    for ext in exts:
        pattern = os.path.join(library_dir, "**", f"*{ext}")
        for abs_path in glob.glob(pattern, recursive=True):
            if "/.git/" in abs_path:
                continue
            try:
                if os.path.getsize(abs_path) > max_bytes:
                    continue
            except OSError:
                continue
            files.append((abs_path, os.path.relpath(abs_path, library_dir)))
    return files


def _chunk_files(files, library_name, source_url):
    """Read and chunk a list of (abs_path, rel_path) pairs."""
    all_chunks = []
    for abs_path, rel_path in files:
        try:
            with open(abs_path, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
        except Exception:
            continue
        if not content.strip():
            continue
        ext = os.path.splitext(abs_path)[1].lower()
        all_chunks.extend(
            _chunk_content(content, ext, library_name, rel_path, source_url)
        )
    return all_chunks


# ---------------------------------------------------------------------------
# Qdrant helpers
# ---------------------------------------------------------------------------


def _deterministic_ids(chunks):
    """Generate stable integer IDs from chunk content so re-indexing upserts."""
    ids = []
    for chunk in chunks:
        h = hashlib.sha256(chunk["content"].encode("utf-8")).hexdigest()[:16]
        ids.append(int(h, 16))
    return ids


def _open_qdrant(qdrant_path):
    path = os.path.expanduser(qdrant_path)
    os.makedirs(path, exist_ok=True)
    return QdrantClient(path=path)


# ---------------------------------------------------------------------------
# CLI commands
# ---------------------------------------------------------------------------


def index(
    qdrant_path=DEFAULT_QDRANT_PATH,
    collection=DEFAULT_COLLECTION,
    embedding_model=DEFAULT_EMBEDDING_MODEL,
    extensions=DEFAULT_EXTENSIONS,
    max_file_size_kb=DEFAULT_MAX_FILE_SIZE_KB,
):
    """Index all libraries from libraries.yaml into Qdrant.

    Reads ~/.grimoire/librarian/library/libraries.yaml, walks each registered
    library, chunks files, embeds them with FastEmbed, and upserts into the
    local Qdrant database. Uses deterministic IDs so re-running overwrites
    rather than duplicates.
    """
    yaml_path = os.path.expanduser(LIBRARIES_YAML)

    if not os.path.isfile(yaml_path):
        print(
            "Error: libraries.yaml not found. Run librarian-initialize first.",
            file=sys.stderr,
        )
        sys.exit(1)

    with open(yaml_path) as f:
        data = yaml.safe_load(f) or {}

    libs = data.get("libraries") or {}
    if not libs:
        print(
            "Error: no libraries registered. Use modify-library to add one.",
            file=sys.stderr,
        )
        sys.exit(1)

    print(f"Indexing {len(libs)} libraries into {collection}...\n")

    client = _open_qdrant(qdrant_path)
    client.set_model(embedding_model)

    total_chunks = 0
    errors = []

    for name, entry in libs.items():
        lib_type = entry.get("type")
        source = entry.get("source", "")

        if lib_type == "git":
            lib_dir = os.path.expanduser(f"~/.grimoire/librarian/library/{name}")
        elif lib_type == "symlink":
            lib_dir = source
        else:
            errors.append(f"{name}: unknown type '{lib_type}'")
            continue

        if not os.path.isdir(lib_dir):
            errors.append(f"{name}: directory not found ({lib_dir})")
            continue

        files = _collect_files(lib_dir, extensions, max_file_size_kb)
        chunks = _chunk_files(files, name, source)

        if not chunks:
            print(f"  {name}: 0 chunks (no indexable content)")
            continue

        client.add(
            collection_name=collection,
            documents=[c["content"] for c in chunks],
            metadata=[c["metadata"] for c in chunks],
            ids=_deterministic_ids(chunks),
            batch_size=64,
        )

        print(f"  {name}: {len(chunks)} chunks from {len(files)} files")
        total_chunks += len(chunks)

    client.close()

    print(f"\nDone. {total_chunks} total chunks indexed.")

    if errors:
        print(f"\nErrors ({len(errors)}):")
        for e in errors:
            print(f"  {e}")


def index_library(
    library_dir,
    library_name,
    source_url,
    qdrant_path=DEFAULT_QDRANT_PATH,
    collection=DEFAULT_COLLECTION,
    embedding_model=DEFAULT_EMBEDDING_MODEL,
    extensions=DEFAULT_EXTENSIONS,
    max_file_size_kb=DEFAULT_MAX_FILE_SIZE_KB,
):
    """Index a single library directory into Qdrant."""
    library_dir = os.path.expanduser(library_dir)
    files = _collect_files(library_dir, extensions, max_file_size_kb)
    chunks = _chunk_files(files, library_name, source_url)

    if not chunks:
        print(f"{library_name}: 0 chunks (no indexable content)")
        return

    client = _open_qdrant(qdrant_path)
    client.set_model(embedding_model)

    client.add(
        collection_name=collection,
        documents=[c["content"] for c in chunks],
        metadata=[c["metadata"] for c in chunks],
        ids=_deterministic_ids(chunks),
        batch_size=64,
    )

    client.close()
    print(f"{library_name}: {len(chunks)} chunks from {len(files)} files")


def chunk_file(abs_path, rel_path, library_name, source_url):
    """Chunk a single file and print JSON to stdout (no Qdrant writes)."""
    try:
        with open(abs_path, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()
    except Exception:
        print(json.dumps([]))
        return
    if not content.strip():
        print(json.dumps([]))
        return
    ext = os.path.splitext(abs_path)[1].lower()
    print(json.dumps(_chunk_content(content, ext, library_name, rel_path, source_url)))


def chunk_library(
    library_dir,
    library_name,
    source_url,
    extensions=DEFAULT_EXTENSIONS,
    max_file_size_kb=DEFAULT_MAX_FILE_SIZE_KB,
):
    """Chunk all files in a library and print JSON to stdout (no Qdrant writes)."""
    library_dir = os.path.expanduser(library_dir)
    files = _collect_files(library_dir, extensions, max_file_size_kb)
    print(json.dumps(_chunk_files(files, library_name, source_url)))


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    fire.Fire(
        {
            "index": index,
            "index_library": index_library,
            "chunk_file": chunk_file,
            "chunk_library": chunk_library,
        }
    )
