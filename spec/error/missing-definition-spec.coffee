{ MissingDefinitionError, MissingDefinitionDetector } = require '../../lib/error/missing-definition'
{ parse } = require '../../lib/analysis/parse-tree'
{ File, Symbol, SymbolSet } = require '../../lib/model/symbol-set'
{ Range, MethodRange, RangeSet } = require '../../lib/model/range-set'
{ ExampleModel } = require "../../lib/model/example-model"


describe "MissingDefinitionDetector", ->

  rangeSet = undefined
  model = undefined
  detector = undefined
  beforeEach =>
    parseTree = parse [
      "public class Example {"
      "  public static void main(String[] args) {"
      "    int i = 1;"
      "    int j = i + 1;"
      "    i = 2;"
      "    i = i + j;"
      "  }"
      "}"
    ].join "\n"
    detector = new MissingDefinitionDetector()
    TEST_FILE = new File "path", "filename"

    # In realistic scenarios, this list of symbols will be pre-populated
    # by analysis that has access to the symbol list
    symbols = new SymbolSet {
      defs: [
        (new Symbol TEST_FILE, "i", (new Range [2, 8], [2, 9]), "int")
        (new Symbol TEST_FILE, "j", (new Range [3, 8], [3, 9]), "int")
        (new Symbol TEST_FILE, "i", (new Range [4, 4], [4, 5]), "int")
        (new Symbol TEST_FILE, "i", (new Range [5, 4], [5, 5]), "int")
      ],
      uses: [
        (new Symbol TEST_FILE, "args", (new Range [1, 35], [1, 39]), "java.lang.String[]")
        (new Symbol TEST_FILE, "i", (new Range [3, 12], [3, 13]), "int")
        (new Symbol TEST_FILE, "i", (new Range [5, 8], [5, 9]), "int")
        (new Symbol TEST_FILE, "j", (new Range [5, 12], [5, 13]), "int")
        (new Symbol TEST_FILE, "$i0", (new Range [5, 8], [5, 13]), "int")
      ]
    }
    rangeSet = new RangeSet()
    model = new ExampleModel undefined, rangeSet, symbols, parseTree

  it "reports no problems when no variables lack definitions", ->
    rangeSet.getSnippetRanges().reset [ new Range [2, 0], [2, 14] ]
    errors = detector.detectErrors model
    (expect errors.length).toBe 0

  it "detects missing variable definitions", ->
    rangeSet.getSnippetRanges().reset [ new Range [3, 0], [3, 18] ]
    errors = detector.detectErrors model
    (expect errors.length).toBe 1
    error = errors[0]
    (expect error.getSymbol().getName()).toEqual "i"
    (expect error.getSymbol().getRange()).toEqual new Range [3, 12], [3, 13]

  it "doesn't flag a variable as defined if definition occurs below a use", ->
    rangeSet.getSnippetRanges().reset [
      new Range [3, 0], [3, 18]
      new Range [4, 0], [4, 14]
    ]
    errors = detector.detectErrors model
    (expect errors.length).toBe 1
    (expect errors[0].getSymbol().getName()).toEqual "i"

  it "skips temporary variables (those with a $)", ->
    rangeSet.getSnippetRanges().reset [
      new Range [2, 0], [3, 18]
      new Range [5, 0], [4, 10]
    ]
    errors = detector.detectErrors model
    (expect errors.length).toBe 0

  describe "when uses are distributed across methods", ->

    rangeSet = undefined
    model = undefined
    detector = undefined
    beforeEach =>
      parseTree = parse [
        "public class Example {"
        "  public static void main(String[] args) {"
        "    int i = 1;"
        "  }"
        "  public static void otherMethod(int j) {"
        "    int i = 1;"
        "    int k = i;"
        "    System.out.println(j);"
        "  }"
        "}"
      ].join "\n"
      detector = new MissingDefinitionDetector()
      TEST_FILE = new File "path", "filename"
      symbols = new SymbolSet {
        defs: [
          (new Symbol TEST_FILE, "i", (new Range [2, 8], [2, 9]), "int")
          (new Symbol TEST_FILE, "i", (new Range [5, 8], [5, 9]), "int")
          (new Symbol TEST_FILE, "k", (new Range [5, 8], [5, 9]), "int")
        ],
        uses: [
          (new Symbol TEST_FILE, "i", (new Range [6, 12], [6, 13]), "int")
          (new Symbol TEST_FILE, "j", (new Range [7, 23], [7, 24]), "int")
        ]
      }
      rangeSet = new RangeSet()
      model = new ExampleModel undefined, rangeSet, symbols, parseTree

    it "does not mark a use as defined by defs in another method", ->
      rangeSet.getSnippetRanges().reset [
        new Range [2, 0], [2, 14]
        new Range [6, 0], [6, 14]
      ]
      errors = detector.detectErrors model
      (expect errors.length).toBe 1

    it "does not mark a use as undefined if the use was used in a " +
        "method range and defined in the method signature", ->
      rangeSet.getSnippetRanges().reset [ new Range [7, 0], [7, 26] ]
      rangeSet.getMethodRanges().reset [
        new MethodRange (new Range [4, 2], [8, 3]), undefined, true
      ]
      errors = detector.detectErrors model
      (expect errors.length).toBe 0

  # TODO: detect definitions made at the class level
