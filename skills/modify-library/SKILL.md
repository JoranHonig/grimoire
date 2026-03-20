---
name: modify-library
description: >-
  Use this skill when the user wants to add, remove, or change a library in the
  grimoire librarian. Trigger phrases include: "add a library", "add a git
  library", "add a local library", "add a symlink library", "remove a library",
  "remove the X library", "change a library", "update a library", "update a
  library source", "upgrade a library", "switch library source", "edit a
  library", "modify a library", "register a library", "unregister a library",
  "delete a library entry", "add knowledge base", "add a repo to the
  librarian", "add library to librarian", or any request to change what
  libraries the librarian has access to. Modifies
  ~/.grimoire/librarian/library/libraries.yaml to add, remove, or update
  library entries. Supports git repositories and local symlink directories.
user_invocable: true
---

# Modify Library

Add, remove, or change a library entry in `~/.grimoire/librarian/library/libraries.yaml`.

## Philosophy

The librarian's knowledge bases are declared in `libraries.yaml`. Each entry
records the library's name, type, and source so the librarian can locate and
refresh it automatically.

This skill handles all three mutation operations on that file:

- **add** — register a new library
- **remove** — deregister an existing library
- **change** — update the type or source of an existing library

Before writing anything, the skill validates that the source actually points to
a reachable repository or directory. This prevents stale entries from silently
accumulating in the index.

## Workflow

When this skill is activated, create a todo list from the following steps. Mark
each task in_progress before starting it and completed when done.

```
- [ ] 1. Parse intent — identify operation, library name, type, and source
- [ ] 2. Validate — check prerequisites and verify the source is reachable
- [ ] 3. Apply — update libraries.yaml; clone git libraries into library/
- [ ] 4. Report — confirm the change
```

---

### 1. Parse intent

Identify these four pieces of information from the user's request:

| Field | Required for | Description |
|-------|-------------|-------------|
| **operation** | all | `add`, `remove`, or `change` |
| **name** | all | the library's key in `libraries.yaml` (e.g. `smart-contract-vulnerabilities`) |
| **type** | add, change | `git` or `symlink` |
| **source** | add, change | git URL (for `git`) or absolute path (for `symlink`) |

If any required field is missing or ambiguous, ask the user before proceeding.
Do not guess without asking — if intent is ambiguous, confirm with the user
before acting. For `change` requests, confirm which field(s) to update (type,
source, or both) if the user has not made this explicit.

**Common patterns to recognize:**

- `add a git library called <name> from <url>` → operation=add, type=git, source=url
- `add a local library at <path>` → operation=add, type=symlink, source=path
- `remove the <name> library` → operation=remove, name=name
- `change the source for <name> to <url>` → operation=change, name=name, source=url

### 2. Validate

Run all checks that apply to the operation before touching any file.

**Check that libraries.yaml exists:**

```bash
[ -f ~/.grimoire/librarian/library/libraries.yaml ] \
  && echo "libraries.yaml: present" \
  || echo "libraries.yaml: absent"
```

If `libraries.yaml` is absent, something is wrong — it is created automatically on session
start by the grimoire init hook. Report the error and stop.

**Check that libraries.yaml is valid YAML:**

```bash
python3 -c "
import yaml
with open('$HOME/.grimoire/librarian/library/libraries.yaml') as f:
    yaml.safe_load(f)
print('yaml: valid')
"
```

If this exits with an error, `libraries.yaml` is malformed. Stop and tell the
user to fix the file manually or delete it and re-run `librarian-initialize`.

**For `remove` and `change` — check that the entry exists:**

```bash
python3 -c "
import yaml
with open('$HOME/.grimoire/librarian/library/libraries.yaml') as f:
    data = yaml.safe_load(f) or {}
libs = data.get('libraries') or {}
name = '<library-name>'
print('entry: present' if name in libs else 'entry: absent')
"
```

If the entry is absent for a `remove` or `change` operation, stop and report
that no library with that name exists.

**For `add` — check that the name is not already taken:**

Run the same check above. If the entry already exists, stop and tell the user
to use `change` instead if they want to update the existing entry.

**For `add` and `change` — validate the source:**

*Git repository:*
```bash
git ls-remote <source> HEAD
```

`git ls-remote` performs a lightweight handshake with the remote — it does not
clone the repository. Exit code 0 means the URL is reachable and points to a
valid git repository. A non-zero exit means the URL is invalid or inaccessible.

If the validation fails, stop and report the error output from `git ls-remote`.
Do not add an unreachable repository to `libraries.yaml`.

*Local directory (symlink):*
```bash
test -d <source> && echo "directory: present" || echo "directory: absent"
```

If the path does not exist or is not a directory, stop and report the error.

