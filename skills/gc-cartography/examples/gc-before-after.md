# GC Cartography Example: Before and After

This example shows two overlapping cartography flows being merged into one consolidated flow.

## Scenario

During an audit of a vault service, two flows were mapped independently:

- **Secret Retrieval** — mapped from the HTTP API perspective
- **Vault Read Path** — mapped from the storage layer perspective

They share 5 of 8 components (62.5% overlap) and describe the same logical operation.

---

## Before: Two Overlapping Flows

### Flow A: `grimoire/cartography/secret-retrieval.md`

```markdown
---
name: Secret Retrieval
description: How secrets are fetched, decrypted, and returned to the client
created: 2026-02-10
updated: 2026-02-10
tags: [crypto, data-flow, kms]
related: [secret-creation, key-rotation]
---

## Overview

The secret retrieval flow handles authenticated requests to read stored secrets. It involves
permission checks, KMS key unwrapping, and client-side decryption. Security-critical because
it is the primary path to exfiltrating stored credentials.

## Entry Points

- `gateway/src/routes/secrets.ts:getSecret` — HTTP GET /api/v1/vaults/:id/secrets/:name

## Key Components

- `gateway/src/middleware/auth.ts` — session validation and JWT verification
- `core/src/authz/policy.rs` — RBAC permission evaluation for vault access
- `core/src/handlers/secret_handler.rs` — request routing and validation
- `core/src/crypto/envelope.rs` — DEK unwrapping and envelope decryption
- `core/src/crypto/kms_client.rs` — AWS KMS integration for KEK operations
- `core/src/storage/vault_store.rs` — fetches encrypted blob from PostgreSQL
- `core/src/audit/logger.rs` — audit trail for secret access events
- `gateway/src/middleware/rate_limit.ts` — per-user rate limiting on read operations

## Flow Sequence

1. Client sends GET request to gateway (`gateway/src/routes/secrets.ts:getSecret`)
2. Gateway validates session (`gateway/src/middleware/auth.ts:validateSession`)
3. Gateway applies rate limit (`gateway/src/middleware/rate_limit.ts:check`)
4. Gateway forwards to core via gRPC (`core/src/handlers/secret_handler.rs:handle_get_secret`)
5. Core evaluates RBAC policy (`core/src/authz/policy.rs:evaluate`)
6. Core fetches encrypted blob + wrapped DEK (`core/src/storage/vault_store.rs:get_secret`)
7. Core unwraps DEK via KMS (`core/src/crypto/kms_client.rs:unwrap_key`)
8. Core decrypts using DEK (`core/src/crypto/envelope.rs:decrypt`)
9. Core logs access event (`core/src/audit/logger.rs:log_access`)
10. Core returns decrypted secret to client

## Security Notes

- Trust boundary between gateway authz and core authz — are they consistent?
- DEK is in plaintext in memory between steps 7-8 — window for memory dump
- Rate limiting (step 3) is per-user but not per-IP — credential stuffing risk
- Audit log (step 9) happens after decryption — if step 8 fails, is access still logged?
```

### Flow B: `grimoire/cartography/vault-read-path.md`

