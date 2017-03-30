{ MissingDeclarationError, MissingDeclarationDetector } = require '../../lib/error/missing-declaration'
{ parse } = require '../../lib/analysis/parse-tree'
{ File, Symbol, SymbolSet } = require '../../lib/model/symbol-set'
{ Range, RangeSet } = require '../../lib/model/range-set'
{ ExampleModel } = require "../../lib/model/example-model"
{ Declaration } = require "../../lib/edit/Declaration"


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
    TEST_FILE = new File "path", "filename"
    symbolSet = new SymbolSet {
      defs: [
        new Symbol TEST_FILE, "i", (new Range [2, 8], [2, 9]), "int"
        new Symbol TEST_FILE, "j", (new Range [3, 8], [3, 9]), "int"
        new Symbol TEST_FILE, "$r0", (new Range [4, 4], [4, 14]), "java.io.PrintStream"
      ]
      uses: [
        new Symbol TEST_FILE, "i", (new Range [3, 12], [3, 13]), "int"
        new Symbol TEST_FILE, "args", (new Range [4, 19], [4, 23]), "java.lang.String[]"
      ]}
    rangeSet = new RangeSet()
    model = new ExampleModel undefined, rangeSet, symbolSet, parseTree
    detector = new MissingDeclarationDetector()

    it "returns nothing when all symbols are declared", ->
      rangeSet.getSnippetRanges().reset [ new Range [2, 0], [2, 14] ]
      errors = detector.detectErrors model
      (expect errors.length).toBe 0

    it "returns the symbols that are missing declarations", ->
      rangeSet.getSnippetRanges().reset [ new Range [3, 0], [3, 18] ]
      errors = detector.detectErrors model
      (expect errors.length).toBe 1
      error = errors[0]
      (expect error instanceof MissingDeclarationError).toBe true
      (expect error.getSymbol().getName()).toBe "i"
      (expect error.getSymbol().getRange()).toEqual new Range [3, 12], [3, 13]

    it "returns parameter uses missing declarations", ->
      rangeSet.getSnippetRanges().reset [ new Range [4, 0], [4, 25] ]
      errors = detector.detectErrors model
      error = errors[0]
      (expect error.getSymbol().getName()).toBe "args"

    it "skips temporary symbols", ->
      rangeSet.getSnippetRanges().reset [ new Range [4, 0], [4, 25] ]
      errors = detector.detectErrors model
      # Missing declarations should only include "args", not "System.out"
      (expect errors.length).toBe 1

    it "skips over variables that have already had a declaration fix", ->
      rangeSet.getSnippetRanges().reset [ new Range [4, 0], [4, 25] ]
      model.getAuxiliaryDeclarations().push new Declaration "args", "java.lang.String[]"
      errors = detector.detectErrors model
      (expect errors.length).toBe 0

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
    TEST_FILE = new File "path", "filename"
    # This is an incomplete set of the symbols that would be detected, but
    # it should be enough to run the declaration error detector.
    symbolSet = new SymbolSet {
      defs: [
        new Symbol TEST_FILE, "memberInt", (new Range [4, 4], [4, 13]), "int"
        new Symbol TEST_FILE, "memberMethod", (new Range [6, 4], [6, 16]), "method"
      ]}
    rangeSet = new RangeSet()
    model = new ExampleModel undefined, rangeSet, symbolSet, parseTree
    detector = new MissingDeclarationDetector()

    # In practice, we hope that programmers don't include class declarations
    # in their code.  If they're creating snippets on the order of a single
    # method, then all of the declaration should be made in method body.
    # But we include this test to make sure the error detector's logic is sound.
    it "doesn't detect errors when the class members are included", ->
      rangeSet.getSnippetRanges().reset [
        (new Range [1, 0], [2, 31])  # Lines with declarations
        (new Range [4, 0], [4, 22])  # definition of memberInt
        (new Range [6, 0], [6, 23])  # use of memberMethod
      ]
      errors = detector.detectErrors model
      (expect errors.length).toBe 0

    it "detects undeclared class variables", ->
      rangeSet.getSnippetRanges().reset [ new Range [4, 0], [4, 22] ]
      errors = detector.detectErrors model
      (expect errors.length).toBe 1
      error = errors[0]
      (expect error.getSymbol().getName()).toBe "memberInt"

    it "detects undeclared class methods (not just variables!)", ->
      rangeSet.getSnippetRanges().reset [ new Range [6, 0], [6, 23] ]
      errors = detector.detectErrors model
      (expect errors.length).toBe 1
      error = errors[0]
      (expect error.getSymbol().getName()).toBe "memberMethod"
