This skill helps your agent find and interact with your `@audit` annotations.

One of my favourite vscode plugins is [tintinweb](https://x.com/nicht_tintin)'s solidity visual developer. It does a lot of things, including introducing the `@audit` comment tag / label. During an audit / security review, you can add comments throughout the codebase with tags such as `@audit-finding` or `@audit-ok` or `@audit`. These comments are automatically indexed and browsable through an easy menu item.

The workflow of reading code, and quickly annotating various parts of the codebase can be incredibly useful. I often find myself adding annotations for:
1. potential and confirmed findings
2. `@audit-ok` notes for code where I've checked and made sure a particular problem does not affect the code
3. notes about [[gadget]]s and tricks that might help in building a kill-chain
4. `@audit-todo` notes about things to check 
5. notes with questions I need to ask the client

I and many others have made these notes an integral part of their workflow. Now grimoire has some useful utilities to work with these annotations.

## How to Use
There are many ways in which you might leverage this skill:

* `hey can you find and compile all open questions that I should ask to the client?`
* `hey can you check that all @audit-findings have also been written into a full finding in grimoire/findings/`
* `can you spawn an opus subagent for each open todo and question and have them try to answer the given query to give me an overview`

## Annotation Types

* `@audit-ok` - to annotate things that the auditor checked and turned out to not be an issue
* `@audit` - the general audit annotation, could be a general comment, question, finding or contemplation
* `@audit-info`, `@audit-low`, `@audit-med`, `@audit-high` and `@audit-crit` - indicate findings of different severity levels
* `@audit-(.*)` - people can come up with their own custom audit tags

## Specification
* The skill.md file should stay super clean and not dive too deep into how the skill can be used. The skill file is there to instruct an agent in how they can retrieve annotations from the codebase.  How the annotations are used is out of scope for the skill itself.
* This skill leverages a python script that uses `python-fire` to expose it's functionality as a CLI
* The skill has two levels of language support.
	* The skill works for all languages through grep based annotation discovery.
	* The skill leverages language specific support (only rust and solidity for now) through tree sitter parsing
	* The python code will fall back on grep based discovery when tree sitter dependencies are not available.
* The script will find all audit annotations and provide them in json. 
* The script can provide some extra information such as the name of the function / trait / contract / etc. that the comment was found in. 

