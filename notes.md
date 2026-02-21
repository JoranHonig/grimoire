

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

Prioritization


### Agent Instructions




* Cross reference findings from documentation back to the code
