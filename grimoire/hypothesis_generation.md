# Hypothesis Generation 

Grimoire is lazer focussed on providing leverage to the security researcher. 

In the end this boils down to hypothesis generation and testing. It's a toolset that centers itself around
having the researcher think and hypotheze, while having the machine run down tasks. 

There is an interesting area of automatic hypothesis generation that is a non-priority but that we might 
also want to look at. 

There are two ways that this could work. 

1. Associative - we surface relevant ideas to the researcher during the course of normal operations related to what 
    they're currently working on. 
2. Autonomous - we have a completely autonomous side process that's exploring the codebase, hypothesizing and validating 
    all on it's own. 

I think (1) is probably the most interesting one, as it is within the context of the researcher and allows rapid collaboration. 

(2) is inherently limited and essentially competes with the standard audit agents and the security agents from anthropic and openai.

Regardless. 

I think for both it could be interesting setting up a ralph loop to build a progressively disclosed knowledge base. Every time a new 
public report comes out we do a differential analysis and improve the knowledge base based on a lack of information. 

We can also run the autonomous agent and see if the changes made actually help identify the bug. We'd allso need some back-pressure 
to prevent regression of the analysis quality (false positives and false negitives).

