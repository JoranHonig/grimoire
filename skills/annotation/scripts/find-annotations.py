#!/usr/bin/env python3
"""Find @audit annotations in a codebase.

Discovers @audit-* comment annotations and returns structured JSON with
contextual metadata. Uses tree-sitter for Rust and Solidity to resolve
enclosing scope names; falls back to grep-based discovery for all other
languages or when tree-sitter is unavailable.

Usage:
    python3 find-annotations.py <directory> [--tag TAG] [--format json|table]
"""

import json
import os
import re
import sys
from dataclasses import asdict, dataclass
from typing import List, Optional

try:
    import fire
except ImportError:
    print("python-fire is required: pip install fire", file=sys.stderr)
    sys.exit(1)

# Tree-sitter is optional — graceful degradation
_HAS_TREE_SITTER = False
_ts_rust = None
_ts_solidity = None

try:
    import tree_sitter_rust as _ts_rust
    import tree_sitter_solidity as _ts_solidity
    from tree_sitter import Language, Parser

    _HAS_TREE_SITTER = True
except ImportError:
    pass

# --- Constants ---

ANNOTATION_RE = re.compile(r"@audit(?:-([\w]+))?(?!\w)")

SKIP_DIRS = {
    ".git",
    "node_modules",
    "target",
    "build",
    "out",
    "dist",
    "__pycache__",
    ".venv",
    "venv",
}

SKIP_EXTENSIONS = {
    ".png", ".jpg", ".jpeg", ".gif", ".bmp", ".ico", ".svg", ".webp",
    ".wasm", ".bin", ".exe", ".dll", ".so", ".dylib", ".a", ".o", ".obj",
    ".zip", ".tar", ".gz", ".bz2", ".xz", ".7z", ".rar",
    ".pdf", ".doc", ".docx", ".xls", ".xlsx",
    ".pyc", ".class", ".lock",
}

MAX_FILE_SIZE = 1_000_000  # 1 MB


@dataclass
class Annotation:
    file: str
    line: int
    tag: str
    content: str
    context_type: str
    context_name: str


# --- Grep Scanner (universal fallback) ---


def _grep_scan_file(filepath: str, base_dir: str) -> List[Annotation]:
    """Scan a single file for @audit annotations using regex."""
    results = []
    try:
        with open(filepath, "r", encoding="utf-8", errors="replace") as f:
            for lineno, line in enumerate(f, start=1):
                for match in ANNOTATION_RE.finditer(line):
                    sub_tag = match.group(1)
                    tag = f"audit-{sub_tag}" if sub_tag else "audit"
                    # Content is everything after the matched tag on the same line
                    after = line[match.end() :].strip()
                    # Strip comment-closing tokens
                    for token in ("*/", "-->"):
                        if after.endswith(token):
                            after = after[: -len(token)].rstrip()
                    results.append(
                        Annotation(
                            file=os.path.relpath(filepath, base_dir),
                            line=lineno,
                            tag=tag,
                            content=after,
                            context_type="unknown",
                            context_name="unknown",
                        )
                    )
    except (OSError, UnicodeDecodeError):
        pass
    return results


# --- Tree-sitter Scanner (Rust + Solidity) ---

# Scope node types to walk up to when resolving context
_RUST_SCOPES = {
    "function_item": "function",
    "impl_item": "impl",
    "trait_item": "trait",
    "mod_item": "module",
}

_SOLIDITY_SCOPES = {
    "function_definition": "function",
    "modifier_definition": "modifier",
    "constructor_definition": "constructor",
    "contract_declaration": "contract",
    "library_declaration": "library",
    "interface_declaration": "interface",
}


def _get_scope_name(node, scope_map: dict) -> tuple:
    """Walk up the AST to find the innermost named scope."""
    current = node.parent
    while current is not None:
        if current.type in scope_map:
            context_type = scope_map[current.type]
            # Try to find the name child node
            name_node = current.child_by_field_name("name")
            if name_node:
                context_name = name_node.text.decode("utf-8", errors="replace")
            else:
                context_name = "<anonymous>"
            return context_type, context_name
        current = current.parent
    return "unknown", "unknown"


