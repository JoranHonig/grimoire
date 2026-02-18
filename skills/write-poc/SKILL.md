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

Check in with the user before continuing!

### 2. Exploit Flow, Kill Chain and Scope

Together with the user you've built a solid understanding of a bug, now you have to establish how the flaw can be demonstrated.

*goal condition*

The purpose of a PoC is to demonstrate and test the validity of a bug, but also to demonstrate it's impact. Study the potential impact 
of the issue and determine what the minimum viable proof of impact is. Formulate a goal condition that's a clear demonstration of the impact:
* open calc.exe ( to demonstrate an RCE )
* have a security critical function return an incorrect value ( e.g. have a jwt verification function pass for an invalid input )
* reach a smart contract state where the attacker has more funds than they started 
* have an alert box open on a web page (xss)

*flow*

Determine whether the exploit has multiple steps or whether it requires just a single one.

**mono** some proof of concepts comprise a single step. A reflected XSS for example might be demonstrated with a single curl statement.
**poly** some proof of concepts comprise multiple steps, especially those formulated as unit tests.

Study the vulnerability and determine which (mono or poly) is necessary to reach the PoC goal condition.

If multiple steps are required, sketch out the exploit flow step by step. 

Check in with the user, have them review the flow you designed and leverage their input to adapt.

### 3. Determine PoC Approach

Select the minimal demonstration that proves the vulnerability exists and conveys its impact.
Follow the principle of **minimum viable proof** — demonstrate the issue without going beyond
what is necessary.

Primary PoC approaches:
* Test Case (preferred)
* Python Script

**Test Case Proof of Concepts**

Analyze whether it is possible to write the proof of concept as a test case to extend an existing test suite.
Determine the best place to put the proof of concept code if that's the case. Then ask the user if they would
like to extend the test suite and if this location is correct.

When the target is a smart contract, ask the user whether to use a **fork test** (live on-chain
state) or a **unit test** (self-contained, synthetic state) before proceeding. Consult
**`references/smart-contracts.md`** for detailed templates, conventions, and vulnerability patterns.

**Alternative Approaches**

The preferred method (after test cases) is a single python script that leverages click and loguru.

**Notes**

When multiple approaches work, prefer the one that is **simplest to reproduce** for the
maintainer receiving the report.

### 4. Write the PoC

Structure every PoC with these elements:

**Header block (comment at top of file) or comment for the test case:**
```
Title:        [Short descriptive title]
Affected:     [Component, version, file/endpoint]
Impact:       [One-line impact statement]
Author:       [Researcher name/handle]
```

Use the comment standard that best applies for the language/ framework that the PoC is written in.

This means natspec for solidity, javadoc for java, etc.

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
- **Testcase Success.** When implementing proof of concepts as a testcase testcase success
  should indicate that the proof of concept workred.
- **Monetary Impact.** If the flaw allows extraction of funds such as for smart contract
  vulnerabilities then clearly demonstrate profitability of an attack. Measure attacker 
  balance before and after the proof of concept and determine profit. Print this profit so 
  the user can verify.

Important: Never run the PoC against a production environment without asking the user!

### 5. Review Before Delivery

Before finalizing, verify:

- [ ] No destructive payloads or actions
- [ ] PoC actually demonstrates the vulnerability (not just a theoretical description)
- [ ] Comments explain the exploit chain clearly
- [ ] Output clearly indicates success or failure
- [ ] Reproduction steps are complete and ordered

## Additional Resources

### Reference Files

For detailed patterns and format guidance, consult:

- **`references/poc-formats.md`** — Detailed output format templates and examples for each
  vulnerability class
- **`references/vulnerability-patterns.md`** — Common vulnerability patterns, root causes,
  and demonstration approaches organized by class
- **`references/smart-contracts.md`** — Smart contract PoC approach selection, Foundry
  templates, cheatcode conventions, and vulnerability patterns
