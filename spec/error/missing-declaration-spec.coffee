{ MissingDeclarationError, MissingDeclarationDetector } = require '../../lib/error/missing-declaration'
{ parse } = require '../../lib/analysis/parse-tree'
{ File, Symbol, SymbolSet, createSymbol, createSymbolText } = require '../../lib/model/symbol-set'
{ Range, RangeSet } = require '../../lib/model/range-set'
{ ExampleModel } = require "../../lib/model/example-model"
{ Declaration } = require "../../lib/edit/Declaration"
{ SymbolTable } = require "../../lib/model/symbol-table"


describe "MissingDeclarationDetector", ->

  # This test case is based on the following code:
  # public class Example {
  #   public static void main(String[] args) {
  #     int i = 0;
  #     int j = i + 1;
  #     System.out.println(args);
  #   }
  # }

  rangeSet = new RangeSet()
  symbolSet = new SymbolSet {
    defs: [
      createSymbol "path", "file", "i", [2, 8], [2, 9], "int"
      createSymbol "path", "file", "j", [3, 8], [3, 9], "int"
      createSymbol "path", "file", "$r0", [4, 4], [4, 14], "java.io.PrintStream"
    ]
    uses: [
      createSymbol "path", "file", "i", [3, 12], [3, 13], "int"
      createSymbol "path", "file", "args", [4, 19], [4, 23], "java.lang.String[]"
    ]}

  model = new ExampleModel undefined, rangeSet, symbolSet
  symbolTable = new SymbolTable()
  symbolTable.putDeclaration \
    (createSymbol "path", "file", "i", [3, 12], [3, 13], "int"),
    (createSymbolText "i", [2, 8], [2, 9])
  symbolTable.putDeclaration \
    (createSymbol "path", "file", "i", [2, 8], [2, 9], "int"),
    (createSymbolText "i", [2, 8], [2, 9])
  symbolTable.putDeclaration \
    (createSymbol "path", "file", "args", [4, 19], [4, 23], "java.lang.String[]"),
    (createSymbolText "args", [1, 35], [1, 39])
  symbolTable.putDeclaration \
    (createSymbol "path", "file", "j", [3, 8], [3, 9], "java.lang.String[]"),
    (createSymbolText "j", [3, 8], [3, 9])
  model.setSymbolTable symbolTable

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

  it "skips temporary symbols", ->
    rangeSet.getSnippetRanges().reset [ new Range [4, 0], [4, 25] ]
    errors = detector.detectErrors model
    # Missing declarations should not include "args" or "System.out"
    (expect errors.length).toBe 0

  it "skips over variables that have already had a declaration fix", ->
    rangeSet.getSnippetRanges().reset [ new Range [4, 0], [4, 25] ]
    model.getAuxiliaryDeclarations().push new Declaration "args", "java.lang.String[]"
    errors = detector.detectErrors model
    (expect errors.length).toBe 0
