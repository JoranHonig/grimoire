# Example: Fresh Install

This example shows the librarian being initialized for the first time on a machine
where `~/.grimoire/librarian/` does not exist.

---

## User prompt

> Initialize the librarian.

---

## Skill execution

**Step 1 — Detect existing state**

```
$ [ -d ~/.grimoire/librarian ] && echo "root: present" || echo "root: absent"
root: absent
```

Root directory is absent. The remaining three checks will also be absent since the root
does not exist. This is a fresh install.

**Step 2 — Plan the changes**

All four items need to be created:
- `~/.grimoire/librarian/` (root)
- `~/.grimoire/librarian/library/`
- `~/.grimoire/librarian/cache/`
- `~/.grimoire/librarian/library/libraries.yaml`

**Step 3 — Apply the changes**

```
$ mkdir -p ~/.grimoire/librarian
$ mkdir -p ~/.grimoire/librarian/library
$ mkdir -p ~/.grimoire/librarian/cache
$ cat > ~/.grimoire/librarian/library/libraries.yaml << 'EOF'
libraries: {}
EOF
```

All commands complete without error.

**Step 4 — Report**

---

## Response to user

Librarian initialized at `~/.grimoire/librarian/`:

- Created `library/`
- Created `cache/`
- Created `library/libraries.yaml` (empty)

Add knowledge bases with the `modify-library` skill, or use the librarian directly
to fetch and search external repositories.
