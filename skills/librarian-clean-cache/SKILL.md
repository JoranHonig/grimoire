---
name: Librarian Clean Cache
description: >-
  Use this skill when the user says "clean librarian cache", "clear librarian
  cache", "clean up librarian repos", "prune librarian cache", "shrink librarian
  cache", "librarian is using too much space", "free up disk space from librarian",
  "how much space is librarian using", or wants to remove cached repositories
  that the librarian has cloned locally. Clears ~/.grimoire/librarian/cache/ to
  reclaim disk space without touching the curated library/ directory.
user_invocable: true
---

# Librarian Clean Cache

Clear the librarian's local repository cache at `~/.grimoire/librarian/cache/`.

## Philosophy

The librarian clones external repositories on demand into `~/.grimoire/librarian/cache/`
to enable efficient local code search. Over time this cache accumulates disk space. This
skill provides a safe, confirmed cleanup: it shows exactly what will be removed before
acting, so the researcher can make an informed decision.

Only the transient `cache/` directory is touched. The `library/` directory — which holds
curated knowledge bases indexed by `libraries.yaml` — is never removed by this skill.

## Workflow

When this skill is activated, create a todo list from the following steps. Mark each task
in_progress before starting it and completed when done.

```
- [ ] 1. Inspect the cache — list repos and total size
- [ ] 2. Confirm with the user — show what will be removed
- [ ] 3. Remove the cache — rm -rf cache/ only
- [ ] 4. Report freed space — confirm removal and state freed bytes
```

---

### 1. Inspect the cache

Check whether `~/.grimoire/librarian/cache/` exists and contains anything:

```bash
[ -d ~/.grimoire/librarian/cache ] && ls -1 ~/.grimoire/librarian/cache/
```

- If the directory does not exist or is empty, report that the cache is already clean and
  mark the remaining steps completed — nothing to do.
- If it exists and has content, gather sizes:

```bash
du -sh ~/.grimoire/librarian/cache/*/   # per-repo sizes
du -sh ~/.grimoire/librarian/cache/     # total
```

### 2. Confirm with the user

Present the findings:

- The list of cached repository names and their individual sizes
- Total disk space that will be freed
- Explicit note that `library/` is **not** affected

Then ask for confirmation before proceeding. Example:

> Found 3 cached repositories (420 MB total):
> - `smart-contract-vulnerabilities` (12 MB)
> - `openzeppelin-contracts` (180 MB)
> - `uniswap-v3-core` (228 MB)
>
> Remove these? The `library/` directory will not be touched. [y/N]

If the user declines, stop without making any changes.

### 3. Remove the cache

Run:

```bash
rm -rf ~/.grimoire/librarian/cache/
```

Do **not** run `rm -rf ~/.grimoire/librarian/` — that would remove the `library/` directory
and `libraries.yaml` as well.

If `rm` exits with an error (e.g. permission denied), report the error and ask the user to
investigate manually. Do not retry.

### 4. Report freed space

Confirm that the directory has been removed and state how much disk space was freed. Note
that the librarian will automatically re-clone repositories as needed for future queries.

## Guidelines

- **Only `cache/` is affected.** Never remove `~/.grimoire/librarian/library/` or
  `~/.grimoire/librarian/library/libraries.yaml` — those are maintained by the researcher.
- **Safe to run repeatedly.** If the cache is already empty, the skill exits cleanly.
- **No impact on research.** The librarian re-clones on demand; clearing the cache does not
  lose any permanent data.
- **Decline without side effects.** If the user says no at the confirmation step, nothing
  is changed.
