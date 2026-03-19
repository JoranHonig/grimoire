# Example: Upgrade Run

This example shows the skill being run on a machine where the librarian was previously
set up but the `cache/` directory is missing (e.g. it was manually deleted, or the
installation predates the two-directory layout).

---

## User prompt

> Initialize the librarian.

---

## Skill execution

**Step 1 — Detect existing state**

```
$ [ -d ~/.grimoire/librarian ] && echo "root: present" || echo "root: absent"
root: present
$ [ -d ~/.grimoire/librarian/library ] && echo "library/: present" || echo "library/: absent"
library/: present
$ [ -d ~/.grimoire/librarian/cache ] && echo "cache/: present" || echo "cache/: absent"
cache/: absent
$ [ -f ~/.grimoire/librarian/library/libraries.yaml ] && echo "libraries.yaml: present" || echo "libraries.yaml: absent"
libraries.yaml: present
```

Root, `library/`, and `libraries.yaml` are present. Only `cache/` is absent.
This is an **upgrade** run.

**Step 2 — Plan the changes**

One item needs to be created:
- `~/.grimoire/librarian/cache/`

Existing items are left untouched:
- `~/.grimoire/librarian/` — already present
- `~/.grimoire/librarian/library/` — already present
- `~/.grimoire/librarian/library/libraries.yaml` — already present (not overwritten)

**Step 3 — Apply the changes**

```
$ mkdir -p ~/.grimoire/librarian/cache
```

Command completes without error.

**Step 4 — Report**

---

## Response to user

Librarian upgraded at `~/.grimoire/librarian/`:

- `library/` — already present (no changes)
- `cache/` — **created**
- `library/libraries.yaml` — already present (not modified)

Your existing library entries are unchanged. The librarian is now fully up to date.
