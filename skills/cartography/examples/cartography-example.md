# Example Cartography File

This is a worked example of a cartography file for the VaultBridge project. It documents the
"Secret Retrieval" flow.

---

```markdown
---
name: Secret Retrieval
description: How secrets are fetched, decrypted, and returned to the client via the retrieval API
created: 2026-02-16
updated: 2026-02-18
tags: [crypto, data-flow, kms, retrieval]
related: [secret-creation, key-rotation]
---

## Overview

The secret retrieval flow handles authenticated requests to read stored secrets from a vault. It
spans the API gateway, core service, and AWS KMS — involving session authentication, RBAC policy
evaluation, key unwrapping, and client-side decryption. This is the primary path through which
stored credentials can be exfiltrated if any step is compromised.

## Entry Points

- `gateway/src/routes/secrets.ts:getSecret` — HTTP GET /api/v1/vaults/:id/secrets/:name
- `core/src/handlers/secret_handler.rs:handle_get_secret` — gRPC handler invoked by gateway

## Key Components

- `gateway/src/middleware/auth.ts` — session validation, extracts user identity from Redis-backed session
- `gateway/src/middleware/rate_limit.ts` — rate limiting on secret access endpoints
- `core/src/authz/policy.rs` — RBAC permission evaluation for vault access
- `core/src/authz/roles.rs` — role definitions and hierarchy
- `core/src/crypto/envelope.rs` — DEK unwrapping and envelope decryption helpers
- `core/src/crypto/kms_client.rs` — AWS KMS integration for KEK unwrap operations
- `core/src/storage/vault_store.rs` — fetches encrypted blob and wrapped DEK from PostgreSQL

## Flow Sequence

1. Client sends authenticated GET request (`gateway/src/routes/secrets.ts:getSecret`)
2. Gateway rate limiter checks request against per-user limits (`gateway/src/middleware/rate_limit.ts`)
3. Gateway auth middleware validates session token against Redis (`gateway/src/middleware/auth.ts:validateSession`)
4. Gateway serializes request and forwards to core service via gRPC
5. Core evaluates RBAC policy for the requesting user against the target vault (`core/src/authz/policy.rs:evaluate`)
6. Core fetches encrypted blob + wrapped DEK from PostgreSQL (`core/src/storage/vault_store.rs:get_secret`)
7. Core sends wrapped DEK to AWS KMS for unwrapping (`core/src/crypto/kms_client.rs:unwrap_key`)
8. Core returns encrypted blob + unwrapped DEK to gateway, gateway proxies to client
9. Client decrypts blob locally using the DEK

## Security Notes

- Trust boundary: gateway performs session auth, core performs RBAC — a request that passes gateway auth
  but targets a vault the user lacks access to should be caught at step 5. Verify both layers are
  consistent and that gateway doesn't cache stale permission grants.
- TOCTOU: permission check (step 5) and data fetch (step 6) are separate database queries. A permission
  revocation between the two queries could leak a secret.
- DEK is transmitted in plaintext from core to client (step 8). This relies entirely on TLS for
  confidentiality. No application-layer encryption on this leg.
- KMS latency in step 7 could enable a timing side-channel to distinguish "secret exists but no access"
  from "secret does not exist" — the KMS call only happens after a successful fetch.
- Rate limiter (step 2) is per-user but does not account for team/service-account tokens, which could
  allow higher volume enumeration.

## Conditional: Shared Vault Access

<!-- condition: load only when investigating shared vaults, team-level access, or cross-team secret sharing -->

Shared vaults allow multiple teams to access the same secret store. The permission path differs:

### Entry Points

- `core/src/authz/sharing.rs:evaluate_shared_access` — additional policy check for shared vaults

### Key Components

- `core/src/authz/sharing.rs` — shared vault permission logic, checks team membership + vault sharing grants
- `core/src/storage/sharing_store.rs` — tracks which vaults are shared with which teams

### Flow Sequence

1. Steps 1-4 from main flow
2. Core detects vault is shared (`core/src/storage/vault_store.rs:get_secret` returns sharing metadata)
3. Core evaluates shared access policy (`core/src/authz/sharing.rs:evaluate_shared_access`)
4. If shared access granted, continues from step 6 of main flow

### Security Notes

- Shared access grants are cached in Redis for performance — stale cache entries could outlive revocation
- Team membership changes should invalidate shared access, but this relies on an async event pipeline

## Related Flows

- [[cartography/secret-creation]] — the write path; same authz checks but different crypto direction
- [[cartography/key-rotation]] — KEK rotation affects the unwrap step; during rotation grace period,
  both old and new KEKs may be valid
```
