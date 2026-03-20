---
name: librarian-initialize
description: >-
  Use this skill when the user says "initialize the librarian", "set up the
  librarian", "setup librarian", "initialize grimoire librarian", "librarian
  initialize", "install the librarian", "create librarian directory", "librarian
  setup", "prepare the librarian", or wants to get the librarian working for the
  first time or upgrade an existing installation. Creates ~/.grimoire/librarian/
  with the library/ and cache/ directories and an empty libraries.yaml, or
  upgrades an existing installation by adding any missing pieces.
user_invocable: true
---

# Librarian Initialize

Set up or upgrade the librarian's directory structure at `~/.grimoire/librarian/`.

## Philosophy

The librarian depends on three directories under `~/.grimoire/librarian/`:

- **`library/`** — the researcher's curated knowledge bases, indexed by `libraries.yaml`
- **`cache/`** — transient clones of external repositories fetched on demand
- **`qdrant/`** — local Qdrant vector database used by the `librarian-index` skill for semantic search

This skill creates that structure on a fresh machine and upgrades it when the layout
has changed. It is safe to run at any time: it never overwrites an existing
`libraries.yaml` or removes any content — it only adds what is missing.

The upgrade path is intentionally simple: compare the expected layout against what
exists and create only the absent pieces. No versioning scheme is required because
the structure is flat and append-only.

## Workflow

When this skill is activated, create a todo list from the following steps. Mark each
task in_progress before starting it and completed when done.

```
- [ ] 1. Detect existing state — check what is already present
- [ ] 2. Plan the changes — identify what needs to be created
- [ ] 3. Apply the changes — create only missing pieces
- [ ] 4. Report — summarize what was created or confirm up to date
```

---

### 1. Detect existing state

Check which parts of the expected layout already exist:

```bash
[ -d ~/.grimoire/librarian ]          && echo "root: present"    || echo "root: absent"
[ -d ~/.grimoire/librarian/library ]  && echo "library/: present"  || echo "library/: absent"
[ -d ~/.grimoire/librarian/cache ]    && echo "cache/: present"   || echo "cache/: absent"
[ -d ~/.grimoire/librarian/qdrant ]   && echo "qdrant/: present"  || echo "qdrant/: absent"
[ -f ~/.grimoire/librarian/library/libraries.yaml ] \
  && echo "libraries.yaml: present" || echo "libraries.yaml: absent"
```

Record which of these five items are present and which are absent. This determines
whether this is a fresh install or an upgrade, and exactly what needs to be created.

### 2. Plan the changes

Based on the detection results, determine the set of actions:

- If **all five** are present → nothing to do (already up to date)
- Otherwise → for each absent item, plan to create it:
  - `~/.grimoire/librarian/` — root directory
  - `~/.grimoire/librarian/library/` — knowledge base directory
  - `~/.grimoire/librarian/cache/` — transient cache directory
  - `~/.grimoire/librarian/qdrant/` — local vector database directory
  - `~/.grimoire/librarian/library/libraries.yaml` — empty library index

Note whether this is a **fresh install** (root was absent) or an **upgrade** (root was
present but some pieces were missing). This distinction is used in the report.

If nothing needs to be created, skip to step 4 and report that the installation is
already up to date.

### 3. Apply the changes

For each item that needs to be created, run the corresponding command:

**Create root directory (if absent):**
```bash
mkdir -p ~/.grimoire/librarian
```

**Create library/ directory (if absent):**
```bash
mkdir -p ~/.grimoire/librarian/library
```

**Create cache/ directory (if absent):**
```bash
mkdir -p ~/.grimoire/librarian/cache
```

**Create qdrant/ directory (if absent):**
```bash
mkdir -p ~/.grimoire/librarian/qdrant
```

**Create empty libraries.yaml (if absent):**
```bash
cat > ~/.grimoire/librarian/library/libraries.yaml << 'EOF'
libraries: {}
EOF
```

Do **not** overwrite `libraries.yaml` if it already exists — it may contain library
entries the researcher has already added.

If any command exits with an error (e.g. permission denied), report the error and
stop. Do not retry or attempt workarounds.

### 4. Report

Summarize the outcome clearly:

- **Fresh install:** State that the librarian has been initialized and list each
  directory and file created.
- **Upgrade:** State which missing pieces were added and which were already present.
- **Already up to date:** State that the installation is current and no changes were
  made.

In all cases, remind the user of the next steps: add libraries with `modify-library`,
index them with `librarian-index`, then use the librarian directly.

Example fresh-install report:

> Librarian initialized at `~/.grimoire/librarian/`:
>
> - Created `library/`
> - Created `cache/`
> - Created `qdrant/`
> - Created `library/libraries.yaml` (empty)
>
> Add knowledge bases with the `modify-library` skill, then index them with `librarian-index`.

## Guidelines

- **Never overwrite existing data.** If `libraries.yaml` already exists, skip it.
  Existing library entries must not be lost.
- **`mkdir -p` is safe.** It is a no-op when the directory already exists, so you can
  call it without checking first if that simplifies the implementation.
- **Idempotent.** Running this skill repeatedly on an already-initialized installation
  has no side effects.
- **No partial state.** If a command fails mid-way, report the error immediately.
  Do not continue with remaining steps after a failure.
- **Only creates structure.** This skill never clones repositories, populates
  `libraries.yaml`, or does anything beyond creating the two directories and the
  empty YAML file.
