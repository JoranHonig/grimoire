# Example: Cross-Service Authentication Flow

This is a worked example of a more complex cartography file — a cross-service authentication
flow spanning multiple services with two conditional sections. Compare with
`cartography-example.md` (single-service, one conditional) to see how conditional sections
scale.

---

```markdown
---
name: User Authentication
description: End-to-end authentication flow from login form through token issuance, session creation, and downstream service authorization
created: 2026-03-10
updated: 2026-03-12
tags: [auth, session, jwt, rbac, cross-service]
related: [password-reset, token-refresh, service-mesh-authz]
---

## Overview

The user authentication flow handles credential submission, identity verification, token
issuance, and session propagation across three services (API gateway, auth service, user
service). It is the primary trust establishment path — a bypass at any stage grants full
account access. The flow branches into OAuth and passkey sub-flows that use different
verification paths but converge at token issuance.

## Entry Points

- `gateway/src/routes/auth.ts:login` — POST /api/v1/auth/login
- `gateway/src/routes/auth.ts:loginCallback` — GET /api/v1/auth/callback (OAuth return)
- `auth-service/src/grpc/auth_server.py:Authenticate` — gRPC handler for internal auth requests

## Key Components

- `gateway/src/middleware/csrf.ts` — CSRF token validation on login form submission
- `gateway/src/middleware/rate_limit.ts` — brute-force protection on login endpoints
- `auth-service/src/grpc/auth_server.py` — gRPC service handling authentication requests
- `auth-service/src/providers/credential.py` — password hashing and comparison (argon2id)
- `auth-service/src/token/issuer.py` — JWT creation, signing (ES256), claims population
- `auth-service/src/token/keys.py` — signing key rotation and JWKS endpoint backing
- `auth-service/src/session/store.py` — Redis session creation with configurable TTL
- `user-service/src/grpc/user_server.go` — user record lookup and status checks
- `user-service/src/repo/user_repo.go` — PostgreSQL user store with soft-delete awareness

## Flow Sequence

1. Client submits credentials via POST (`gateway/src/routes/auth.ts:login`)
2. Gateway validates CSRF token (`gateway/src/middleware/csrf.ts:validate`)
3. Gateway checks brute-force rate limit (`gateway/src/middleware/rate_limit.ts:checkLogin`)
4. Gateway forwards credentials to auth service via gRPC (`auth-service/src/grpc/auth_server.py:Authenticate`)
5. Auth service requests user record from user service (`user-service/src/grpc/user_server.go:GetUser`)
6. User service fetches record from PostgreSQL (`user-service/src/repo/user_repo.go:FindByEmail`)
7. Auth service verifies password against stored hash (`auth-service/src/providers/credential.py:verify`)
8. Auth service issues JWT with user claims (`auth-service/src/token/issuer.py:issue`)
9. Auth service creates Redis session (`auth-service/src/session/store.py:create`)
10. Gateway sets session cookie and returns JWT to client

## Security Notes

- Rate limiter (step 3) keys on IP + email pair — distributed attacks across IPs with a fixed
  email are caught, but credential stuffing across many emails from one IP may slip through.
- User lookup (step 6) does not distinguish "user not found" from "user soft-deleted" in the
  gRPC response — auth service treats both as invalid credentials. Verify this doesn't leak
  account existence via timing.
- Password verification (step 7) uses argon2id with server-side timing — but the gRPC round
  trip to user-service (step 5-6) adds variable latency that could mask or reveal the
  verify step's constant-time properties.
- JWT signing key (step 8) rotation is manual via config reload. If key rotation is delayed,
  compromised keys have unbounded validity.
- Session TTL (step 9) defaults to 24h but is overridden per-environment in config. Check
  whether staging/dev environments use longer TTLs that could be exploited if accessible.
- CSRF validation (step 2) is skipped for requests with `Authorization: Bearer` header —
  verify this doesn't create a bypass when both cookie and bearer are present.

## Conditional: OAuth Provider Flow

<!-- condition: load only when investigating OAuth login, third-party identity providers, SSO, or the /callback endpoint -->

OAuth login replaces steps 4-7 of the main flow with provider-delegated verification.

### Entry Points

- `gateway/src/routes/auth.ts:loginCallback` — OAuth callback after provider redirect
- `auth-service/src/providers/oauth.py:handle_callback` — processes OAuth code exchange

### Key Components

- `auth-service/src/providers/oauth.py` — OAuth code exchange and profile mapping
- `auth-service/src/providers/registry.py` — registered OAuth providers and their configs
- `auth-service/src/providers/profile_mapper.py` — maps provider profile to internal user schema

### Flow Sequence

1. Steps 1-3 from main flow (CSRF + rate limit still apply)
2. Gateway redirects to OAuth provider authorize URL
3. User authenticates with provider, provider redirects to callback
4. Gateway receives callback (`gateway/src/routes/auth.ts:loginCallback`)
5. Auth service exchanges code for token (`auth-service/src/providers/oauth.py:exchange_code`)
6. Auth service fetches user profile from provider (`auth-service/src/providers/oauth.py:fetch_profile`)
7. Auth service maps provider profile to internal user (`auth-service/src/providers/profile_mapper.py:map_to_user`)
8. Continues from step 8 of main flow (JWT issuance + session)

### Security Notes

- OAuth state parameter must be validated to prevent CSRF on callback — check `handle_callback`
- Provider profile email may differ from internal user email — verify mapping doesn't allow
  account takeover by registering a matching email at the OAuth provider
- Code exchange (step 5) must use PKCE or server-side secret — check which flow is configured

## Conditional: Passkey / WebAuthn Flow

<!-- condition: load only when investigating passkeys, WebAuthn, FIDO2, or passwordless authentication -->

Passkey authentication replaces the password verification step (step 7) with a WebAuthn
challenge-response.

### Entry Points

- `auth-service/src/providers/webauthn.py:begin_authentication` — generates challenge
- `auth-service/src/providers/webauthn.py:complete_authentication` — verifies assertion

### Key Components

- `auth-service/src/providers/webauthn.py` — WebAuthn ceremony handling (challenge + verify)
- `auth-service/src/storage/credential_store.py` — stored public key credentials per user

### Flow Sequence

1. Steps 1-6 from main flow (user lookup still required to find registered credentials)
2. Auth service generates WebAuthn challenge (`auth-service/src/providers/webauthn.py:begin_authentication`)
3. Client performs WebAuthn ceremony with authenticator
4. Client sends signed assertion back
5. Auth service verifies assertion against stored credential (`auth-service/src/providers/webauthn.py:complete_authentication`)
6. Continues from step 8 of main flow (JWT issuance + session)

### Security Notes

- Challenge must be single-use and time-bounded — check if challenges are stored in Redis with TTL
- Credential store should enforce per-user credential limits to prevent DoS via credential flooding
- Verify that passkey flow cannot be downgraded to password flow without user confirmation

## Related Flows

- [[cartography/password-reset]] — shares the user lookup path (steps 5-6) and session creation
- [[cartography/token-refresh]] — uses the same JWT issuer but with refresh-specific claims
- [[cartography/service-mesh-authz]] — downstream services validate the JWT issued in step 8
```
