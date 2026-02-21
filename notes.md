# Grimoire Notes 

## Roadmap 

skills:
* triage 
* proof of concept   
* identify
    * maybe this skill needs to be split up (e.g. there could be a skill for building architectural context)
* context 
* scoping 
* flow
* back-pressure and automation
  * semgrep
  * codeql 
  * slither
* finding
* report 

agents:
* sigil     (general sub-agent)
* sage      (back-pressure agent that double checks and gives a second opinion)
* librarian (fetches external documentation where relevant)
* imp       (reviews findings from external audits that might provide relevant information)

## Findings and Other Artifacts

There should be a directory where various artifacts can be put. Things like findings, static analysis modules and 
proof of concepts.

This should be in a git repository separate from the code under test. We should probably have claude point out on the initial
scope building that this is the case and that  if we're running within the git context of the system under test that the user 
might want to change directories / directory structure. 

```
findings/
detect/
poc/
tmp/ <-- for temp scripts / pocs that are being worked on
```


## Context and Delegation 

Context is really important and should be kept clean. 

As much as possible sub-agents should be used for different tasks and subtasks. 

For example a flow should be explored by a sub-agent with only the necessary context.


## Backpressure 

Only allow autonomy with back-pressure methods available. 

Example: Find me all locations where X happens
Back pressure: A semgrep module that actually finds all locations where X happens

You should never, ever, ask a completeness question to an agent that can not be backed up with a back-pressure skill. 

Example: Are all versions of this datastructure parsed correctly

This query lacks back pressure. The agent can not produce an artifact that ensures it actually checks all locations 
where a datastructure is parsed, or that it is parsed correctly. 

Improvement: Find all usages of this datastructure and check whether the version number in the parse function matches 
that of the usage function. 

This is better because the agent can distill this into a static analysis module. 

I've mentioned semgrep and static analysis twice. They're key unlockers in improving the reliability of agent co-auditors.

### Grimoire 

There should be a semgrep, slither and codeql skill. 

There should also be a back-pressure skill. This skill would mostly be about injecting a hook that ensures the agent applies 
back-pressure whenever possible. 

I think it might also be worthwhile to introduce a back-pressure agent that tries to do a soft "fact check" on queries that 
can not be backpressured. As it's simply not always practical to try to achieve back-pressure through static analysis.

Proof of concepts for findings are a great example of a task that naturally induces back-pressure.

---


## Progressive Disclosure and Context Building 

A lot of my security research time is spent tracking down flows. I start with a point of interest,
such as an intricate / complex mechansim performing sensitive operations. I review the mechanism and based 
on my understanding come up with things that could go wrong. I then investigate the different flows that 
interact with the given mechanism and see if the pre-conditions to my attack scenario can be met. 

There are two areas where an agent might aid me in this process. 

The one with the highest leverage is in identifying the flows that interact with the interesting mechanism.

LSPs are slow (esp. find references) and codebases can be constructed with tons of layers of abstraction. As 
a result a lot of time can get lost in navigating around, cross referencing, going back and forth, etc. 

The process of looking at control- and dataflow is actually quite straightforward and something that an agent can 
navigate quite well. Furthermore, an agent can handle abstract tasks like "please point out areas which perform auth checks".

### Progressive Disclosure / Knowledge Graph 

Callgraphs, dataflow graphs, etc are essentially just different relations between abstract components. An interactive 
graph can be leveraged by an agent to quickly navigate the codebase and identify the code that I want to have a look at w.r.t. any given flow. 

An lsp server exposes much of these relations and is likely sufficient to cover most usecases. 

### Context Building 

The idea of context building is to extend the existing knowledge graph exposed by an lsp with learnings and conclusions from the audit. 

For example, I might find out that a function does a specific check which covers a unique set of edge cases. I want to make a note with 
that conclusion to be surfaced in future investigations. The idea here is not to have the agent reason about these conclusions, it's just 
to have it surface these conclusions to me. 

The problem with asking the agent with reasoning or even coming up with conclusions is the phenomenon that continued reasoning diverges 
and that the ideas/ conclusions are not amenable to back-pressure.

That said, there might be a set of conclusions that are amenable to back-pressure. This is an interesting observation. For example, an 
agent might notice a certain function produces html code that's potentially vulnerable to xxs injection. This is an hypothesis that's 
easily testible by producing a small test case. 

