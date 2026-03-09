The [[agents/scribe|scribe]] agent's task is to learn from your findings and conversations.

It builds detection modules and documentation for autonomous detection of vulnerabilities. To do this grimoire has a couple of scribe related skills. These skills teach your agent how to leverage automation (static-analysis and agentic review) to automatically detect classes of vulnerabilities.

## Skills
### Distill

The scribe is responsible for reviewing a finding and determining whether it is feasible and desirable to build an automated analysis for a given vector. 

The scribe then uses a [[gnome]] for the actual implementation of the module (which we call a [[sigil]] in grimoire). There are skills for the different kinds of sigils which provide instructions on how to build and run idiomatic static analysis modules and agentic review [[checks]].

New sigils are always built within the context of the current project and placed in the `grimoire/sigil` directory that's created when grimoire is [[summon]]ed.

At the end of an audit the [[scribe]] agent will extend your [[personal grimoire]] with the sigils built during the audit. Note that some sigils might be very specific to the current project. Your [[scribe]] studies every detector before merging it with your personal grimoire to ensure only generalisable  sigils are stored. 

You can also ask your scribe to merge your sigils before you've wrapped up your audit.
### Garbage Collection

Your [[personal grimoire]] will get a bit cluttered over time and get duplicates so we provide a `scribe-gc` skill.

The scribe implements two features to prevent this:
1. An analysis of the start-of-audit findings raised by [[summon]] will potentially surface duplicate findings. This is a good indication that there are duplicate sigils.
2. You can also manually initiate a garbage collection analysis. Your scribe will perform a systematic review of your sigils (only in your personal grimoire).
### Utilities

A `scribe-utilities` skill provides simple utilities to get information about the sigils both in the personal grimoire and in the current project.
