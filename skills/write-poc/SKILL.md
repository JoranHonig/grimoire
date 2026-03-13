---
name: write-poc
user_invocable: true
description: >-
  This skill should be used when the user asks to "write a proof of concept",
  "create a PoC", "demonstrate a vulnerability", "write an exploit PoC",
  "show this bug is exploitable", "prove this vulnerability exists",
  "PoC for CVE", "demonstrate the impact", "exploit this bug",
  "build an exploit", "write a Foundry test for this bug",
  "create a forge test PoC", or needs to create a working demonstration
  of a security vulnerability for responsible disclosure and remediation
  purposes.
---

# Write Proof of Concept

## Purpose

Assist security researchers in writing clear, effective proof-of-concept code that
demonstrates discovered vulnerabilities. PoCs serve as evidence for project maintainers
to understand, reproduce, and fix security issues. Every PoC produced under this skill
assumes an authorized security research context — pentesting engagements, bug bounty
programs, coordinated disclosure, or CTF challenges.

## Philosophy

This skill exists because unstructured "write me a PoC" prompts succeed roughly 60% of
the time. The opinionated structure here — fixed phases, explicit vulnerability-class
references, approach confirmation gates — raises that to approximately 90% one-shot
success by front-loading the decisions that cause agent confusion.

**A PoC is proof, not a suggestion.** It transforms a hypothesis ("I think this is
exploitable") into a fact ("here is the exploit running"). Theoretical descriptions are
insufficient. If it cannot be run and observed to succeed, it is not done.

**Minimum viable proof.** Demonstrate the issue exists and its impact. Do not build a full
exploit toolkit, do not chain unrelated bugs, do not add features beyond what proves the
point.

**Benign payloads only.** `alert(1)`, `sleep()`, `id`, `whoami`. Never destructive. This
is non-negotiable.

**Parameterized targets.** `localhost`, `$TARGET`, environment variables. Never hardcoded
production URLs. The maintainer must be able to point the PoC at their own test
environment.

**Impact communication.** Especially for smart contracts: demonstrate monetary impact.
Measure balances before and after. Print profit. Reviewers and triagers respond to
concrete numbers, not abstract descriptions.

> You are responsible for your PoCs. Agents make mistakes. Always review the generated
> code, verify it demonstrates what you think it demonstrates, and never run it against
> production without explicit authorization.

## Workflow Checklist

When this skill is activated, create a todo list from the following steps. Mark each task
in_progress before starting it and completed when done. Use descriptions from the detailed
sections below.

```
- [ ] 1. Gather vulnerability details — study the issue and impacted code, establish vuln class, root cause, attack surface, prerequisites, and impact. Consider dispatching a librarian for external references. Confirm with user.
- [ ] 2. Define exploit flow — formulate goal condition, determine mono/poly flow, sketch steps if multi-step. Confirm with user.
- [ ] 3. Determine PoC approach — choose test case vs script, for smart contracts decide fork/unit test and whether to use forge-poc-templates. Confirm with user.
- [ ] 4. Write the PoC — dispatch a gnome with the full briefing from phases 1-3 to implement the PoC. Review gnome output and confirm with user.
- [ ] 5. Review before delivery — dispatch a familiar to independently verify the PoC against the review checklist. Present familiar's assessment to user for final approval.
```

---

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

**Librarian.** If the vulnerability involves external protocols, specifications, or known
vulnerability patterns, consider dispatching a librarian agent to retrieve relevant
documentation, prior findings, or security advisories. This is especially useful for
protocol-level bugs (e.g., ERC specs, DeFi invariants) where the codebase alone doesn't
tell the full story.

Check in with the user before continuing!

### 2. Exploit Flow, Kill Chain and Scope

With the vulnerability details established, determine how the flaw can be demonstrated.

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

**Identify the vulnerability class from step 1 and consult the matching reference file:**

| Vulnerability Class | Reference File |
|---|---|
| SQL injection, XSS, SSRF, auth bypass, IDOR | `references/web-application-vulns.md` |
| Buffer overflow, use-after-free, format string | `references/memory-corruption.md` |
| Weak randomness, ECB, padding oracle, hardcoded secrets | `references/crypto-vulns.md` |
| TOCTOU, concurrent request races | `references/race-conditions.md` |
| Business logic flaws | `references/logic-flaws.md` |
| Misconfiguration, exposed services | `references/config-issues.md` |
| Smart contract vulnerabilities | `references/smart-contracts.md` |
| Smart contract (flash loan, reentrancy, price manipulation) | `references/forge-poc-templates.md` |
| Other / unlisted | `references/general-principles.md` |

Read the matching reference file before choosing an approach — it contains templates and
conventions specific to the vulnerability class. For general format principles that apply
to all classes, also consult `references/general-principles.md` and `references/poc-formats.md`.

Primary PoC approaches:
* Test Case (preferred)
* Python Script

**Test Case Proof of Concepts**

Analyze whether it is possible to write the proof of concept as a test case to extend an existing test suite.
Determine the best place to put the proof of concept code if that's the case. Then ask the user if they would
like to extend the test suite and if this location is correct.

When the target is a smart contract, ask the user whether to use a **fork test** (live on-chain
state) or a **unit test** (self-contained, synthetic state) before proceeding. Also determine
whether **forge-poc-templates** (Immunefi's PoC library) would be useful — it provides base
contracts for flash loans, reentrancy, price manipulation, and balance tracking. Always ask
the user whether to use it, and give a recommendation based on the exploit pattern. Consult
**`references/smart-contracts.md`** for approach selection, templates, and conventions, and
**`references/forge-poc-templates.md`** for the forge-poc-templates API reference.

**Alternative Approaches**

The preferred method (after test cases) is a single python script that leverages click and loguru.

**Notes**

When multiple approaches work, prefer the one that is **simplest to reproduce** for the
maintainer receiving the report.

**Confirm**

Always confirm the PoC approach with the user.

### 4. Write the PoC

**Delegate to a gnome agent.** By this point all decisions have been made — the vulnerability
is understood, the exploit flow is designed, and the approach is confirmed. Dispatch a gnome
(subagent) to implement the PoC in an isolated context. This keeps the orchestration context
clean from implementation details and preserves context for the review phase.

**Gnome briefing.** Provide the gnome with:
- The vulnerability details from phase 1 (class, root cause, affected component, impact)
- The exploit flow from phase 2 (goal condition, mono/poly, step sketch)
- The chosen approach from phase 3 (test case vs script, fork vs unit, forge-poc-templates)
- The matching reference file(s) for the vulnerability class
- The specific source files it needs to read
- An example PoC from the `examples/` directory that best matches the chosen approach

**Gnome instructions.** The gnome must follow all implementation guidelines below and report
back with: the implemented PoC, a summary of decisions made during implementation, and any
blockers or assumptions it had to make.

**Implementation guidelines (included in gnome briefing):**

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

**Implementation rules:**
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
- **Test case success.** When implementing a PoC as a test case, test passage should
  indicate exploit success.
- **Monetary Impact.** If the flaw allows extraction of funds such as for smart contract
  vulnerabilities then clearly demonstrate profitability of an attack. Measure attacker
  balance before and after the proof of concept and determine profit. Print this profit so
  the user can verify.
- **Use section header comments.** Organize PoC code into logical blocks using the format
  `// == [ Section Name ] ==` to let readers quickly skim and distinguish preamble/setup from
  the core exploit logic.
  - Common sections include Set Up, Build Payload, Execute Exploit, and Verify Impact, but
    the exact sections depend on the vulnerability.
  - Keep the number of sections minimal — less is more. Only introduce a section break where
    the code shifts to a meaningfully different phase of the exploit.

Important: Never run the PoC against a production environment without asking the user!

**Confirm**

Once the gnome returns, review its output for obvious issues and present the completed PoC
to the user. Walk them through the implementation and confirm it matches the agreed approach,
covers the full exploit flow, and produces clear output.

### 5. Review Before Delivery

**Delegate to a familiar agent.** Dispatch a familiar (subagent using a high-reasoning model)
to independently review the PoC produced in phase 4. The familiar acts as a skeptical
reviewer — it verifies rather than assumes.

**Familiar briefing.** Provide the familiar with:
- The vulnerability details from phase 1
- The exploit flow from phase 2
- The completed PoC code from phase 4

**Familiar review checklist.** The familiar must verify each item and report its assessment:

- [ ] No destructive payloads or actions
- [ ] PoC actually demonstrates the vulnerability (not just a theoretical description)
- [ ] The exploit logic correctly implements the attack flow from phase 2
- [ ] Comments explain the exploit chain clearly
- [ ] Output clearly indicates success or failure
- [ ] Reproduction steps are complete and ordered
- [ ] An accuracy and completeness estimate for the PoC

Present the familiar's review alongside the PoC to the user for final approval before delivery.

## Additional Resources

All reference files are listed in the vulnerability-class-to-reference table in step 3.
Consult the matching reference before choosing an approach.

For worked examples demonstrating each PoC approach (curl, Python script, Foundry unit
test, Foundry fork test with forge-poc-templates), see the `examples/` directory.
