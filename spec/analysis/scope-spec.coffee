{ InputStream, CommonTokenStream } = require "antlr4"
{ JavaParser } = require "../../lib/grammar/Java/JavaParser"
{ ScopeFinder } = require "../../lib/analysis/scope"
{ BlockScope, ForLoopScope, MethodScope, ClassScope } = require "../../lib/analysis/scope"
{ parse, partialParse } = require "../../lib/analysis/parse-tree"
{ Symbol, SymbolText, File } = require "../../lib/model/symbol-set"
{ Range } = require "../../lib/model/range-set"


describe "ScopeFinder", ->

  _isScopeForMethod = (scope) => scope instanceof MethodScope

  _isScopeForConstructor = (scope) =>
    (scope instanceof MethodScope) and
      (scope.getCtx().parentCtx.ruleIndex is JavaParser.RULE_constructorBody)

  _isScopeForForLoop = (scope) => scope instanceof ForLoopScope

  _isScopeForStatementBlock = (scope) => scope instanceof BlockScope

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
      count = _countMatchingScopes (scope) => scope instanceof ClassScope
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
      symbol = new SymbolText "i", (new Range [6, 15], [6, 16])
      scopes = scopeFinder.findSymbolScopes symbol
      count = _countSymbolScopes scopes, _isScopeForStatementBlock
      (expect count).toBe 1

    it "can find a symbol in a method scope", ->
      symbol = new SymbolText "i", (new Range [3, 8], [3, 9])
      scopes = scopeFinder.findSymbolScopes symbol
      count = _countSymbolScopes scopes, _isScopeForMethod
      (expect count).toBe 1

    it "can find a symbol within class declarations", ->
      symbol = new SymbolText "k", (new Range [1, 20], [1, 21])
      scopes = scopeFinder.findSymbolScopes symbol
      count = _countSymbolScopes scopes, (scope) => scope instanceof ClassScope
      (expect count).toBe 1

    it "can find methods (not just variables!)", ->
      symbol = new SymbolText "method1", (new Range [9, 14], [9, 21])
      scopes = scopeFinder.findSymbolScopes symbol
      (expect (scopes.length >= 1)).toBe true

    it "finds multiple encapsulating scopes", ->
      # This symbol is actually inside three scopes: one is a block of
      # statements, another is a method body, and another is a class body.
      symbol = new SymbolText "i", (new Range [6, 15], [6, 16])
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

  _isSymbolTextInList = (symbolText, list) =>
    for listSymbolText in list
      if symbolText.equals listSymbolText
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
    scope = new BlockScope fakeFile, ctx

    it "produces a list of variables declared", ->
      symbols = scope.getDeclarations()
      (expect symbols.length).toBe 2
      (expect _isSymbolTextInList \
        (new SymbolText "j", (new Range [1, 12], [1, 13])),
        symbols).toBe true
      (expect _isSymbolTextInList \
        (new SymbolText "k", (new Range [2, 12], [2, 13])),
        symbols).toBe true

  describe "for a for loop", ->

    it "includes the variables declared in loop initialization", ->

      FOR_CODE = [
        "      for (int i = 0; i < 2; i++) {"
        "        System.out.println(i);"
        "      }"
      ].join "\n"
      ctx = partialParse FOR_CODE, "statement"
      blockCtx = ctx.children[4].children[0]
      scope = new ForLoopScope fakeFile, blockCtx

      symbols = scope.getDeclarations()
      (expect symbols.length).toBe 1
      (expect _isSymbolTextInList \
        (new SymbolText "i", (new Range [0, 15], [0, 16])),
        symbols).toBe true

    it "also includes declarations from enhanced for loop control", ->

      ENHANCED_CONTROL_FOR_CODE = [
        "      for (String s: strings) {"
        "        System.out.println(s);"
        "      }"
      ].join "\n"
      ctx = partialParse ENHANCED_CONTROL_FOR_CODE, "statement"
      blockCtx = ctx.children[4].children[0]
      scope = new ForLoopScope fakeFile, blockCtx

      symbols = scope.getDeclarations()
      (expect symbols.length).toBe 1
      (expect _isSymbolTextInList \
        (new SymbolText "s", (new Range [0, 18], [0, 19])),
        symbols).toBe true

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
    scope = new MethodScope fakeFile, ctx.children[3].children[0]
    symbols = scope.getDeclarations()

    # This should hold true for all scopes, but we're only testing it
    # for methods right now for brevity.
    it "ignores declarations of blocks nested within it", ->
      (expect _isSymbolTextInList \
        (new SymbolText "i", (new Range [1, 8], [1, 9])),
        symbols).toBe true

    it "includes declarations from parameters", ->
      (expect symbols.length).toBe 2
      (expect _isSymbolTextInList \
        (new SymbolText "args", (new Range [0, 21], [0, 25])),
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
    scope = new ClassScope fakeFile, ctx.children[2]
    symbols = scope.getDeclarations()

    it "produces a list of variables declared", ->
      (expect _isSymbolTextInList \
      (new SymbolText "i", (new Range [1, 14], [1, 15])),
        symbols).toBe true

    it "produces a list of methods declared", ->
      (expect _isSymbolTextInList \
      (new SymbolText "method1", (new Range [2, 21], [2, 28])),
        symbols).toBe true

    it "includes the name of the class in the declarations", ->
      (expect symbols.length).toBe 3
      (expect _isSymbolTextInList \
      (new SymbolText "Example", (new Range [0, 6], [0, 13])),
        symbols).toBe true
