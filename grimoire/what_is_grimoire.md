
Grimoire is a set of skills, agents, tools and plugins designed with the specific intention of increasing leverage.

It's singular goal is to increase the quality, speed and depth of security research. 

## Not an Audit Agent
As a result, Grimoire is not an audit agent. 

It incorporates some of the same aspects of audit agents, but it has a fundamentally different goal. It's goal is not to provide the best autonomous audit possible. Grimoire is primarily useful for expert security researchers. It removes friction, automates what can be automated and above all provides leverage.

A novice user can easily get started using grimoire by installing it. Grimoire is engineered to steer agents in the right direction for security research related tasks. As a result, you can simply ask the agent research related questions like you would a plain claude, codex, .. setup.

That said there are things to learn about grimoire.

## Leverage
So where does the leverage come from?

Many places! For example, grimoire provides a [[proof of concept]] skill. At first glance, proof of concept writing might seem trivial. However, you'll often see that one-shotting proof of concepts leads to suboptimal results. Grimoire steers agents to produce clean proof of concepts that communicate impact and demonstrate flaws in simple and understandable ways.

Another example is in automation. During audits you often encounter bugs that could've been detected using some automated approach (static analysis or agentic). However, you might not have had the time to actually look into actually building the detector. This is where Grimoire's [[scribe]] agent steps in! It will automatically review your findings and conversations for automation opportunities, and build the detection modules for you! 

Every audit kicks off an automated run of all modules you've had built before, providing a more comprehensive initial scrape with every audit.

These are just two simple and concrete examples, grimoire provides much more!
## Summoning
Before you start using grimoire you'll need to learn about *summoning*.

You're probably familiar with the claude `/init` command, which explores a codebase and builds a CLAUDE.md file with a digest for future agents on how to interact with the codebase. `/summon` is similar in nature. An exploration of the codebase provides grimoire with a good
understanding of how everything fits together. However, where `/init` sets agents up for success in building new features `/summon` sets agents up for doing well on queries from security researchers.

Dive deeper here: [[summon]]

## Friction
Grimoire is set up to provide as little friction as possible.

There are a couple of features that require you to read the documentation. `/summon` being a good example. However, most of grimoire is designed to be minimalistic and frictionless, skills will get triggered when you need them, agents started when useful. 

You can just use it like you would a normal agent and have Grimoire improve your experience by steering the agent to provide better results.

## Progressing 

Grimoire is a living thing, it grows as you do. 

We've compiled a set of *tomes* with instructions to help you interact with Grimoire for the best results.

- [[back-pressure and what not to ask]]
- [[hypothesis generation - fail as fast as possible]]
