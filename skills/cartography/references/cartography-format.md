# Cartography File Format

This reference defines the format for cartography files stored in `grimoire/cartography/`.

## File Location

All cartography files live in `grimoire/cartography/` with a slugified filename derived from the
flow name: `grimoire/cartography/secret-retrieval.md`.

## Frontmatter

Every cartography file starts with YAML frontmatter:

```yaml
---
name: Secret Retrieval
description: How secrets are fetched, decrypted, and returned to the client
created: 2026-02-16
updated: 2026-02-16
tags: [crypto, data-flow, kms]
related: [key-rotation, secret-creation]
---
```

| Field         | Required | Description                                                    |
|---------------|----------|----------------------------------------------------------------|
| `name`        | yes      | Short flow name. Used in the index and for display.            |
| `description` | yes      | One-line description. Used in the index and for agent matching.|
| `created`     | yes      | ISO date when the file was first created.                      |
| `updated`     | yes      | ISO date of the last modification.                             |
| `tags`        | no       | Freeform categorization tags for filtering.                    |
| `related`     | no       | List of other cartography file slugs (without `.md`).          |

**Constraint:** `name` and `description` must each be a single line. The indexing script relies
on this.

## Body Sections

### Overview

2-3 sentences describing the flow and its security relevance. This is what an agent reads to
decide whether to load the full file.

```markdown
## Overview

The secret retrieval flow handles authenticated requests to read stored secrets. It involves
permission checks, KMS key unwrapping, and client-side decryption. Security-critical because it
is the primary path to exfiltrating stored credentials.
```

### Entry Points

List the entry points into this flow using `path/to/file:symbol` notation. Entry points are
where execution begins for this flow — API endpoints, CLI commands, event handlers, etc.

```markdown
## Entry Points

- `gateway/src/routes/secrets.ts:getSecret` — HTTP GET /api/v1/vaults/:id/secrets/:name
- `core/src/handlers/secret_handler.rs:handle_get_secret` — gRPC handler
```

### Key Components

Modules and files that participate in the flow, with a brief note on their role. This is the
navigation map — it tells you *where* to look, not *what the code does*.

```markdown
## Key Components

- `core/src/authz/policy.rs` — RBAC permission evaluation for vault access
- `core/src/crypto/envelope.rs` — DEK unwrapping and envelope decryption
- `core/src/crypto/kms_client.rs` — AWS KMS integration for KEK operations
- `core/src/storage/vault_store.rs` — fetches encrypted blob and wrapped DEK from PostgreSQL
```

### Flow Sequence

Numbered steps tracing execution through the system. Reference files at each step. Keep it
linear — branch points or conditional paths that are independently useful should go in
conditional sections.

```markdown
## Flow Sequence

1. Client sends GET request to gateway (`gateway/src/routes/secrets.ts:getSecret`)
2. Gateway middleware authenticates session (`gateway/src/middleware/auth.ts:validateSession`)
3. Gateway forwards to core via gRPC (`core/src/handlers/secret_handler.rs:handle_get_secret`)
4. Core evaluates RBAC policy (`core/src/authz/policy.rs:evaluate`)
5. Core fetches encrypted blob + wrapped DEK (`core/src/storage/vault_store.rs:get_secret`)
6. Core unwraps DEK via KMS (`core/src/crypto/kms_client.rs:unwrap_key`)
7. Core returns encrypted blob + unwrapped DEK to client
8. Client decrypts locally using DEK
```

### Security Notes

Trust boundaries, validation gaps, observations, and areas that warrant investigation. These
are the security researcher's annotations — the *reason* this flow matters.

```markdown
## Security Notes

- Trust boundary between gateway authz and core authz — are they consistent?
- DEK is in plaintext in transit from core to client (relies on TLS)
- Permission check (step 4) and data fetch (step 5) are separate queries — TOCTOU window?
- KMS call in step 6 could be used for a timing side-channel to enumerate valid secret IDs
```

### Conditional Sections

Optional sections for sub-flows that would pollute the main flow's context. An agent evaluates
the condition comment to decide whether to load the section.

```markdown
## Conditional: Shared Vault Access

<!-- condition: load only when investigating shared vaults, team-level access, or cross-team secret sharing -->

Shared vaults use a different permission path...
```

**Format:**
- Section heading: `## Conditional: [Sub-flow Name]`
- Condition comment: `<!-- condition: load only when [topic description] -->`
- Body follows the same patterns (entry points, components, sequence, notes) but scoped to the
  sub-flow

Use conditional sections when:
- The main flow body exceeds ~80 lines
- A sub-flow is only relevant for specific investigations
- Including the sub-flow would dilute the main flow's signal-to-noise ratio

### Related Flows

Cross-links to other cartography files. These should match the `related` field in frontmatter.

```markdown
## Related Flows

- [[cartography/secret-creation]] — the write path for secrets
- [[cartography/key-rotation]] — KEK rotation affects the unwrap step in this flow
```

## Key Constraint

**Cartography files are pointers, not containers.** They document *where* to look, not *what
the code does*. An agent reading a cartography file should know exactly which files to open and
in what order — but should read those files itself to understand the actual logic.

If you find yourself writing detailed code explanations, stop. Add the file path and a one-line
role description instead. Detailed analysis belongs in `grimoire/tomes/`.
