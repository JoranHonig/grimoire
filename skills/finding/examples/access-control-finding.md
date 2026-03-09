# Example: Access Control Finding

A minimal valid finding for a missing authentication check on a backend API route.
Demonstrates a finding with no Details section and a PoC placeholder — the simplest
complete finding that satisfies all required fields and sections.

## Finding File

```markdown
---
title: Account takeover enabled by lack of authentication in backend route PUT /user
severity: Critical
type: access-control
context:
  - src/routes/user.js:34-52
  - src/middleware/auth.js
---

## Description

The `PUT /user` endpoint at `src/routes/user.js:34` allows updating any user's profile,
including email and password, without requiring authentication. The route handler directly
processes the request body and updates the user record identified by the `id` parameter.

An unauthenticated attacker can send a PUT request to `/user/:id` with arbitrary profile
data, overwriting the target user's email and password. This enables full account takeover
of any user. No privileges or preconditions are required — the endpoint is publicly
accessible.

The `auth.js` middleware exists and is applied to other routes (`GET /user`, `DELETE /user`)
but is missing from the `PUT` handler's middleware chain.

## Proof of Concept

No PoC yet — run `/write-poc` to generate one.

## Recommendation

Add the authentication middleware to the `PUT /user` route handler's middleware chain,
consistent with the other user endpoints.
```

## Why This Finding Works

- **Title.** Where (PUT /user backend route), how (lack of authentication), what (account
  takeover). All three elements present.
- **No Details section.** The vulnerability mechanism is straightforward — a missing
  middleware application. The Description covers it completely. Adding Details would be
  redundant.
- **Severity: Critical.** No authentication required, any user account can be taken over,
  no preconditions. The Description justifies this without overstating.
- **Self-contained.** Explains what the endpoint does, what the flaw is, why auth.js should
  be there (it's on other routes), and exactly what an attacker can do.
- **PoC placeholder.** Honestly states no PoC exists yet and directs to the appropriate
  skill. This is better than omitting the section or fabricating a PoC.
- **Minimal recommendation.** One sentence. Names what to do (add middleware) and why
  (consistency with other endpoints). Does not suggest how to rewrite the route.
- **No References section.** Not every finding needs references. A missing auth middleware
  is self-evidently a problem — no external citation needed.
