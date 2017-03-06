# Grammars

This folder stores grammars for parsers.  Currently, these
grammars are for [ANTLR4](https://github.com/antlr/antlr4),
a parser-generator tool.

You shouldn't need to generate any of the lexers and
parsers.  It should be enough to use the lexers and parsers
that I've already generated, from your Coffeescript.  This
will look kind of like this:

```javascript
{ LanguageLexer } = require './grammar/Language/LanguageLexer'
{ LanguageLexer } = require './grammar/Language/LanguageParser'
{ LanguageListener } = require './grammar/Language/LanguageListener'
```

Of course, you'll have to substitute `language` with the
name of the language you want to parse.

That said, if you want to generate the lexers and parsers
anew, it will take a couple of steps.  First, [set up
ANTLR](https://github.com/antlr/antlr4/blob/master/doc/getting-started.md)
on your machine.  Then, run this command, run this command
(substituting in `language` for the language you want):

```bash
antlr4 -Dlanguage=JavaScript <Language>.g4 -o <Language> -visitor
```
