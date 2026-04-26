# Sigil Spawning Reference

How summon spawns sigil agents to hunt for known vulnerability patterns.

## Subagent Prompt Template

When spawning a sigil subagent for a check, use this prompt structure:

```
You are a sigil — a single-context vulnerability hunter. Your task is to hunt for one
specific vulnerability pattern in this codebase.

**Context:** Read GRIMOIRE.md at the project root for engagement context (target, architecture,
crown jewels, attack surface).

**Check:** Read the check file at `<CHECK_FILEPATH>`. This defines the vulnerability pattern
you are hunting for — what to search for and how to assess matches.

**Hunt protocol (Mode 1 from agents/sigil.md):**

1. Read GRIMOIRE.md. Note the target's language, architecture, and crown jewels.
2. Check `grimoire/sigil-findings/` for prior findings on this pattern. Skip if already covered.
3. Formulate a testable hypothesis from the check's Patterns and Assessment sections.
4. Search the codebase using Grep, Read, and Glob. Follow the check's search patterns.
5. For each match, assess using the check's Assessment section. Distinguish true positives
   from safe usage.
6. For confirmed findings, write to `grimoire/sigil-findings/<slug>.md` with:
   - Title, severity, confidence
   - Affected file(s) and line(s)
   - Root cause explanation
   - Evidence (code snippets showing the vulnerability)
   - Suggested next steps (write-poc, variant sigil, cartography)
7. Return a hunt summary: check name, verdict (finding/dismissed), confidence, finding path.

**Constraints:**
- Hunt ONE pattern only (the check you were given)
- No file modifications outside `grimoire/sigil-findings/`
- Evidence-only assertions — if you can't find concrete evidence, dismiss
- Benign analysis only — do not attempt exploitation
```

## Parallelism

Spawn sigils in batches of 5. Each sigil is a subagent that loads GRIMOIRE.md (~150 lines) plus
one check file (~30 lines) plus codebase reads. Five concurrent sigils is a pragmatic cap that
balances coverage speed against context budget.

If the user has more than 20 applicable checks, suggest filtering first:
- By severity (run critical/high checks first)
- By tag (focus on the most relevant vulnerability classes)
- By language (if the codebase uses multiple languages, prioritize the primary one)

## Language Matching

The `select-checks.sh` script filters checks by language. Matching rules:

- Check `languages` field is compared case-insensitively against target languages
- Empty or missing `languages` field means the check applies to all languages
- Multi-language checks (e.g., `solidity, vyper`) match if ANY language overlaps
- Common aliases are not resolved (e.g., `javascript` does not match `js`) — checks should
  use the same language names that appear in GRIMOIRE.md

## When No Checks Exist

On a fresh engagement with no spellbook, the sigil swarm step completes instantly. This is
expected. Note in GRIMOIRE.md:

```
## Automation

No spellbook checks available. As findings accumulate during this engagement, use the
checks skill to codify vulnerability patterns. Re-run sigil spawning after building checks.
```

## Familiar Integration

After sigil results are collected, route them through the familiar agent for triage:

1. Sigils spawn as before and write findings to `grimoire/sigil-findings/`
2. Invoke the familiar agent in batch triage mode (Mode 2) on `grimoire/sigil-findings/`
3. The familiar independently verifies each finding — confirming, adjusting severity,
   marking uncertain, or dismissing with evidence
4. Dismissed findings are moved to `grimoire/sigil-findings/dismissed/` for audit trail
5. Only confirmed and uncertain findings are presented to the user

The sigil spawning, batching, and result collection logic stays the same. The familiar
adds a verification pass between collection and presentation.
