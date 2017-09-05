{ MissingDefinitionError, MissingDefinitionDetector } = require '../../lib/error/missing-definition'
{ parse } = require '../../lib/analysis/parse-tree'
{ File, Symbol, SymbolSet, createSymbol, createSymbolText } = require '../../lib/model/symbol-set'
{ Range, MethodRange, RangeSet } = require '../../lib/model/range-set'
{ ExampleModel } = require "../../lib/model/example-model"
{ SymbolTable } = require "../../lib/model/symbol-table"


describe "MissingDefinitionDetector", ->

  rangeSet = undefined
  model = undefined
  detector = undefined
  beforeEach =>
    # This test is based on the following example:
    #
    # public class Example {
    #   public static void main(String[] args) {
    #     int i = 1;
    #     int j = i + 1;
    #     i = 2;
    #     i = i + j;
    #   }
    # }
    detector = new MissingDefinitionDetector()
    TEST_FILE = new File "path", "filename"

    iDef = createSymbol "path", "filename", "i", [2, 8], [2, 9], "int"
    jDef = createSymbol "path", "filename", "j", [3, 8], [3, 9], "int"
    iDef2 = createSymbol "path", "filename", "i", [4, 4], [4, 5], "int"
    iDef3 = createSymbol "path", "filename", "i", [5, 4], [5, 5], "int"

    argsUse = createSymbol "path", "filename", "args", [1, 35], [1, 39], "java.lang.String[]"
    iUse = createSymbol "path", "filename", "i", [3, 12], [3, 13], "int"
    iUse2 = createSymbol "path", "filename", "i", [5, 8], [5, 9], "int"
    jUse = createSymbol "path", "filename", "j", [5, 12], [5, 13], "int"
    tempUse = createSymbol "path", "filename", "$i0", [5, 8], [5, 13], "int"

    # In realistic scenarios, this list of symbols will be pre-populated
    # by analysis that has access to the symbol list
    symbols = new SymbolSet {
      defs: [iDef, jDef, iDef2, iDef3]
      uses: [argsUse, iUse, iUse2, jUse, tempUse]
    }
    rangeSet = new RangeSet()
    symbolTable = new SymbolTable()
    symbolTable.putDeclaration iDef, iDef.getSymbolText()
    symbolTable.putDeclaration iDef2, iDef.getSymbolText()
    symbolTable.putDeclaration iDef3, iDef.getSymbolText()
    symbolTable.putDeclaration jDef, jDef.getSymbolText()
    symbolTable.putDeclaration argsUse, createSymbolText "args", [1, 35], [1, 39]
    symbolTable.putDeclaration iUse, iDef.getSymbolText()
    symbolTable.putDeclaration iUse2, iDef.getSymbolText()
    symbolTable.putDeclaration jUse, jDef.getSymbolText()
    model = new ExampleModel undefined, rangeSet, symbols
    model.setSymbolTable symbolTable

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
      # This test is based on the following example
      # public class Example {
      #   public static void main(String[] args) {
      #     int i = 1;
      #   }
      #   public static void otherMethod(int j) {
      #     int i = 1;
      #     int k = i;
      #     System.out.println(j);
      #   }
      # }
      detector = new MissingDefinitionDetector()
      TEST_FILE = new File "path", "filename"

      iDef = createSymbol "path", "filename", "i", [2, 8], [2, 9], "int"
      iDef2 = createSymbol "path", "filename", "i", [5, 8], [5, 9], "int"
      kDef = createSymbol "path", "filename", "k", [5, 8], [5, 9], "int"

      iUse = createSymbol "path", "filename", "i", [6, 12], [6, 13], "int"
      jUse = createSymbol "path", "filename", "j", [7, 23], [7, 24], "int"

      symbols = new SymbolSet {
        defs: [iDef, iDef2, kDef]
        uses: [iUse, jUse]
      }
      rangeSet = new RangeSet()
      symbolTable = new SymbolTable()
      symbolTable.putDeclaration iDef, iDef.getSymbolText()
      symbolTable.putDeclaration iDef2, iDef.getSymbolText()
      symbolTable.putDeclaration kDef, kDef.getSymbolText()
      symbolTable.putDeclaration iUse, iUse.getSymbolText()
      symbolTable.putDeclaration jUse, createSymbolText "j", [4, 37], [4, 38]
      model = new ExampleModel undefined, rangeSet, symbols
      model.setSymbolTable symbolTable

    it "does not mark a use as defined by defs in another method", ->
      rangeSet.getSnippetRanges().reset [
        new Range [2, 0], [2, 14]
        new Range [6, 0], [6, 14]
      ]
      errors = detector.detectErrors model
      (expect errors.length).toBe 1

  # TODO: detect definitions made at the class level
