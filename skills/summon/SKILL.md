---
name: summon
description: >-
  This skill should be used when the user says "summon", "summon grimoire",
  "/summon", "initialize grimoire", "start an audit", "begin security review",
  "set up audit workspace", "kick off security research", "scope a codebase",
  "map a codebase for security", "prepare for an audit", or wants to initialize
  Grimoire on a new codebase. This is the first skill run on a new engagement.
  It builds initial context, creates the audit workspace structure, and produces
  GRIMOIRE.md — the living contextual map that primes all future agent
  interactions for security research.
user_invocable: true
---

# Summon

Initialize Grimoire on a new codebase. Build context, create the audit workspace, and produce
`GRIMOIRE.md` — the living contextual map for this security engagement.

## Philosophy

**Build context first.** Top researchers always establish contextual understanding before hunting
for bugs. Summon explores the target, builds a map, and gives you and future agents the context
needed to do meaningful work. Keep GRIMOIRE.md concise — it is loaded into every agent context.
Detailed notes belong in `grimoire/tomes/`.

## Workflow

When this skill is activated, create a todo list from the following steps. Mark each task
in_progress before starting it and completed when done.

```
- [ ] 1. Verify workspace layout — confirm directory structure, identify in-scope repo(s)
- [ ] 2. Create audit directory structure — set up grimoire/, findings/, spells/, tomes/
- [ ] 3. Build initial context — language, tooling, frameworks, integrations, problem & approach
- [ ] 4. Map architecture and flows — identify structure, primary flows, key components
- [ ] 5. Identify crown jewels — determine high-impact targets and threat model
- [ ] 6. Write GRIMOIRE.md — assemble the contextual map
- [ ] 7. Review GRIMOIRE.md — kick off subagent to verify accuracy and trim bloat
- [ ] 8. Surface automation opportunities — check for spellbook modules to run
- [ ] 9. Spawn sigil swarm — run checks-based sigils against the codebase
```

---

### 1. Verify Workspace Layout

Check the current working directory. The ideal layout is:

```
project/          <-- cwd
    in_scope_repo/
```

The project directory should contain the repository (or repositories) that are in scope. Grimoire
creates its own files and directories alongside (not inside) the scoped code.

**Verify:**
- Are we in a directory that contains one or more code repositories?
- Are we accidentally inside the repo itself? (If so, warn the user and suggest moving up)
- Is there a git repo at the current level that would conflict? (Grimoire artifacts should not
  pollute the scoped repo's git history)

If multiple repositories are in scope, identify each one. GRIMOIRE.md should cover all in-scope
repos in a single document, with architecture and flows sections clearly delineating per-repo
structure where they differ.

If the layout looks wrong, explain the expected structure to the user and ask them to confirm or
adjust before proceeding. Do not silently continue with a bad layout.

If the user has additional context available (meeting notes, scope documents, prior audit reports),
ask whether they'd like to point Grimoire at those directories.

### 2. Create Audit Directory Structure

Create the following directories if they don't already exist:

```
project/
    in_scope_repo/              # already present
    grimoire/
        findings/               # findings during this audit
        sigil-findings/         # findings sourced from sigil agents
        spells/                 # scripts, PoCs, static analysis modules
        tomes/                  # documentation, detailed notes, learnings
        tmp/                    # temporary files and scripts
    GRIMOIRE.md                 # main contextual map (created in step 6)
```

Documents in `grimoire/tomes/` are cross-linked from GRIMOIRE.md using Obsidian-style wiki links:
`[[tomes/auth-flow]]` links to `grimoire/tomes/auth-flow.md`.

Optionally create if the user indicates they have relevant materials:
```
    meeting_notes/              # context from client meetings
    scope/                      # scope documentation from client
```

Do not overwrite existing directories or files.

### 3. Build Initial Context

Explore the in-scope repository to answer these questions. Use subagents to parallelize exploration
where possible.

**Concrete details:**
- What programming language(s) are used?
- What build system / package manager is used?
- What test framework is used?
- What major frameworks or libraries does the project depend on?
- What external systems does the project integrate with? (databases, APIs, blockchains, message
  queues, cloud services)

**Problem and approach:**
- What problem is this project trying to solve?
- At a high level, what approach does this project use to solve it?
- Who are the users / actors in the system?

Start by reading documentation if available (README, docs/, wiki). Then scan the codebase
structure, dependency manifests, and configuration files. Documentation conveys intent; code
conveys reality. Cross-reference both.

### 4. Map Architecture and Flows

Dive deeper into the codebase to understand structure and behavior. Use subagents to explore
individual modules, components, or flows in parallel. Keep the main context focused on assembling
the map.

**Architecture (structure):**
- How is the codebase organized? (modules, packages, layers)
- What are the key components and how do they relate?
- Where are the system boundaries? (entry points, external interfaces)
- Are there implicit relationships that aren't obvious from call graphs? (e.g., input validated
  in one place, consumed in another; shared state; event-driven coupling)

