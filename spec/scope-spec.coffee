{ InputStream, CommonTokenStream } = require 'antlr4'
{ JavaLexer } = require '../lib/grammars/Java/JavaLexer'
{ JavaParser } = require '../lib/grammars/Java/JavaParser'
{ ScopeFinder, Scope, ScopeType } = require '../lib/scope'
{ parse, partialParse } = require '../lib/parse-tree'
{ Symbol, File } = require '../lib/symbol-set'
{ Range } = require 'atom'


describe "ScopeFinder", ->

  _isScopeForMethod = (scope) =>
    scope.getType() is ScopeType.METHOD and
      scope.getCtx().parentCtx.ruleIndex is JavaParser.RULE_methodBody

  _isScopeForConstructor = (scope) =>
    scope.getType() is ScopeType.METHOD and
      scope.getCtx().parentCtx.ruleIndex is JavaParser.RULE_constructorBody

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

  _isScopeForStatementBlock = (scope) =>
    # Because we know the only types of statement blocks in the code
    # snippet will be blocks for the loop and method,
    # we should be able to locate this block by just ignoring the others
    (scope.getType() is ScopeType.BLOCK) and
      not (_isScopeForForLoop scope) and
      not (_isScopeForMethod scope)

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

      tree = parse code
      scopeFinder = new ScopeFinder (new File ".", "E.java"), tree
      scopes = scopeFinder.findAllScopes()

      # Count up the number of scopes that match a given pattern
      matchCount = 0
      (matchCount += 1 if matchFunc scope) for scope in scopes
      matchCount

    it "finds class blocks", ->
      count = _countMatchingScopes (scope) =>
        scope.getType() is ScopeType.CLASS
      (expect count).toBe 1

    it "finds method blocks", ->
      count = _countMatchingScopes _isScopeForMethod
      (expect count).toBe 1

    it "finds constructor blocks", ->
      codeWithConstructor = [
        "public class Example {"
        "  public Example() {}"
        "}"
      ].join "\n"
      count = _countMatchingScopes _isScopeForConstructor, codeWithConstructor
      (expect count).toBe 1

    it "finds loop blocks", ->
      count = _countMatchingScopes _isScopeForForLoop
      (expect count).toBe 1

    it "finds other blocks not attached to a particular structure", ->
      count = _countMatchingScopes _isScopeForStatementBlock
      (expect count).toBe 1

  describe "when looking for scopes for a symbol", ->

    MULTISCOPE_CODE = [
      "public class Example {"
      "  public static int k = 3;"
      "  public static void main(String[] args) {"
      "    int i = 1;"
      "    {"
      "       int j = 2;"
      "       j = j + i;"
      "    }"
      "  }"
      "  public void method1() {}"
      "}"
    ].join "\n"

    fakeFile = new File ".", "E.java"
    parseTree = parse MULTISCOPE_CODE
    scopeFinder = new ScopeFinder fakeFile, parseTree

    _countSymbolScopes = (scopes, matchFunc) =>
      # Count up the number of scopes that match a given pattern
      matchCount = 0
      (matchCount += 1 if matchFunc scope) for scope in scopes
      matchCount

    it "can find a symbol in a statement block scope", ->
      # Initialize the scope finder.  This is the object under test.
      symbol = new Symbol fakeFile, "i", (new Range [6, 15], [6, 16])
      scopes = scopeFinder.findSymbolScopes symbol
      count = _countSymbolScopes scopes, _isScopeForStatementBlock
      (expect count).toBe 1

    it "can find a symbol in a method scope", ->
      symbol = new Symbol fakeFile, "i", (new Range [3, 8], [3, 9])
      scopes = scopeFinder.findSymbolScopes symbol
      count = _countSymbolScopes scopes, _isScopeForMethod
      (expect count).toBe 1

    it "can find a symbol within class declarations", ->
      symbol = new Symbol fakeFile, "k", (new Range [1, 20], [1, 21])
      scopes = scopeFinder.findSymbolScopes symbol
      count = _countSymbolScopes scopes, (scope) =>
        scope.getType() is ScopeType.CLASS
      (expect count).toBe 1

    it "can find methods (not just variables!)", ->
      symbol = new Symbol fakeFile, "method1", (new Range [9, 14], [9, 21])
      scopes = scopeFinder.findSymbolScopes
      (expect (scopes.length >= 1)).toBe true

    it "finds multiple encapsulating scopes", ->
      # This symbol is actually inside three scopes: one is a block of
      # statements, another is a method body, and another is a class body.
      symbol = new Symbol fakeFile, "i", (new Range [6, 15], [6, 16])
      scopes = scopeFinder.findSymbolScopes symbol
      (expect scopes.length).toBe 3


