<p align="center">
  <img src="grimoire_logo.png" alt="Grimoire" width="300" />
</p>

<h1 align="center">Grimoire</h1>

<p align="center">
  <strong>A security research toolkit that learns.</strong><br/>
    Grimoire takes the raw agent experience and tunes it for security research. Clean, readable and reproducible PoCs,
    automatic static analysis module distillation, and more.
</p>

<p align="center">
  <a href="#installation"><img src="https://img.shields.io/badge/Codex-Plugin-8B5CF6?style=flat-square" alt="Codex Plugin" /></a>
  <img src="https://img.shields.io/badge/version-0.1.0-blue?style=flat-square" alt="Version 0.1.0" />
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License MIT" />
</p>

---

## Why Grimoire?

There are many audit agents and vulnerability discovery skills.

These are great, but the real power of agents is in amplifying operator skill. Grimoire embraces that philosophy and implements
several skills that make your agent a better co-auditor.

Some skills (such as the cartography) skill come with a small workflow adaption. However, most features such as the *librarian*
are designed to just *work* within whatever workflow you follow.

> The *librarian* is an agent that looks for documentation and references (e.g. previous audit findings, docs, blog posts, etc.) . It is very focussed on providing only information backed up by reference and keeps the main context clear from large mcp descriptions.
>
> The *cartography* skill provides instructions to Codex on how it can document a mapping from features / flows to code locations. This allows you to say `hey load context on the authentication flow`, Codex will review the file and very quickly load the relevant context.

### Philosophy

Grimoire is built on a few hard convictions from real-world security research:

- **Leverage over automation.** Grimoire provides skills that amplify operator skill, though some automation is present to give you more room for research.
- **Ergonomics.** Agents are already quite useful, and Grimoire adds skills like cartography that fit security-review workflows better.
- **Not getting in your way.** Grimoire takes the base agent experience and makes it more useful for auditing without getting in your way.

### Alpha

Grimoire is still at a very early stage and under continuous development, so expect major changes.

## Getting Started

Yes, you can use Grimoire as part of a normal Codex security workflow. The shortest loop is:
`summon` for context, `cartography` for flow mapping, `librarian` for outside research,
`finding-draft` and `finding-review` for capture, `write-poc` for reproduction, and `scribe`
for reusable checks.

### Installation

This fork is Codex-native: the manifest lives at `.codex-plugin/plugin.json`, optional MCP
servers live in `.mcp.json`, slash-command workflows live in `commands/`, and skills live
under `skills/`.

Clone this fork into your local plugin directory, or symlink this checkout there:

```bash
git clone https://github.com/this-vishalsingh/grimoire.git ~/plugins/grimoire
```

Codex discovers plugins through a marketplace file. For a user-local install, make sure this
repository is available at `~/plugins/grimoire`, then add this entry to
`~/.agents/plugins/marketplace.json`:

```json
{
  "name": "local",
  "interface": {
    "displayName": "Local Plugins"
  },
  "plugins": [
    {
      "name": "grimoire",
      "source": {
        "source": "local",
        "path": "./plugins/grimoire"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Coding"
    }
  ]
}
```

Skills and hooks are wired through the Codex plugin manifest. Commands and role prompts are
included in the conventional `commands/` and `agents/` directories, with thin skill wrappers for
the named Grimoire roles. Some features require API keys:

| Service | Key | Purpose |
|---------|-----|---------|
| [Solodit](https://solodit.xyz) | `SOLODIT_API_KEY` | Audit findings search via claudit |
| [Context7](https://context7.com/dashboard) | `CONTEXT7_API_KEY` | Library documentation lookups |

Set these in your Codex environment or settings:

```json
{
  "env": {
    "SOLODIT_API_KEY": "your-key-here",
    "CONTEXT7_API_KEY": "your-key-here"
  }
}
```

Both are optional - the librarian will fall back to web search if they are not set. You can also export them as regular shell environment variables (for example in `~/.zshrc`) instead of using `settings.json`.

### Workflow

Use Grimoire like this in practice:

1. Start with `summon`.
2. Use `cartography` to map code paths and `librarian` to research outside sources.
3. Turn confirmed issues into artifacts with `finding-draft` and `finding-review`.
4. Reproduce with `write-poc`.
5. Distill repeatable defenses with `scribe`.
6. When improving Grimoire itself, use `gap-analysis`, `execute-plan`, and `assess-process-improvements`.

Example session:

```text
You:      "Summon grimoire on this codebase"
Grimoire: → Analyzes project structure, architecture, integrations
          → Identifies crown jewels and attack surface
          → Writes GRIMOIRE.md contextual map
          → Surfaces first targets for research

You:      "Map the authentication flow"
You:      "Look up prior audit findings for ERC-4626 inflation attacks"
You:      "Document this as a finding"
You:      "Review my findings before submission"
You:      "Write a PoC for the reentrancy I found"
You:      "Distill this finding into a check"
```

If you just want the quick routing map, these are the common phrases:

```text
"Map the authentication flow"              → cartography
"Write a PoC for the reentrancy I found"   → write-poc
"Document this as a finding"               → finding-draft
"Review my findings before submission"     → finding-review
"Check for duplicates"                     → finding-dedup
```

Learn more about grimoire by reading [docs](grimoire/concepts/what%20is%20grimoire.md)

## Project Structure

```
grimoire/                     # Human-written specs (read-only, source of truth)
├── agents/                   # Agent specifications
├── skills/                   # Skill specifications
├── concepts/                 # Design philosophy
├── flows/                    # Multi-step workflow specs
└── ideas/                    # Roadmap and research notes
skills/                       # Implemented skills (where development happens)
agents/                       # Implemented agents
commands/                     # Codex slash-command workflows
.codex-plugin/plugin.json     # Codex plugin manifest
.mcp.json                     # Optional MCP server definitions
```

Specs and implementation are strictly separated. The `grimoire/` directory is the source of truth — never modified during development. Skills in `skills/` implement those specs.

The `grimoire/` directory is also written as a form of documentation, feel free to browse around if you want to learn more.