**Primary flows (behavior):**
- What are the main activities / use cases?
- For each primary flow: what steps are involved, and how does execution flow through the system?
- Where does authentication and authorization happen?
- Where does data enter and leave the system?

Keep this high-level. The goal is a map for navigation, not a line-by-line audit. Detailed flow
analysis belongs in `grimoire/tomes/` and will happen during the actual research.

### 5. Identify Crown Jewels

Determine what matters most from a security perspective. In the end, we care about bugs that have
**impact**. Crown jewels are the assets and capabilities that attackers would target.

**Common crown jewels by domain:**
- **Smart contracts:** funds, governance control, oracle manipulation, protocol invariants
- **Web applications:** user accounts, authentication tokens, PII, payment data, admin access
- **Infrastructure:** RCE, privilege escalation, lateral movement, secrets/credentials
- **APIs:** data exfiltration, rate limiting bypass, authorization bypass

**For each crown jewel, note:**
- What is the asset?
- Where in the code is it handled?
- What are the likely attack vectors?
- What would successful exploitation look like?

Consult `references/domain-crown-jewels.md` for a comprehensive breakdown of assets, attack
vectors, and exploitation patterns by domain.

This is an initial assessment. The user will refine crown jewels as the engagement progresses.
GRIMOIRE.md is living memory.

### 6. Write GRIMOIRE.md

Assemble findings from steps 3-5 into `GRIMOIRE.md` at the project root. This file serves as:
- Initial context for the researcher
- Context primer for all future agent interactions
- A living document that evolves during the engagement

**Template:**

```markdown
# GRIMOIRE — [Project Name]

> Summoned: [date]
> Scope: [brief scope description]

## Target

- **Language:** [languages]
- **Build/Test:** [build system, test framework]
- **Frameworks:** [key frameworks/libraries]
- **Integrations:** [external systems]

## Problem & Approach

[2-3 sentences: what the project does and how]

## Architecture

[High-level component map. Use a simple list or ASCII diagram. Keep it scannable.]

## Primary Flows

[List the main use cases / activities. For each: 1-2 line description of the flow path through
the system. More detail belongs in grimoire/tomes/.]

## Crown Jewels

[For each high-value target: asset, location, likely attack vectors. Bulleted list.]

## Attack Surface Notes

[Initial observations about security-relevant patterns, trust boundaries, areas that warrant
deeper investigation. Keep this brief — it will grow during the engagement.]

## Automation

[List any spellbook modules that were run or are available to run. Note results if applicable.]
```

**Important constraints:**
- Keep GRIMOIRE.md concise. It will be loaded into every agent context.
- Use `[[document-name]]` cross-linking to reference detailed notes in `grimoire/tomes/`.
- Do not include line-by-line code analysis. That belongs in tomes.
- Consult `examples/grimoire-md-example.md` for a concrete reference of what a completed
  GRIMOIRE.md looks like.

### 7. Review GRIMOIRE.md

After writing GRIMOIRE.md, kick off a subagent to review it. The subagent should read both
GRIMOIRE.md and the in-scope codebase independently to verify accuracy and flag bloat. Do not
skip this step — the main agent built context progressively and may have carried forward
assumptions or included too much detail.

**Subagent instructions:**

Give the subagent the following mandate. It should read GRIMOIRE.md and then independently spot-check
claims against the actual codebase:

1. **Accuracy check** — Verify factual claims against the codebase:
   - Are the listed languages, frameworks, and dependencies correct?
   - Do the described flows match what the code actually does?
   - Are referenced file paths and component names real?
   - Are crown jewel locations accurate?
   - Flag anything stated with confidence that the code contradicts.

2. **Bloat check** — GRIMOIRE.md is loaded into every agent context. Every unnecessary line
   degrades future agent performance. Flag:
   - Sections that repeat the same information in different words
   - Overly detailed flow descriptions that belong in `grimoire/tomes/`
   - Vague filler sentences that don't add navigational or security value
   - Content exceeding ~150 lines total (a strong signal of bloat)

3. **Completeness check** — Flag obvious gaps:
   - Major entry points or external interfaces not mentioned
   - Significant components missing from the architecture
   - Crown jewels that seem absent given the project domain

The subagent should return a short list of specific corrections, cuts, and additions. Apply them
to GRIMOIRE.md before presenting the final version to the user. Show the user what the subagent
found and what was changed.

### 8. Surface Automation Opportunities

Check if the user has a spellbook (prior static analysis modules, detection scripts, or
research automation).

