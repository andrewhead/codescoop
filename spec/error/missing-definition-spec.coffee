{ MissingDefinitionError, MissingDefinitionDetector } = require '../../lib/error/missing-definition'
{ parse } = require '../../lib/analysis/parse-tree'
{ Symbol, SymbolSet } = require '../../lib/model/symbol-set'
{ Range, RangeSet } = require '../../lib/model/range-set'


describe "MissingDefinitionDetector", ->

  parseTree = parse [
    "public class Example {"
    "  public static void main(String[] args) {"
    "    int i = 1;"
    "    int j = i + 1;"
    "    i = 2;"
    "  }"
    "}"
  ].join "\n"
  detector = new MissingDefinitionDetector()

  # In realistic scenarios, this list of symbols will be pre-populated
  # by analysis that has access to the symbol list
  symbols = new SymbolSet {
    defs: [
      (new Symbol "Example.java", "i", new Range [2, 8], [2, 9])
      (new Symbol "Example.java", "j", new Range [3, 8], [3, 9])
      (new Symbol "Example.java", "i", new Range [4, 4], [4, 5])
    ],
    uses: [
      (new Symbol "Example.java", "args", new Range [1, 35], [1, 39])
      (new Symbol "Example.java", "i", new Range [3, 12], [3, 13])
    ]
  }

  it "reports no problems when no variables lack definitions", ->
    rangeSet = new RangeSet [ new Range [2, 0], [2, 14] ]
    errors = detector.detectErrors parseTree, rangeSet, symbols
    (expect errors.length).toBe 0

  it "detects missing variable definitions", ->
    rangeSet = new RangeSet [ new Range [3, 0], [3, 18] ]
    errors = detector.detectErrors parseTree, rangeSet, symbols
    (expect errors.length).toBe 1
    error = errors[0]
    (expect error.getSymbol().getName()).toEqual "i"
    (expect error.getSymbol().getRange()).toEqual new Range [3, 12], [3, 13]

  it "doesn't flag a variable as defined if definition occurs below a use", ->
    rangeSet = new RangeSet [
      new Range [3, 0], [3, 18]
      new Range [4, 0], [4, 10]
    ]
    errors = detector.detectErrors parseTree, rangeSet, symbols
    (expect errors.length).toBe 1
    (expect errors[0].getSymbol().getName()).toEqual "i"

  # TODO: detect definitions made at the class level
