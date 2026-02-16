---
name: Write Proof of Concept
description: >-
  This skill should be used when the user asks to "write a proof of concept",
  "create a PoC", "demonstrate a vulnerability", "write an exploit PoC",
  "show this bug is exploitable", "prove this vulnerability exists",
  "PoC for CVE", "demonstrate the impact", or needs to create a working
  demonstration of a security vulnerability for responsible disclosure
  and remediation purposes.
---

# Write Proof of Concept

## Purpose

Assist security researchers in writing clear, effective proof-of-concept code that
demonstrates discovered vulnerabilities. PoCs serve as evidence for project maintainers
to understand, reproduce, and fix security issues. Every PoC produced under this skill
assumes an authorized security research context — pentesting engagements, bug bounty
programs, coordinated disclosure, or CTF challenges.

## PoC Writing Workflow

Follow these steps in order when writing a proof of concept.

### 1. Gather Vulnerability Details

Before writing any code, establish the following:

- **Vulnerability class** — What type of issue is it? (e.g., SQL injection, buffer overflow, SSRF, auth bypass, race condition)
- **Affected component** — Which file, endpoint, function, or binary is vulnerable?
- **Root cause** — What is the underlying flaw? (e.g., unsanitized input, missing bounds check, TOCTOU)
- **Attack surface** — How is the vulnerable component reached? (e.g., HTTP request, CLI argument, file upload, IPC)
- **Prerequisites** — What conditions must be true? (e.g., authenticated user, specific configuration, network access)
- **Impact** — What can an attacker achieve? (e.g., RCE, data exfiltration, privilege escalation, DoS)

If any detail is unclear, ask the user before proceeding. A PoC built on incorrect assumptions wastes time.

Study both the impacted code and the issue description provided by the user, make sure to understand the exploit flow deeply.

### 2. Determine PoC Approach

Select the minimal demonstration that proves the vulnerability exists and conveys its impact.
Follow the principle of **minimum viable proof** — demonstrate the issue without going beyond
what is necessary.

Primary PoC approaches:
* Test Case (preferred)
* Python Script

**Test Case Proof of Concepts**

Analyze whether it is possible to write the proof of concept as a test case to extend an existing test suite. Determine the best place to put the proof of concept code if that's the case. Then ask the user i they would like to extend the test suite and if this location is correct.

When the target is a smart contract, ask the user whether to use a **fork test** (live on-chain
state) or a **unit test** (self-contained, synthetic state) before proceeding. Consult
**`references/smart-contracts.md`** for detailed templates, conventions, and vulnerability patterns.

**Alternative Approaches**

The preferred method (after test cases) is a single python script that leverages click and loguru.

**Notes**

When multiple approaches work, prefer the one that is **simplest to reproduce** for the
maintainer receiving the report.

### 3. Write the PoC

Structure every PoC with these elements:

**Header block (comment at top of file):**
```
Title:        [Short descriptive title]
Vulnerability: [CWE ID if known, or class name]
Affected:     [Component, version, file/endpoint]
Impact:       [One-line impact statement]
Author:       [Researcher name/handle]
Date:         [Date written]
Context:      [Bug bounty program / pentest engagement / coordinated disclosure]
```

**Implementation guidelines:**

- **Use benign payloads.** Demonstrate the vulnerability without causing harm. For example, use
  `alert(1)` or `<img src=x>` for XSS, `sleep()` for SQL injection, `id` or `whoami` for
  command injection, `127.0.0.1` for SSRF. Avoid destructive payloads.
- **Target localhost or placeholder addresses.** Never hardcode production targets. Use
  variables or arguments for the target so the maintainer can point it at their own test
  environment.
- **Add clear comments.** Annotate each significant step explaining *what* it does and *why*
  it matters for the exploit chain. Maintainers need to understand the logic to write a fix.
- **Handle errors gracefully.** Include basic error handling so the PoC fails informatively
  rather than silently or with a cryptic traceback.
- **Print clear output.** Indicate success or failure explicitly. Example: `[+] Vulnerability
  confirmed: server returned injected content` or `[-] Target does not appear vulnerable`.
- **Keep dependencies minimal.** Prefer standard libraries. If external dependencies are
  required, document them in a requirements section.

### 4. Select Output Format

Adapt the deliverable format to the vulnerability and audience:

- **Standalone script** — Most common. A single `.py`, `.sh`, or `.rb` file that reproduces
  the issue end-to-end. Best for: injection flaws, auth bypasses, race conditions.
- **curl command(s)** — For simple HTTP-based issues where a script is overkill. Best for:
  IDOR, open redirects, header injection, simple SSRF.
- **Code snippet + explanation** — When the vulnerability is in source code and the PoC is
  a specific input or configuration. Best for: logic bugs, crypto weaknesses, unsafe defaults.
- **Multi-step reproduction** — Numbered steps mixing commands, code, and explanation. Best
  for: complex chains, multi-stage attacks, privilege escalation paths.

For detailed format guidance per vulnerability class, consult **`references/poc-formats.md`**.

### 5. Add Context and Remediation

After the PoC code, include:

- **Reproduction steps** — Numbered list a maintainer can follow to confirm the issue.
  Assume they have access to the source code and a local test environment.
- **Impact analysis** — Concrete description of what an attacker could achieve. Avoid
  hyperbole; be precise. State the worst realistic outcome.
- **Suggested remediation** — Recommend a fix direction. Reference specific functions,
  libraries, or patterns where possible (e.g., "use parameterized queries", "add CSRF token
  validation", "apply bounds checking at line N").
- **References** — Link to relevant CWEs, CVEs, or advisories if applicable.

### 6. Review Before Delivery

Before finalizing, verify:

- [ ] PoC actually demonstrates the vulnerability (not just a theoretical description)
- [ ] No destructive payloads or actions
- [ ] Target is parameterized (not hardcoded to a live system)
- [ ] Comments explain the exploit chain clearly
- [ ] Output clearly indicates success or failure
- [ ] Dependencies are documented
- [ ] Reproduction steps are complete and ordered
- [ ] Remediation suggestion is actionable

## Language Selection

Choose the implementation language based on context:

- **Python** — Default choice for most PoCs. Rich standard library, readable, widely
  understood by developers across ecosystems.
- **Bash/curl** — Simple HTTP-based PoCs, quick one-liners, pipeline demonstrations.
- **C** — Memory corruption, binary exploitation, kernel issues.
- **JavaScript/TypeScript** — Browser-based vulnerabilities, Node.js issues, DOM-based XSS.
- **Ruby** — Ruby/Rails-specific vulnerabilities.
- **Go/Rust** — When the target is written in these languages and reproduction requires it.
- **Solidity (Foundry)** — Smart contract vulnerabilities. See `references/smart-contracts.md`.

Match the language to the target ecosystem when possible — a Rails developer will understand
a Ruby PoC faster than a Python one.

## Additional Resources

### Reference Files

For detailed patterns and format guidance, consult:

- **`references/poc-formats.md`** — Detailed output format templates and examples for each
  vulnerability class
- **`references/vulnerability-patterns.md`** — Common vulnerability patterns, root causes,
  and demonstration approaches organized by class
- **`references/smart-contracts.md`** — Smart contract PoC approach selection, Foundry
  templates, cheatcode conventions, and vulnerability patterns