Look for:
- Existing `spells/` directory content from previous engagements
- Semgrep, CodeQL, or Slither rules
- Custom detection scripts

If automation modules exist:
- List what's available and briefly describe what each detects
- Ask the user which modules they'd like to run against the new codebase
- Run selected modules and provide an initial triage of results

If no spellbook exists yet:
- Note this in GRIMOIRE.md under Automation
- Note that automation modules can be built from findings as the engagement progresses

If the researcher has a personal grimoire (`~/.grimoire/sigils/`), list what's available and
suggest running the Scribe GC skill (`/scribe-gc` with scope "both") to check for duplicates
between personal and project-local sigils before applying them.

Note in GRIMOIRE.md under Automation that new detection modules can be distilled from findings
as the engagement progresses using the Scribe agent (`/scribe-distill`).

### 9. Spawn Sigil Swarm

After automation discovery, spawn sigil agents to hunt for known vulnerability patterns across
the codebase. Each sigil is a single-context agent that hunts one bug pattern using a check
from the spellbook.

Consult `references/sigil-spawning.md` for the subagent prompt template and detailed guidance.

**Index available checks.**

Run the `index-checks.sh` script from the checks skill's `scripts/` directory, passing
`grimoire/spells/checks/` as the target. If the directory does not exist or contains no
checks, note "No checks available — sigil swarm skipped" in GRIMOIRE.md under Automation
and skip this step. A fresh engagement with no prior checks is normal.

**Filter by language.**

Match each check's `languages` field against the languages identified in step 3 (the Target
section of GRIMOIRE.md). Only include checks whose language matches the target codebase.
Include checks with an empty or wildcard languages field regardless of target.

Run the `select-checks.sh` script from this skill's `scripts/` directory, passing
`grimoire/spells/checks/` and a comma-separated list of target languages from GRIMOIRE.md.
The script outputs only the checks that apply.

**Confirm with the user.**

Present the user with:
- How many applicable checks were found
- A brief list of check names and what they detect
- The estimated number of sigils to spawn

Ask whether to: **spawn all**, **select a subset**, or **skip**. Sigil spawning is the most
expensive operation in the workflow — the user must explicitly approve it.

If there are more than 20 applicable checks, warn about the time cost and suggest filtering
by tag or selecting a subset.

**Spawn sigils.**

For each approved check, spawn a subagent sigil. Process in batches of 5 to manage context
budget. For each check, give the subagent these instructions:

1. Read GRIMOIRE.md for engagement context
2. Read the check file at `<filepath>` for the vulnerability pattern
3. Hunt following the protocol in `references/sigil-spawning.md` — formulate a hypothesis from
   the check, search the codebase, evaluate evidence, produce a finding or dismiss
4. Write any findings to `grimoire/sigil-findings/<check-slug>.md` where `<check-slug>` is the
   check's filename without extension. If a check produces multiple findings, append a numeric
   suffix (e.g., `reentrancy-1.md`, `reentrancy-2.md`)
5. Return a hunt summary: check name, verdict (finding or dismissed), confidence, and file path
   if a finding was written

Wait for each batch of 5 to complete before spawning the next batch.

**Collect and present results.**

After all sigils complete, aggregate results. Present a summary:

```
## Sigil Swarm Results

Checks run: [N]  |  Findings: [N]  |  Dismissed: [N]

| Check | Verdict | Severity | Confidence | Finding |
|-------|---------|----------|------------|---------|
```

Group findings by severity (Critical/High first).

**Familiar Triage.** Invoke the familiar agent in batch triage mode (Mode 2) on
`grimoire/sigil-findings/`. The familiar will independently verify each finding, dismiss
false positives (moving them to `grimoire/sigil-findings/dismissed/`), and adjust severity
where warranted. Present the familiar's triage summary to the user instead of raw sigil
results.

**Update GRIMOIRE.md.**

Append to the Automation section:
- Number of checks run and findings produced
- Link to `grimoire/sigil-findings/` for details
- Note which checks were skipped (if any) and why

---

## Guidelines

- **Subagents for exploration.** Use subagents to parallelize codebase exploration. This keeps
  the main context clean and speeds up the process.
- **Cross-reference documentation and code.** Documentation describes intent; code describes
  reality. Discrepancies between the two are themselves interesting from a security perspective.
- **Ask, don't assume.** If something is ambiguous (scope, layout, priorities), ask the user.
- **Living document.** Remind the user that GRIMOIRE.md should be edited as they learn more.
  It's a starting point, not a final artifact.
- **Conciseness over completeness.** GRIMOIRE.md is a map, not an encyclopedia. Err on the side
  of too brief. Detailed notes go in `grimoire/tomes/`.
