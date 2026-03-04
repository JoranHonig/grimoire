In this document I'll introduce you to Grimoire's `summon` skill, which you run on your first interaction with a codebase. It is kind of similar to claude's init skill but geared towards security research.

Similar to `/init` this skill will create a file `GRIMOIRE.md`. This file helps you (a security researcher) to build context when starting with a new project. It also serves to prime the context of agents as you use them on a codebase where Grimoire is summoned.

### Learnings from Top researchers

Over the last years I've spoken with many security researchers, and read many blogs/ tweets. Based on which I've distilled a few insights on the audit process and how to best get started.

The main take-away: **build context first**

Some researchers start by reading documentation, others by reading the code. All researchers first build a solid contextual understanding.

Some researchers start by reading **documentation first**. This provides a nice introduction and clearly conveys the *problem* a project is solving and their *approach* to solving it. It is not uncommon for security researchers to already identify many of the attack vectors that turn in to 
critical findings just by reading this documentation. Furthermore, the understanding built in reading the documentation provides important context 
when actually diving into the code. This comes down to the way we learn and memorize things. Novel ideas are generally stored in association to 
existing memories. 

Other researchers start by browsing the **code first**. Documentation can be out of date and only describes what the code is doing on a high level, not how it is actually structured and how everything fits together. Documentation is often also spotty, only discussing certain aspects of a system.  Interestingly, code-first researchers generally don't start with a thorough line-by-line approach. Instead they leverage a more global approach, skimming through large parts of the codebase to get a sense of how everything fits together. 

There is an interesting parallel to be drawn to the techniques that can be employed in reading, where we can also identify different approaches that usually follow each other. A global type of reading where the headers and general context of a piece of writing is identified often preceeds
a more thorough reading of the actual content.

In other words, most researchers start with a context first approach.

This makes sense when you think about the mechanism behind human memorisation and learning. As memories/ learning initially happens in context to prior information. 

### Context, what context?

So what does context entail, and what's actually in the GRIMOIRE.md file?

It starts with a couple of high level concrete details answering the following questions:
* What language, test/build framework and tooling is used?
* What (if any) systems does the project integrate with?
* What problem is this project trying to solve?
* At a high level, what approach does this project use to solve the problem?

Though seemingly trivial, this is the seed out of which the rest of the context grows. 

Once the initial context is established we can dive deeper, and look at *Architecture and Flows*

* (identify primary flows) what are the activities / use-cases? 
    * what steps (flow) are involved in executing those activities and how do they flow through the system 
* (identify structure and architecture) how is the codebase put together
    * as you're reading code it is easy to see explicit & local relations (a calls b)
        it is more difficult to identify implicit relations. Input validation is a good example.  You'll often read lots of code which requires valid input, but does not check it themselves. Building architectural context helps build a map for navigating
        a codebase when you encounter such non-explicit cases. 

> [!info] 
> It is important that GRIMOIRE.md does not get too large as this pollutes LLM context and causes attention loss. As a result, GRIMOIRE.md contains only a high level description of the flows and architecture.

At this point it might be important to point out that though it is possible to point out that the audit process often starts with building context, it is also true that you never really stop building context throughout the audit process. However, more detailed context belongs in the `grimoire/tomes` directory, which we'll discuss later in this post.

Once there is a good global overview of the primary flows and architecture it's important to contextualize one more thing: *the crown jewels*.

In the end we care about finding bugs that have impact. For smart contracts this usually means some form of loss of funds. For many other applications, it might mean account take over 
remote code execution, privilege escalation / loss of confidentiality. Grimoire will identify what the crown jewels are and document them in `GRIMOIRE.md`. 

`GRIMOIRE.md` provides useful initial context to you, but can also be used by you to provide context to the agents. Grimoire might not initially identify all interesting areas of impact. In editing GRIMOIRE.md you can prime future agent runs to be more aware of the context and potential impact.

In other words, `GRIMOIRE.md` should be treated as living contextual memory. It changes during the security review.

### Directory structure

In addition to building context Grimoire also performs some logistical tasks during the summon command, including setting up the infrastructure for an audit / bug hunt.

Ideally you start grimoire in a directory containing a directory with the code that's in scope. 

```
audits/
    your_next_audit/  <-- here 
        in_scope_repo/
```

This allows grimoire some flexibility to setup files, directories, worktrees without polluting the scoped code.  Grimoire should check it's working directory and confirm that you've set things up correctly. 

Within your project grimoire will create the following directory structure:

```
project/ 
    in_scope_repo/
    meeting_notes/ <- (optional) contains useful context from meetings
    scope/         <- (optional) documentation on the scope from client
    grimoire/
        findings/ <- the findings during this audit 
        spells/   <- scripts proof of concepts and static analysis modules
        tomes/    <- documentation and learnings 
    GRIMOIRE.md   <- main contextual map
```

Similar to obsidian Grimoire employs `[[doc-name]]` style cross-linking between documents. 

### The Right Time for Automation

Note: The scribe is not implemented yet so this is WIP.

Another feature of grimoire is the [[scribe]] and the users personal [[spellbook]].

Over time users will acquire a set of static analysis modules that go beyond what's publicly available. This is their own secret arcane compendium.

The start of an audit ( when one would kick off `/summon` ) is the exact right time to run these static analysis modules and daemons.  