### 3. Apply

Read `libraries.yaml`, apply the mutation, and write the result back using
Python. Replace `<library-name>`, `<type>`, and `<source>` with the values
from step 1.

**Add:**
```bash
python3 - <<'EOF'
import yaml, sys, os

path = os.path.expanduser('~/.grimoire/librarian/library/libraries.yaml')
with open(path) as f:
    data = yaml.safe_load(f) or {}

if 'libraries' not in data or data['libraries'] is None:
    data['libraries'] = {}

data['libraries']['<library-name>'] = {
    'type': '<type>',
    'source': '<source>',
}

with open(path, 'w') as f:
    yaml.dump(data, f, default_flow_style=False, allow_unicode=True, sort_keys=False)

print('done')
EOF
```

**Remove:**
```bash
python3 - <<'EOF'
import yaml, os

path = os.path.expanduser('~/.grimoire/librarian/library/libraries.yaml')
with open(path) as f:
    data = yaml.safe_load(f) or {}

libs = data.get('libraries') or {}
libs.pop('<library-name>', None)
data['libraries'] = libs

with open(path, 'w') as f:
    yaml.dump(data, f, default_flow_style=False, allow_unicode=True, sort_keys=False)

print('done')
EOF
```

**Change:**
```bash
python3 - <<'EOF'
import yaml, os

path = os.path.expanduser('~/.grimoire/librarian/library/libraries.yaml')
with open(path) as f:
    data = yaml.safe_load(f) or {}

entry = (data.get('libraries') or {}).get('<library-name>', {})
# Update only the fields provided; keep existing values for fields not being changed
entry['type'] = '<type>'       # omit this line if type is not changing
entry['source'] = '<source>'   # omit this line if source is not changing
data['libraries']['<library-name>'] = entry

with open(path, 'w') as f:
    yaml.dump(data, f, default_flow_style=False, allow_unicode=True, sort_keys=False)

print('done')
EOF
```

If the Python script exits with an error, report the error and stop. Do not
attempt to repair the file manually.

**For `add` with `type: git` — clone the repository:**

After writing `libraries.yaml`, clone the repository into the library directory:

```bash
git clone <source> ~/.grimoire/librarian/library/<library-name>
```

If the clone fails, remove the entry from `libraries.yaml` to keep the index
consistent with what is actually present on disk:

```bash
python3 - <<'EOF'
import yaml, os

path = os.path.expanduser('~/.grimoire/librarian/library/libraries.yaml')
with open(path) as f:
    data = yaml.safe_load(f) or {}

libs = data.get('libraries') or {}
libs.pop('<library-name>', None)
data['libraries'] = libs

with open(path, 'w') as f:
    yaml.dump(data, f, default_flow_style=False, allow_unicode=True, sort_keys=False)

print('rolled back')
EOF
```

Then report the clone error to the user and stop.

### 4. Report

Confirm the operation clearly.

Example add report (git library):

> Added `smart-contract-vulnerabilities` to the library index and cloned it to
> `~/.grimoire/librarian/library/smart-contract-vulnerabilities/`:
>
> ```yaml
> type: git
> source: git@github.com:kadenzipfel/smart-contract-vulnerabilities.git
> ```
>
> The library is ready to use.

Example add report (symlink library):

> Added `security-notes` to the library index:
>
> ```yaml
> type: symlink
> source: /Users/alice/security-notes
> ```
>
> The librarian will read directly from `/Users/alice/security-notes`.

Example remove report:

> Removed `smart-contract-vulnerabilities` from the library index.
>
> The entry has been deleted from `libraries.yaml`. Any locally cloned copy in
> `~/.grimoire/librarian/library/` was not touched — remove it manually if
> you no longer need the files.

Example change report:

> Updated `smart-contract-vulnerabilities` in the library index:
>
> ```yaml
> type: git
> source: https://github.com/kadenzipfel/smart-contract-vulnerabilities.git
> ```

## Guidelines

- **Never skip validation.** Do not write to `libraries.yaml` before the source
  has been verified as reachable.
- **Ask before acting when intent is ambiguous.** If the library name, type, or
  source is unclear, ask — do not guess.
- **Preserve existing entries.** The Python snippets above load the full file
  and write it back; only the targeted entry is affected.
- **Remove does not delete files.** This skill only modifies `libraries.yaml`.
  It does not delete cloned repositories from `library/` or `cache/`.
- **git ls-remote requires network access.** If the user is offline, mention
  that validation requires a network connection and offer to skip validation
  only if the user explicitly confirms the URL is correct.
- **Symlink source must be an absolute path.** Relative paths are ambiguous
  across sessions; ask the user to provide the full path.