def _ts_scan_file(
    filepath: str, base_dir: str, parser, scope_map: dict
) -> List[Annotation]:
    """Scan a file using tree-sitter for precise comment extraction."""
    results = []
    try:
        with open(filepath, "rb") as f:
            source = f.read()
        tree = parser.parse(source)
    except (OSError, Exception) as e:
        # If tree-sitter fails, fall back to grep for this file
        print(f"Warning: tree-sitter parse failed for {filepath}: {e}", file=sys.stderr)
        return _grep_scan_file(filepath, base_dir)

    def visit(node):
        if node.type in ("line_comment", "block_comment", "comment"):
            text = node.text.decode("utf-8", errors="replace")
            # A comment node can span multiple lines; check each line
            start_line = node.start_point[0] + 1  # tree-sitter is 0-indexed
            for i, comment_line in enumerate(text.split("\n")):
                for match in ANNOTATION_RE.finditer(comment_line):
                    sub_tag = match.group(1)
                    tag = f"audit-{sub_tag}" if sub_tag else "audit"
                    after = comment_line[match.end() :].strip()
                    for token in ("*/", "-->"):
                        if after.endswith(token):
                            after = after[: -len(token)].rstrip()
                    ctx_type, ctx_name = _get_scope_name(node, scope_map)
                    results.append(
                        Annotation(
                            file=os.path.relpath(filepath, base_dir),
                            line=start_line + i,
                            tag=tag,
                            content=after,
                            context_type=ctx_type,
                            context_name=ctx_name,
                        )
                    )
        for child in node.children:
            visit(child)

    visit(tree.root_node)
    return results


# --- Scanner dispatch ---


def _make_parser(language_mod):
    """Create a tree-sitter parser for the given language module."""
    lang = Language(language_mod.language())
    parser = Parser(lang)
    return parser


def _should_skip(filepath: str) -> bool:
    """Check if a file should be skipped."""
    _, ext = os.path.splitext(filepath)
    if ext.lower() in SKIP_EXTENSIONS:
        return True
    try:
        if os.path.getsize(filepath) > MAX_FILE_SIZE:
            return True
    except OSError:
        return True
    return False


def _scan_directory(directory: str) -> List[Annotation]:
    """Walk directory and scan all files for annotations."""
    results = []
    base_dir = os.path.abspath(directory)

    # Prepare tree-sitter parsers if available
    rust_parser = None
    sol_parser = None
    if _HAS_TREE_SITTER:
        try:
            rust_parser = _make_parser(_ts_rust)
        except Exception:
            pass
        try:
            sol_parser = _make_parser(_ts_solidity)
        except Exception:
            pass

    for root, dirs, files in os.walk(base_dir):
        # Prune skipped directories
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        dirs.sort()

        for filename in sorted(files):
            filepath = os.path.join(root, filename)
            if _should_skip(filepath):
                continue

            ext = os.path.splitext(filename)[1].lower()

            if ext == ".rs" and rust_parser:
                results.extend(
                    _ts_scan_file(filepath, base_dir, rust_parser, _RUST_SCOPES)
                )
            elif ext == ".sol" and sol_parser:
                results.extend(
                    _ts_scan_file(filepath, base_dir, sol_parser, _SOLIDITY_SCOPES)
                )
            else:
                results.extend(_grep_scan_file(filepath, base_dir))

    return results


# --- Output formatting ---


def _format_table(annotations: List[Annotation]) -> str:
    """Format annotations as a human-readable table."""
    if not annotations:
        return "No annotations found."

    lines = []
    lines.append(f"{'FILE':<40} {'LINE':>5}  {'TAG':<15} {'CONTEXT':<30} CONTENT")
    lines.append("-" * 120)
    for a in annotations:
        ctx = (
            f"{a.context_type}:{a.context_name}"
            if a.context_type != "unknown"
            else ""
        )
        content = a.content[:60] + "..." if len(a.content) > 60 else a.content
        lines.append(
            f"{a.file:<40} {a.line:>5}  {a.tag:<15} {ctx:<30} {content}"
        )
    lines.append(f"\nTotal: {len(annotations)} annotation(s)")
    return "\n".join(lines)


# --- CLI ---


def find(directory: str, tag: Optional[str] = None, format: str = "json"):
    """Find @audit annotations in a directory.

    Args:
        directory: Path to scan for annotations.
        tag: Filter to a specific tag (e.g., 'audit-high', 'audit-todo').
             Exact match only.
        format: Output format — 'json' (default) or 'table'.
    """
    if not os.path.isdir(directory):
        print(f"Error: '{directory}' is not a directory", file=sys.stderr)
        sys.exit(1)

    annotations = _scan_directory(directory)

    if tag:
        annotations = [a for a in annotations if a.tag == tag]

    if format == "table":
        print(_format_table(annotations))
    else:
        print(json.dumps([asdict(a) for a in annotations], indent=2))


if __name__ == "__main__":
    fire.Fire(find)