describe "Scope", ->

  MULTISCOPE_CODE = [
    "public class Example {"
    "  public static int k = 3;"
    "  public static void main(String[] args) {"
    "    int i = 1;"
    "    {"
    "       int j = 2;"
    "       j = j + i;"
    "    }"
    "  }"
    "  public void method1() {}"
    "}"
  ].join "\n"

  fakeFile = new File ".", "E.java"
  parseTree = parse MULTISCOPE_CODE
  scopeFinder = new ScopeFinder fakeFile, parseTree

  _isSymbolInList = (symbol, list) =>
    for listSymbol in list
      if symbol.equals listSymbol
        return true
    false

  describe "for a block of statements", ->

    BLOCK_CODE = [
      "      {"
      "        int j = 2;"
      "        int k = 3;"
      "        j = j + i;"
      "      }"
    ].join "\n"
    ctx = partialParse BLOCK_CODE, "block"
    scope = new Scope fakeFile, ctx, ScopeType.BLOCK

    it "produces a list of variables declared", ->
      symbols = scope.getDeclaredSymbols()
      (expect symbols.length).toBe 2
      (expect _isSymbolInList \
        (new Symbol fakeFile, "j", (new Range [1, 12], [1, 13])),
        symbols).toBe true
      (expect _isSymbolInList \
        (new Symbol fakeFile, "k", (new Range [2, 12], [2, 13])),
        symbols).toBe true

  describe "for a for loop", ->

    xit "includes the variables declared in loop initialization", ->
      (expect true).toBe false

  describe "for a method", ->

    METHOD_CODE = [
      "  void main(String[] args) {"
      "    int i = 1;"
      "    {"
      "       int j = 2;"
      "       j = j + i;"
      "    }"
      "  }"
    ].join "\n"
    ctx = partialParse METHOD_CODE, "methodDeclaration"
    scope = new Scope fakeFile, ctx.children[3].children[0], ScopeType.METHOD
    symbols = scope.getDeclaredSymbols()

    # This should hold true for all scopes, but we're only testing it
    # for methods right now for brevity.
    it "ignores declarations of blocks nested within it", ->
      (expect _isSymbolInList \
        (new Symbol fakeFile, "i", (new Range [1, 8], [1, 9])),
        symbols).toBe true

    it "includes declarations from parameters", ->
      (expect symbols.length).toBe 2
      (expect _isSymbolInList \
        (new Symbol fakeFile, "args", (new Range [0, 21], [0, 25])),
        symbols).toBe true

  describe "for a class", ->

    CLASS_CODE = [
      "class Example {"
      "  private int i;"
      "  public static void method1(int pi) {"
      "    int j;"
      "    int i = pi;"
      "  }"
      "}"
    ].join "\n"

    ctx = partialParse CLASS_CODE, "classDeclaration"
    scope = new Scope fakeFile, ctx.children[2], ScopeType.CLASS
    symbols = scope.getDeclaredSymbols()

    it "produces a list of variables declared", ->
      (expect _isSymbolInList \
      (new Symbol fakeFile, "i", (new Range [1, 14], [1, 15])),
        symbols).toBe true

    it "produces a list of methods declared", ->
      (expect _isSymbolInList \
      (new Symbol fakeFile, "method1", (new Range [2, 21], [2, 28])),
        symbols).toBe true

    it "includes the name of the class in the declarations", ->
      (expect symbols.length).toBe 3
      (expect _isSymbolInList \
      (new Symbol fakeFile, "Example", (new Range [0, 6], [0, 13])),
        symbols).toBe true
