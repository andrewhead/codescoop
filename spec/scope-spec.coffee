{ InputStream, CommonTokenStream } = require 'antlr4'
{ JavaLexer } = require '../lib/grammars/Java/JavaLexer'
{ JavaParser } = require '../lib/grammars/Java/JavaParser'
{ ScopeFinder, ScopeType } = require '../lib/scope'


describe "ScopeFinder", ->

  describe "after running on a parse tree", ->

    # This code example has class blocks, method blocks,
    # blocks attached to iterators, and other blocks that
    # aren't attached to any particular structure.
    FIRST_EXAMPLE = [
      "public class Example {"
      "  public static void main(String[] args) {"
      "    int i = 0;"
      "    for (int j = 0; j < 2; j++) {"
      "      System.out.println(j);"
      "    }"
      "    {"
      "        int k = 2;"
      "    }"
      "  }"
      "}"
    ].join "\n"

    _countMatchingScopes = (matchFunc, code = FIRST_EXAMPLE) =>

      # REUSE: This boilerplate for constructing a parse tree using ANTLR
      # is based on the snippet from the ANTLR4 project:
      # https://github.com/antlr/antlr4/blob/master/doc/javascript-target.md
      inputStream = new InputStream code
      lexer = new JavaLexer inputStream
      tokens = new CommonTokenStream lexer
      parser = new JavaParser tokens
      parser.buildParseTrees = true
      tree = parser.compilationUnit()

      # Initialize the scope finder.  This is the object under test.
      scopeFinder = new ScopeFinder tree
      scopes = scopeFinder.findScopes()

      # Count up the number of scopes that match a given pattern
      matchCount = 0
      (matchCount += 1 if matchFunc scope) for scope in scopes
      matchCount

    it "finds class blocks", ->
      count = _countMatchingScopes (scope) =>
        scope.getType() is ScopeType.CLASS
      (expect count).toBe 1

    _isScopeForMethod = (scope) =>
      scope.getType() is ScopeType.BLOCK and
        scope.getCtx().parentCtx.ruleIndex is JavaParser.RULE_methodBody

    it "finds method blocks", ->
      count = _countMatchingScopes _isScopeForMethod
      (expect count).toBe 1

    _isScopeForConstructor = (scope) =>
      scope.getType() is ScopeType.BLOCK and
        scope.getCtx().parentCtx.ruleIndex is JavaParser.RULE_constructorBody

    it "finds constructor blocks", ->
      codeWithConstructor = [
        "public class Example {"
        "  public Example() {}"
        "}"
      ].join "\n"
      count = _countMatchingScopes _isScopeForConstructor, codeWithConstructor
      (expect count).toBe 1

    _isScopeForForLoop = (scope) =>
      ctx = scope.getCtx()
      # As blocks for for-loops will be treated just like blocks that
      # are not part of control structure, we traverse the tree around
      # this scope to make sure it's attached to a nearby "for"
      match = false
      if scope.getType() is ScopeType.BLOCK
        try
          forText = scope.getCtx().parentCtx.parentCtx.children[0].symbol.text
        if forText? and forText is "for"
          match = true
      match

    it "finds loop blocks", ->
      count = _countMatchingScopes _isScopeForForLoop
      (expect count).toBe 1

    it "finds other blocks not attached to a particular structure", ->
      count = _countMatchingScopes (scope) =>
        # Because we know the only types of statement blocks in the code
        # snippet will be blocks for the loop and method,
        # we should be able to locate this block by just ignoring the others
        (scope.getType() is ScopeType.BLOCK) and
          not (_isScopeForForLoop scope) and
          not (_isScopeForMethod scope)
      (expect count).toBe 1