```markdown
---
name: Vault Read Path
description: Storage layer read path for retrieving encrypted vault entries
created: 2026-02-14
updated: 2026-02-14
tags: [storage, crypto, database]
related: [vault-write-path]
---

## Overview

The read path through the vault storage layer. Covers how encrypted entries are fetched from
the database, decrypted, and returned. Focus on the storage and crypto layers.

## Entry Points

- `core/src/handlers/secret_handler.rs:handle_get_secret` — gRPC handler for read requests

## Key Components

- `core/src/handlers/secret_handler.rs` — request routing and input validation
- `core/src/authz/policy.rs` — permission checks before data access
- `core/src/storage/vault_store.rs` — PostgreSQL queries for encrypted blobs
- `core/src/storage/cache.rs` — LRU cache for frequently accessed secrets
- `core/src/crypto/envelope.rs` — envelope decryption with DEK
- `core/src/crypto/kms_client.rs` — KMS key operations
- `core/src/crypto/key_cache.rs` — DEK cache to reduce KMS calls

## Flow Sequence

1. Handler receives gRPC request (`core/src/handlers/secret_handler.rs:handle_get_secret`)
2. Handler checks permissions (`core/src/authz/policy.rs:evaluate`)
3. Handler checks secret cache (`core/src/storage/cache.rs:get`)
4. On cache miss: fetch from database (`core/src/storage/vault_store.rs:get_secret`)
5. Check DEK cache (`core/src/crypto/key_cache.rs:get_dek`)
6. On DEK cache miss: unwrap via KMS (`core/src/crypto/kms_client.rs:unwrap_key`)
7. Decrypt envelope (`core/src/crypto/envelope.rs:decrypt`)
8. Populate caches (`core/src/storage/cache.rs:put`, `core/src/crypto/key_cache.rs:put_dek`)
9. Return decrypted secret

## Security Notes

- Secret cache (step 3) stores decrypted values in memory — cache poisoning vector?
- DEK cache (step 5) keeps key material in memory — how long? What eviction policy?
- Cache population (step 8) happens after successful decrypt — but is cache write atomic?
- No audit logging in this path — relies on caller to log
```

### Overlap Analysis

**Shared components (5):**
- `core/src/handlers/secret_handler.rs`
- `core/src/authz/policy.rs`
- `core/src/storage/vault_store.rs`
- `core/src/crypto/envelope.rs`
- `core/src/crypto/kms_client.rs`

**Unique to Flow A (3):** `gateway/src/middleware/auth.ts`, `core/src/audit/logger.rs`,
`gateway/src/middleware/rate_limit.ts`

**Unique to Flow B (2):** `core/src/storage/cache.rs`, `core/src/crypto/key_cache.rs`

**Overlap:** 5 / max(8, 7) = 5 / 8 = **62.5%** — exceeds 40% threshold

**Decision:** Merge. Both flows describe the same read operation. Flow A covers the full
gateway-to-response path. Flow B adds storage-layer detail (caching). Flow A is the primary
because it has more components, more security notes, and broader scope. Flow B's caching
detail becomes a conditional section.

---

## After: Merged Flow

### `grimoire/cartography/secret-retrieval.md`

