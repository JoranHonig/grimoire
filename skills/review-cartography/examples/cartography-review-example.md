# Example: Cartography Review Cycle

A worked example showing the review of a "Secret Retrieval" cartography file from the
VaultBridge project. Demonstrates finding and correcting four common issues: a missing entry
point, an outdated file path, a missing cross-reference, and a new security note.

## Original Flow File (Before Review)

```markdown
---
name: Secret Retrieval
description: How secrets are fetched, decrypted, and returned to the client
created: 2026-02-16
updated: 2026-02-16
tags: [crypto, data-flow, kms]
---

## Overview

The secret retrieval flow handles authenticated requests to read stored secrets. It involves
permission checks, KMS key unwrapping, and client-side decryption.

## Entry Points

- `gateway/src/routes/secrets.ts:getSecret` — HTTP GET /api/v1/vaults/:id/secrets/:name
- `core/src/handlers/secret_handler.rs:handle_get_secret` — gRPC handler

## Key Components

- `core/src/authz/policy.rs` — RBAC permission evaluation
- `core/src/crypto/envelope.rs` — DEK unwrapping and envelope decryption
- `core/src/crypto/kms_client.rs` — AWS KMS integration for KEK operations
- `core/src/storage/vault_store.rs` — fetches encrypted blob and wrapped DEK

## Flow Sequence

1. Client sends GET request (`gateway/src/routes/secrets.ts:getSecret`)
2. Gateway auth middleware validates session (`gateway/src/middleware/auth.ts:validateSession`)
3. Core evaluates RBAC policy (`core/src/authz/policy.rs:evaluate`)
4. Core fetches encrypted blob + wrapped DEK (`core/src/storage/vault_store.rs:get_secret`)
5. Core unwraps DEK via KMS (`core/src/crypto/kms_client.rs:unwrap_key`)
6. Core returns encrypted blob + unwrapped DEK to client

## Security Notes

- Trust boundary between gateway authz and core authz — are they consistent?
- DEK is in plaintext in transit from core to client (relies on TLS)
- TOCTOU: permission check (step 3) and data fetch (step 4) are separate queries
```

## Review Findings

Each helper pass reports independently:

- **Entry points helper pass:** Found `cli/src/commands/get_secret.rs:run` — a CLI entry point
  added after initial mapping. File exists, handler dispatches to the same core gRPC path.
- **Key components helper pass:** `core/src/crypto/envelope.rs` was renamed to
  `core/src/crypto/decrypt.rs` in a recent refactor. Current path is stale.
- **Flow sequence helper pass:** Sequence is missing a step — a request validation middleware
  (`gateway/src/middleware/validate.ts:validateRequest`) was added between auth and core
  dispatch.
- **Security notes helper pass:** New audit logging was added at step 5, but it logs the secret
  name in plaintext — potential information disclosure via log access.

## Corrected Flow File (After Review)

```markdown
---
name: Secret Retrieval
description: How secrets are fetched, decrypted, and returned to the client via the retrieval API
created: 2026-02-16
updated: 2026-03-10
tags: [crypto, data-flow, kms, retrieval]
related: [secret-creation, key-rotation]
---

## Overview

The secret retrieval flow handles authenticated requests to read stored secrets from a vault.
It spans the API gateway, CLI, core service, and AWS KMS. This is the primary path through
which stored credentials can be exfiltrated if any step is compromised.

## Entry Points

- `gateway/src/routes/secrets.ts:getSecret` — HTTP GET /api/v1/vaults/:id/secrets/:name
- `core/src/handlers/secret_handler.rs:handle_get_secret` — gRPC handler invoked by gateway
- `cli/src/commands/get_secret.rs:run` — CLI command, dispatches to same gRPC handler

## Key Components

- `gateway/src/middleware/auth.ts` — session validation
- `gateway/src/middleware/validate.ts` — request schema validation
- `core/src/authz/policy.rs` — RBAC permission evaluation for vault access
- `core/src/crypto/decrypt.rs` — DEK unwrapping and envelope decryption
- `core/src/crypto/kms_client.rs` — AWS KMS integration for KEK operations
- `core/src/storage/vault_store.rs` — fetches encrypted blob and wrapped DEK

## Flow Sequence

1. Client sends authenticated GET request (`gateway/src/routes/secrets.ts:getSecret`)
2. Gateway auth middleware validates session (`gateway/src/middleware/auth.ts:validateSession`)
3. Gateway validates request schema (`gateway/src/middleware/validate.ts:validateRequest`)
4. Gateway forwards to core via gRPC (`core/src/handlers/secret_handler.rs:handle_get_secret`)
5. Core evaluates RBAC policy (`core/src/authz/policy.rs:evaluate`)
6. Core fetches encrypted blob + wrapped DEK (`core/src/storage/vault_store.rs:get_secret`)
7. Core unwraps DEK via KMS (`core/src/crypto/kms_client.rs:unwrap_key`)
8. Core returns encrypted blob + unwrapped DEK to client

## Security Notes

- Trust boundary between gateway authz and core authz — are they consistent?
- DEK is in plaintext in transit from core to client (relies on TLS)
- TOCTOU: permission check (step 5) and data fetch (step 6) are separate queries
- Audit logger at step 6 logs secret name in plaintext — information disclosure via log access

## Related Flows

- [[cartography/secret-creation]] — the write path; same authz checks
- [[cartography/key-rotation]] — KEK rotation affects the unwrap step
```

## Why This Review Works

- **Independent verification.** Each helper pass checked actual code, not just path existence.
  The renamed file (`envelope.rs` to `decrypt.rs`) was caught because the helper pass read the
  directory listing, not just tested `[ -f path ]`.
- **No bloat.** Four issues found, four things fixed. The file gained a few lines from the new
  entry point and sequence step but stayed well under 80 lines.
- **Reciprocal links.** Adding `related: [secret-creation, key-rotation]` here means also
  updating those two files to include `secret-retrieval` in their `related` lists.
- **Security notes preserved.** All three original notes were kept. One new note was added
  based on the audit logging change discovered during verification.
