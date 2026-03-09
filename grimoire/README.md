This is the documentation / specification for grimoire. A set of skills and agents hyper focused on providing as much leverage as possible to security engineers.

Unlike other security related skillsets Grimoire does not focus on providing a compilation of knowledge. Instead Grimoire is focussed on providing skills and agents that guide researchers and agents in the security research process. 

Grimoire is mostly based on my ( Joran Honig ) experience and what I need from agents. As a result you might find that grimoire is less refined if you research dissimilar targets.

> [!info]
This directory contains only files that have been completely written by a human, they serve as a specification for the Grimoire project and provide agents with back pressure. Most of the files have been written in an instructional / blog post style.

You'll likely benefit from setting up grimoire without really diving into what it can do. Agents like the [[librarian]] will automatically pop up and provide useful information where necessary. That said, it can be helpful to to read through: [[what is grimoire]] which provides a quick introduction.

Some highlights:
* The [[agents/scribe|scribe]] agent automatically turns your findings into static analysis modules and checks that are automatically ran during your next audit.
* The [[cartography]] skill helps build re-usable context building guides. No more, `read file x, y, z and follow the auth flow` every time you're reviewing an aspect related to auth. Just  ask: `load context on auth`.
* The [[proof of concept]] skill turns one-shotting a proof of concept from dream into reality.

## Work in Progress

Grimoire is pre v1.0.

There are too many ideas and there will be lots of fine-tuning ahead. 

## Grimoire Specs

There are four categories of specifications / documents.

* agents - The agents that grimoire provides
* skills - The skills that grimoire provides
* flows - Common security research activities and how grimoire aids in their completion
* concepts - Documents describing concepts that don't map to particular skills, flows or agents

Skills:
* [[summon]]
* [[cartography]]
* [[skills/scribe|scribe]]
* [[proof of concept]]
* [[checks]]

Agents
* [[agents/scribe]]
* [[librarian]]
* [[sigil]]
* [[skills/scribe|scribe]]

Concepts:
* [[hypothesis generation]]
* [[the original sin]]
* [[(trivial) verifiability]]
* [[backpressure]]


## Agent Driven

These specifications are only written by a human, the grimoire implementation itself is largely agent driven and based on the ralph loop approach. 