```markdown
---
name: Secret Retrieval
description: How secrets are fetched, decrypted, and returned — from gateway through storage layer caching
created: 2026-02-10
updated: 2026-03-10
tags: [crypto, data-flow, kms, storage, database]
related: [secret-creation, key-rotation, vault-write-path]
---

## Overview

The secret retrieval flow handles authenticated requests to read stored secrets. Covers the
full path from HTTP gateway through RBAC, storage, KMS key unwrapping, envelope decryption,
and caching. Security-critical because it is the primary path to exfiltrating stored
credentials.

## Entry Points

- `gateway/src/routes/secrets.ts:getSecret` — HTTP GET /api/v1/vaults/:id/secrets/:name
- `core/src/handlers/secret_handler.rs:handle_get_secret` — gRPC handler for read requests

## Key Components

- `gateway/src/middleware/auth.ts` — session validation and JWT verification
- `gateway/src/middleware/rate_limit.ts` — per-user rate limiting on read operations
- `core/src/handlers/secret_handler.rs` — request routing and validation
- `core/src/authz/policy.rs` — RBAC permission evaluation for vault access
- `core/src/storage/vault_store.rs` — PostgreSQL queries for encrypted blobs
- `core/src/storage/cache.rs` — LRU cache for frequently accessed secrets
- `core/src/crypto/envelope.rs` — DEK unwrapping and envelope decryption
- `core/src/crypto/kms_client.rs` — AWS KMS integration for KEK operations
- `core/src/crypto/key_cache.rs` — DEK cache to reduce KMS calls
- `core/src/audit/logger.rs` — audit trail for secret access events

## Flow Sequence

1. Client sends GET request to gateway (`gateway/src/routes/secrets.ts:getSecret`)
2. Gateway validates session (`gateway/src/middleware/auth.ts:validateSession`)
3. Gateway applies rate limit (`gateway/src/middleware/rate_limit.ts:check`)
4. Gateway forwards to core via gRPC (`core/src/handlers/secret_handler.rs:handle_get_secret`)
5. Core evaluates RBAC policy (`core/src/authz/policy.rs:evaluate`)
6. Core fetches encrypted blob + wrapped DEK (`core/src/storage/vault_store.rs:get_secret`)
7. Core unwraps DEK via KMS (`core/src/crypto/kms_client.rs:unwrap_key`)
8. Core decrypts using DEK (`core/src/crypto/envelope.rs:decrypt`)
9. Core logs access event (`core/src/audit/logger.rs:log_access`)
10. Core returns decrypted secret to client

## Conditional: Storage Layer Caching

<!-- condition: load only when investigating cache behavior, cache poisoning, key material caching, or performance-related security concerns -->

The storage layer includes two caches that short-circuit the main flow sequence:

1. **Secret cache** (`core/src/storage/cache.rs`) — LRU cache of decrypted secrets. On hit,
   skips steps 6-8 entirely. Checked before database fetch.
2. **DEK cache** (`core/src/crypto/key_cache.rs`) — caches unwrapped DEKs to reduce KMS
   calls. On hit, skips step 7. Checked before KMS unwrap.

Cached flow sequence:
1. Handler receives request (step 4 in main flow)
2. Handler checks permissions (step 5)
3. Check secret cache (`core/src/storage/cache.rs:get`) — if hit, skip to step 7
4. On miss: fetch from database (step 6)
5. Check DEK cache (`core/src/crypto/key_cache.rs:get_dek`) — if hit, skip to step 7
6. On miss: unwrap via KMS (step 7 in main flow)
7. Decrypt and return (steps 8-10)
8. Populate caches (`core/src/storage/cache.rs:put`, `core/src/crypto/key_cache.rs:put_dek`)

## Security Notes

- Trust boundary between gateway authz and core authz — are they consistent?
- DEK is in plaintext in memory between steps 7-8 — window for memory dump
- Rate limiting (step 3) is per-user but not per-IP — credential stuffing risk
- Audit log (step 9) happens after decryption — if step 8 fails, is access still logged?
- Secret cache stores decrypted values in memory — cache poisoning vector?
- DEK cache keeps key material in memory — how long? What eviction policy?
- Cache population happens after successful decrypt — but is cache write atomic?
- No audit logging in cached path — relies on caller to log

## Related Flows

- [[cartography/secret-creation]] — the write path for secrets
- [[cartography/key-rotation]] — KEK rotation affects the unwrap step in this flow
- [[cartography/vault-write-path]] — the write counterpart to this read path
```

### What Changed

| Aspect | Before | After |
|--------|--------|-------|
| Files | 2 (`secret-retrieval.md`, `vault-read-path.md`) | 1 (`secret-retrieval.md`) |
| Components | 8 + 7 (5 shared) | 10 (deduplicated union) |
| Entry Points | 1 + 1 | 2 (union) |
| Security Notes | 4 + 4 | 8 (all preserved) |
| Tags | 3 + 3 | 5 (union) |
| Related | 2 + 1 | 3 (union, absorbed slug removed) |
| Conditional sections | 0 | 1 (caching detail from absorbed flow) |

### Cross-Reference Cleanup

After the merge, `vault-read-path.md` was deleted. Any file referencing it needs updating:

- `grimoire/cartography/vault-write-path.md`: `related: [vault-read-path]` updated to
  `related: [secret-retrieval]`
- `GRIMOIRE.md`: `[[cartography/vault-read-path]]` link updated to
  `[[cartography/secret-retrieval]]`
