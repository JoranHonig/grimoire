# Example: Add a Git Library

A researcher wants to add the `smart-contract-vulnerabilities` knowledge base
so the librarian can reference it when answering questions about ERC token
flaws and common DeFi attack patterns.

---

**User prompt:**

> Add the smart-contract-vulnerabilities library from git@github.com:kadenzipfel/smart-contract-vulnerabilities.git

---

## Skill execution

### Step 1 — Parse intent

The request is unambiguous:

| Field | Value |
|-------|-------|
| operation | add |
| name | `smart-contract-vulnerabilities` |
| type | `git` |
| source | `git@github.com:kadenzipfel/smart-contract-vulnerabilities.git` |

All required fields are present. Proceed to validation.

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
print('entry: present' if 'smart-contract-vulnerabilities' in libs else 'entry: absent')
"
entry: absent
```

Good — the name is available.

**Validate the git URL:**

```bash
$ git ls-remote git@github.com:kadenzipfel/smart-contract-vulnerabilities.git HEAD
d3f1a2b4c5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0	HEAD
```

Exit code 0. The repository is reachable and valid.

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

data['libraries']['smart-contract-vulnerabilities'] = {
    'type': 'git',
    'source': 'git@github.com:kadenzipfel/smart-contract-vulnerabilities.git',
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
  smart-contract-vulnerabilities:
    type: git
    source: git@github.com:kadenzipfel/smart-contract-vulnerabilities.git
```

---

### Step 4 — Report

> Added `smart-contract-vulnerabilities` to the library index:
>
> ```yaml
> type: git
> source: git@github.com:kadenzipfel/smart-contract-vulnerabilities.git
> ```
>
> The librarian will use this library when answering questions about smart
> contract vulnerabilities. To fetch it into the local library directory, ask
> the librarian to pull its libraries.
