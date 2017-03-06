{ MissingDeclarationError, MissingDeclarationDetector } = require '../lib/error/missing-declarations'
{ parse } = require '../lib/parse-tree'
{ Symbol, SymbolSet } = require '../lib/model/symbol-set'
{ Range, RangeSet } = require '../lib/range-set'


describe "MissingDeclarationDetector", ->

  describe "when called on a simple 'main'", ->
    parseTree = parse [
      "public class Example {"
      "  public static void main(String[] args) {"
      "    int i = 0;"
      "    int j = i + 1;"
      "    System.out.println(args);"
      "  }"
      "}"
    ].join "\n"
    symbolSet = new SymbolSet [
      new Symbol "Example.java", "args", new Range [1, 35], [1, 39]
      new Symbol "Example.java", "i", new Range [2, 8], [2, 9]
      new Symbol "Example.java", "j", new Range [3, 8], [3, 9]
      new Symbol "Example.java", "i", new Range [3, 12], [3, 13]
      new Symbol "Example.java", "args", new Range [4, 19], [4, 23]
    ]
    detector = new MissingDeclarationDetector()

    it "returns nothing when all symbols are declared", ->
      rangeSet = new RangeSet [ new Range [2, 0], [2, 14] ]
      errors = detector.detectErrors parseTree, rangeSet, symbolSet
      (expect errors.length).toBe 0

    it "returns the symbols that are missing declarations", ->
      rangeSet = new RangeSet [ new Range [3, 0], [3, 18] ]
      errors = detector.detectErrors parseTree, rangeSet, symbolSet
      (expect errors.length).toBe 1
      error = errors[0]
      (expect error instanceof MissingDeclarationError).toBe true
      (expect error.getSymbol().getName()).toBe "i"
      (expect error.getSymbol().getRange()).toEqual new Range [3, 12], [3, 13]

    it "returns parameter uses missing declarations", ->
      rangeSet = new RangeSet [ new Range [4, 0], [4, 25] ]
      errors = detector.detectErrors parseTree, rangeSet, symbolSet
      error = errors[0]
      (expect error.getSymbol().getName()).toBe "args"

  describe "when called on a class with members", ->

    # TODO: I included calls to members of 'this' in the example below.
    # In the future, we should be able to detect when symbols on 'this'
    # or other local classes are undefined and add code for them.
    parseTree = parse [
      "public class Example {"
      "  public int memberInt;"
      "  public void memberMethod() {}"
      "  public void doWork() {"
      "    memberInt = 1;"
      "    this.memberInt = memberInt + 1;"
      "    memberMethod();"
      "    this.memberMethod();"
      "  }"
      "}"
    ].join "\n"
    # This is an incomplete set of the symbols that would be detected, but
    # it should be enough to run the declaration error detector.
    symbolSet = new SymbolSet [
      new Symbol "Example.java", "memberInt", new Range [4, 4], [4, 13]
      new Symbol "Example.java", "memberMethod", new Range [6, 4], [6, 16]
    ]
    detector = new MissingDeclarationDetector()

    # In practice, we hope that programmers don't include class declarations
    # in their code.  If they're creating snippets on the order of a single
    # method, then all of the declaration should be made in method body.
    # But we include this test to make sure the error detector's logic is sound.
    it "doesn't detect errors when the class members are included", ->
      rangeSet = new RangeSet [
        (new Range [1, 0], [2, 31])  # Lines with declarations
        (new Range [4, 0], [4, 22])  # definition of memberInt
        (new Range [6, 0], [6, 23])  # use of memberMethod
      ]
      errors = detector.detectErrors parseTree, rangeSet, symbolSet
      (expect errors.length).toBe 0

    it "detects undeclared class variables", ->
      rangeSet = new RangeSet [ new Range [4, 0], [4, 22] ]
      errors = detector.detectErrors parseTree, rangeSet, symbolSet
      (expect errors.length).toBe 1
      error = errors[0]
      (expect error.getSymbol().getName()).toBe "memberInt"

    it "detects undeclared class methods (not just variables!)", ->
      rangeSet = new RangeSet [ new Range [6, 0], [6, 23] ]
      errors = detector.detectErrors parseTree, rangeSet, symbolSet
      (expect errors.length).toBe 1
      error = errors[0]
      (expect error.getSymbol().getName()).toBe "memberMethod"