### Gadgets

A phenomenon I have observed in my bounty hunting is that I collect a set of what I would call gadgets. 

The term is derived from the way that ROP-gadgets are used in binariy exploitation. Essentially, gadgets are tricks I found that 
allow me to have the code do something unexpected. Usually on their own these gadgets are benign, they might rise to the level of low 
severity issues, but often not even that. 

These gadgets are often essential in enabling critical vulnerabilies to be exploitable. 

I currently mostly keep a mental note about these, but it might be interesting to augment my workflow such that an agent indexes 
my gadgets and suggests them when I'm considering whether an issue can be exploited. 

It might even be useful to have the agent itself produce gadgets, or incorporate a gadget search in its proof of concept development workflow.

A nice thing is that gadgets are generally expressable as unit tests.

---

## Grimoire Identify

alternative naming: detect magic

The following is an idea for a skill that's run on a researchers first interaction with a codebase. It is kind of similar to claude's init skill. However, the target audience is a bit different.

This skill will help a security researcher build context when they start on a new project. The same context will also prime future agents that the security researcher might leverage.

Similar to /init this skill will create a file `GRIMOIRE.md`.


### Learnings from Top researchers

The following is a collection of lessons taken away by interviewing top security researchers and analyzing their thought and research process.

Build Context First 

Some researchers start by reading documentation first. This provides a nice introduction and clearly conveys the *problem* a project is solving
and their *approach* to solving it. It is not uncommon for security researchers to already identify many of the attack vectors that turn in to 
critical findings just by reading this documentation. Furthermore, the understanding built in reading the documentation provides important context 
when actually diving into the code. This comes down to the way we learn and memorize things. Novel ideas are generally stored in association to 
existing memories. 

Other researchers start by browsing the code. Documentation can be out of date and only describes what the code is doing on a high level, not 
how it is actually structured and how everything fits together. Documentation is often also spotty, only discussing certain aspects of a system. 
Interestingly, code-first researchers generally don't start with a thorough line-by-line approach. Instead they leverage a more global approach,
skimming through large parts of the codebase to get a sense of how everything fits together. 

There is an interesting parallel to be drawn to the techniques that can be employed in reading, where we can also identify different approaches 
that usually follow each other. A global type of reading where the headers and general context of a piece of writing is identified often preceeds
a more thorough reading of the actual content.

In studying all cases it's possible to identify a commonality: context first. 

Regardless of approach, every researcher starts by building a contextual framework of the project that they are reviewing. 

This contextual framework has multi-faceted benefits and aids understanding, memorization, hypothesis generation and testing.


### Context, what context?

You can start building context by answering simple questions like:

* What language, test/build framework and tooling is used?
* What (if any) systems does the project integrate with?
* What problem is this project trying to solve?
* At a high level, what approach does this project use to solve the problem?

Though seemingly trivial, this is the seed out of which the rest of the context grows. 

Once the initial context is estableshed we can dive deeper, and look at *Architecture and Flows*

* (identify primary flows) what are the activities / use-cases? 
    * what steps (flow) are involved in executing those activities and how do they flow through the system 
* (identify structure and architecture) how is the codebase put together
    * as you're reading code it is easy to see explicit & local relations (a calls b)
        it is more difficult to identify implicit relations. Input validation is a good example.  You'll often read lots of code 
        which requires valid input, but does not check it themselves. Building architectural context helps build a map for navigating
        a codebase when you encounter such non-explicit cases. 

At this point it might be important to point out that though it is possible to point out that the audit process often starts with building context,
it is also true that you never really stop building context throughout the audit process. 

Once there is a good global overview of the primary flows and architecture it's important to contextualize one more thing. 

The crown jewels.

In the end we don't necessarily care about finding bugs, we care about finding bugs that get us the crown jewels. 
For smart contracts this usually means some form of loss of funds. For many other applications, it might mean account take over 
remote code execution, privilege escalation / loss of confidentiality. 

Identify the flows and components that actually interact with the crown jewels. The functions transferring funds, the logic
related to authentication. 

It's important to not go too wild. It's often not very suseful that a c program might be vulnerable to binary exploitation. 

The goal here is to point out the application specific sensitive flows and components. 


### Agent Instructions




* Cross reference findings from documentation back to the code
