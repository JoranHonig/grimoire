# GRIMOIRE — VaultBridge

> Summoned: 2026-02-15

## Target

- **Language:** Rust (core), TypeScript (API gateway)
- **Build/Test:** Cargo, Jest, Docker Compose for integration tests
- **Frameworks:** Actix-web, Prisma, Redis (session/cache)
- **Integrations:** PostgreSQL, AWS KMS, Stripe API, OAuth2 providers (Google, GitHub)

## Problem & Approach

VaultBridge is a credential management platform that allows teams to store, rotate, and share
secrets (API keys, database credentials, certificates). It uses envelope encryption — secrets are
encrypted client-side with a data encryption key (DEK), and the DEK is wrapped with a key
encryption key (KEK) managed by AWS KMS. Access is controlled through a role-based permission
model with organization, team, and vault-level granularity.

## Scope

- **In-scope:** `vaultbridge-core` repository, `v2.3.x` branch. Covers `core/` (Rust service),
  `gateway/` (TypeScript API), and `spa/` (React client).
- **Out-of-scope:** Third-party KMS (AWS KMS) behavior; Stripe API integration; the
  `legacy-cli/` directory (slated for removal in v2.4). Source: client engagement letter §3.

### Capability assumptions (foreclose within granted capability)
- `org_admin` role: can invite users, assign roles, rotate keys — but cannot directly read
  secret payloads. Source: scope §4.1.
- `kms_client` IAM role: can only `kms:Encrypt`/`kms:Decrypt` on the project's KEK ARN.
  Source: `scope/iam-policy.json`.

### Trust assumptions (context only; do not foreclose findings)
- AWS KMS itself is assumed trusted — KMS service compromise is out of threat model.
  Source: scope §3.2.
- The SPA client environment is assumed not malicious at runtime (i.e., no attacker running
  code in the user's browser beyond XSS the application introduces). Source: scope §3.3.

### Protocol invariants (claimed to hold)
- A wrapped DEK is never persisted outside PostgreSQL. Source: design doc §2.
- Audit log entries are append-only once written. Source: scope §5.

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│  Web Client  │────▶│  API Gateway  │────▶│   Core Service   │
│  (React SPA) │     │  (TypeScript) │     │     (Rust)       │
└─────────────┘     └──────────────┘     └────────┬────────┘
                           │                       │
                    ┌──────┴──────┐         ┌──────┴──────┐
                    │   Redis     │         │  PostgreSQL  │
                    │ (sessions)  │         │  (metadata)  │
                    └─────────────┘         └─────────────┘
                                                   │
                                            ┌──────┴──────┐
                                            │   AWS KMS    │
                                            │ (KEK mgmt)   │
                                            └─────────────┘
```

- **API Gateway** (`gateway/`): Express + TypeScript. Handles auth, rate limiting, request
  validation. Routes to core service via gRPC.
- **Core Service** (`core/`): Rust/Actix-web. Business logic, encryption, permission checks.
- **Crypto module** (`core/src/crypto/`): Envelope encryption, key derivation, KMS integration.
- **Permissions** (`core/src/authz/`): RBAC engine. Policy evaluation happens here.
- **Storage** (`core/src/storage/`): Prisma-based persistence layer for vault metadata and
  encrypted blobs.

## Primary Flows

- **Secret creation:** Client encrypts payload with generated DEK → sends encrypted blob + DEK
  to gateway → gateway authenticates + authorizes → core wraps DEK with KMS KEK → stores
  encrypted blob + wrapped DEK in PostgreSQL. See [[tomes/secret-lifecycle]] for detail.
- **Secret retrieval:** Auth → permission check (vault + role) → fetch wrapped DEK + blob →
  unwrap DEK via KMS → return encrypted blob + DEK to client → client decrypts locally.
- **Key rotation:** Admin triggers rotation → core generates new KEK via KMS → re-wraps all
  DEKs in the vault → old KEK scheduled for deletion after grace period.
- **Team invitation:** Admin invites user → OAuth2 flow → user added to org → default role
  assigned → explicit vault access must be granted separately.
- **Audit log:** All secret access and permission changes logged to append-only audit table.
  Gateway middleware captures request metadata.

## Crown Jewels

- **Encrypted secrets + DEKs** — `core/src/storage/vault_store.rs`. Compromise of wrapped DEKs
  combined with KMS access = full secret exfiltration. Attack vectors: SQL injection in storage
  layer, IDOR on vault endpoints, broken access control on retrieval flow.
- **KMS credentials / IAM role** — `core/src/crypto/kms_client.rs`. If the service's AWS
  credentials are leaked or the IAM role is over-permissioned, attacker can unwrap DEKs directly.
  Attack vectors: SSRF to metadata endpoint, env variable leakage, log injection.
- **Session tokens** — `gateway/src/middleware/auth.ts`. Redis-backed sessions. Session fixation,
  token leakage, or broken invalidation on permission changes could grant unauthorized access.
  Attack vectors: cookie misconfiguration, missing invalidation on role change.
- **RBAC policy engine** — `core/src/authz/policy.rs`. Logic flaws here = privilege escalation.
  Attack vectors: role hierarchy bypass, implicit default permissions, TOCTOU between authz check
  and data access.

## Attack Surface Notes

- Gateway validates request shape but core re-validates permissions — check for discrepancies
  between gateway authz and core authz. Potential for bypass if gateway allows a request the core
  should reject.
- Key rotation grace period introduces a window where old KEKs remain active. Worth investigating
  whether a revoked user's cached DEK could still decrypt during this window.
- Audit log is append-only but check whether audit entries can be forged or suppressed by
  manipulating the gateway middleware.
- Client-side encryption means the web client has the DEK in memory. XSS in the SPA = full
  secret access for the user's vaults.

## Automation

No spellbook modules available yet. This is the first engagement.

Opportunities to build during this audit:
- Semgrep rules for missing authz checks on core service endpoints
- SQL injection pattern detection in the Prisma query layer
- RBAC policy consistency checker (compare gateway vs core permission definitions)

---

*Example of a populated Automation section from a later engagement:*

```
## Automation

Modules run on summon:
- `spells/missing-authz-check.yml` (semgrep) — 3 results, 1 confirmed, 2 false positives
- `spells/unvalidated-redirect.yml` (semgrep) — 0 results
- `spells/toctou-state-check.yml` (semgrep) — 7 results, triaging

Available but not run (user discretion):
- `spells/oracle-staleness-agent/` — agentic detector, high token cost
```
