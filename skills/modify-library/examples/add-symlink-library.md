# Example: Add a Local Symlink Library

A researcher has a local directory of custom security notes and audit templates
at `/Users/alice/security-notes` and wants to make it available to the
librarian without cloning anything.

---

**User prompt:**

> Add my local security notes as a library — the directory is at /Users/alice/security-notes

---

## Skill execution

### Step 1 — Parse intent

The request mentions a local directory, so the type is `symlink`:

| Field | Value |
|-------|-------|
| operation | add |
| name | `security-notes` |
| type | `symlink` |
| source | `/Users/alice/security-notes` |

The user did not provide an explicit library name. The skill infers
`security-notes` from the directory name and confirms with the user:

> I'll register this as `security-notes`. Does that look right, or would you
> like a different name?

The user confirms. Proceed to validation.

---

### Step 2 — Validate

**Check libraries.yaml:**

```bash
$ [ -f ~/.grimoire/librarian/library/libraries.yaml ] && echo "present" || echo "absent"
present
```

**Check that the name is not already taken:**

```bash
$ python3 -c "
import yaml
with open('$HOME/.grimoire/librarian/library/libraries.yaml') as f:
    data = yaml.safe_load(f) or {}
libs = data.get('libraries') or {}
print('entry: present' if 'security-notes' in libs else 'entry: absent')
"
entry: absent
```

Good — the name is available.

**Validate the local directory:**

```bash
$ test -d /Users/alice/security-notes && echo "directory: present" || echo "directory: absent"
directory: present
```

The directory exists. Proceed to apply.

---

### Step 3 — Apply

```bash
$ python3 - <<'EOF'
import yaml, os

path = os.path.expanduser('~/.grimoire/librarian/library/libraries.yaml')
with open(path) as f:
    data = yaml.safe_load(f) or {}

if 'libraries' not in data or data['libraries'] is None:
    data['libraries'] = {}

data['libraries']['security-notes'] = {
    'type': 'symlink',
    'source': '/Users/alice/security-notes',
}

with open(path, 'w') as f:
    yaml.dump(data, f, default_flow_style=False, allow_unicode=True, sort_keys=False)

print('done')
EOF
done
```

`libraries.yaml` now contains:

```yaml
libraries:
  security-notes:
    type: symlink
    source: /Users/alice/security-notes
```

---

### Step 4 — Report

> Added `security-notes` to the library index:
>
> ```yaml
> type: symlink
> source: /Users/alice/security-notes
> ```
>
> The librarian will read directly from `/Users/alice/security-notes` — no
> cloning required. Changes to that directory are immediately visible.
