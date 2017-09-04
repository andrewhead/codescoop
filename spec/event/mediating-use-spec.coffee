{ parse } = require "../../lib/analysis/parse-tree"
{ ExampleModel } = require "../../lib/model/example-model"
{ SymbolTable } = require "../../lib/model/symbol-table"
{ File, Symbol, createSymbol } = require "../../lib/model/symbol-set"
{ Range } = require "../../lib/model/range-set"
{ MediatingUseEvent, MediatingUseDetector } = require "../../lib/event/mediating-use"


describe "MediatingUseDetector", ->

  # This test is based on the following example:
  # public class Example {
  #   public static void main(String[] args) {
  #     int i = 1;
  #     int j = 2;
  #     System.out.println(i);
  #     System.out.println(i);
  #     System.out.println(j);  // Ignored, it isn't i
  #     i + 1;
  #   }
  #   public static void anotherMethod() {
  #     int i = 1;
  #     System.out.println(i);
  #   }
  # }
  # In the 'main' function: this is where most tests will focus
  iDef = createSymbol "path", "filename", "i", [2, 8], [2, 9], "int"
  jDef = createSymbol "path", "filename", "j", [3, 8], [3, 9], "int"
  # In 'anotherMethod'.  This is for more specialized tests
  iDef2 = createSymbol "path", "filename", "i", [10, 8], [10, 9], "int"

  # In the 'main' function
  iUse = createSymbol "path", "filename", "i", [4, 23], [4, 24], "int"
  iUse2 = createSymbol "path", "filename", "i", [5, 23], [5, 24], "int"
  jUse = createSymbol "path", "filename", "j", [6, 23], [6, 24], "int"
  iUse3 = createSymbol "path", "filename", "i", [7, 4], [7, 5], "int"
  # In 'anotherMethod'
  iUse4 = createSymbol "path", "filename", "i", [11, 23], [11, 24], "int"

  model = undefined
  detector = undefined
  beforeEach =>
    model = new ExampleModel()
    model.getSymbols().getVariableUses().reset [iUse, iUse2, jUse, iUse3, iUse4]
    model.getSymbols().getVariableDefs().reset [iDef, jDef, iDef2]
    symbolTable = new SymbolTable()
    symbolTable.putDeclaration iDef, iDef.getSymbolText()
    symbolTable.putDeclaration iUse, iDef.getSymbolText()
    symbolTable.putDeclaration iUse2, iDef.getSymbolText()
    symbolTable.putDeclaration iUse3, iDef.getSymbolText()
    symbolTable.putDeclaration iDef2, iDef2.getSymbolText()
    symbolTable.putDeclaration iUse4, iDef2.getSymbolText()
    symbolTable.putDeclaration jDef, jDef.getSymbolText()
    symbolTable.putDeclaration jUse, jDef.getSymbolText()
    model.setSymbolTable symbolTable
    detector = new MediatingUseDetector model

  it "finds uses between a def and use and returns them in line order", ->
    (expect model.getEvents().length).toBe 0
    snippetRanges = [
      new Range [2, 0], [2, 14]  # 'i' def
      new Range [7, 0], [7, 10]  # 'i' final use
    ]
    model.getRangeSet().getSnippetRanges().reset snippetRanges
    (expect model.getEvents().length).toBe 2
    events = model.getEvents()
    (expect events[0] instanceof MediatingUseEvent).toBe true
    (expect events[0].getDef().getRange()).toEqual new Range [2, 8], [2, 9]
    (expect events[0].getUse().getRange()).toEqual new Range [7, 4], [7, 5]
    (expect events[0].getMediatingUse().getRange()).toEqual new Range [4, 23], [4, 24]
    (expect events[1].getMediatingUse().getRange()).toEqual new Range [5, 23], [5, 24]

  it "only recommends uses that aren't in the active ranges", ->
    snippetRanges = [
      new Range [2, 0], [2, 14]  # 'i' def
      new Range [5, 0], [5, 26]  # 'i' mediating use #1
      new Range [7, 0], [7, 10]  # 'i' final use
    ]
    model.getRangeSet().getSnippetRanges().reset snippetRanges
    (expect model.getEvents().length).toBe 1
    (expect model.getEvents()[0].getMediatingUse().getRange()).toEqual \
      new Range [4, 23], [4, 24]

  it "only associates defs and uses in the same scope", ->
    # These two active ranges contain an unrelated def and use.  The
    # event detector should find no link between the two.
    snippetRanges = [
      new Range [2, 0], [2, 14]    # 'i' def in 'main'
      new Range [11, 0], [11, 26]  # 'i' final use in 'anotherMethod'
    ]
    model.getRangeSet().getSnippetRanges().reset snippetRanges
    (expect model.getEvents().length).toBe 0

  it "doesn't detect an intervening use that was already queued", ->
    model.getEvents().push new MediatingUseEvent \
      (createSymbol "path", "filename", "i", [2, 8], [2, 9], "int"),    # 'i' def
      (createSymbol "path", "filename", "i", [7, 4], [7, 5], "int"),    # 'i' final use
      (createSymbol "path", "filename", "i", [5, 23], [5, 24], "int")   # 'i' mediating use
    # This set of active ranges will produce exactly the same mediating
    # event as the one that is already enqueued in the model's events
    snippetRanges = [
      new Range [2, 0], [2, 14]  # 'i' def
      new Range [7, 0], [7, 10]  # 'i' final use
    ]
    model.getRangeSet().getSnippetRanges().reset snippetRanges
    (expect model.getEvents().length).toBe 2

  it "doesn't detect an intervening use that was already viewed", ->
    model.getViewedEvents().push new MediatingUseEvent \
      (createSymbol "path", "filename", "i", [2, 8], [2, 9], "int"),    # 'i' def
      (createSymbol "path", "filename", "i", [7, 4], [7, 5], "int"),    # 'i' final use
      (createSymbol "path", "filename", "i", [5, 23], [5, 24], "int")   # 'i' mediating use
    # This set of active ranges will produce exactly the same mediating
    # event as the one that is already enqueued in the model's events
    snippetRanges = [
      new Range [2, 0], [2, 14]  # 'i' def
      new Range [7, 0], [7, 10]  # 'i' final use
    ]
    model.getRangeSet().getSnippetRanges().reset snippetRanges
    (expect model.getEvents().length).toBe 1

  it "marks an event as obselete when the use isn't in the active ranges", ->
    event = new MediatingUseEvent iDef, iUse, iUse2
    model.getRangeSet().getSnippetRanges().reset [iDef.getRange()]
    (expect detector.isEventObsolete event).toBe true

  it "marks an event as obselete when the use isn't in the active ranges", ->
    event = new MediatingUseEvent iDef, iUse, iUse2
    model.getRangeSet().getSnippetRanges().reset [iUse.getRange()]
    (expect detector.isEventObsolete event).toBe true

  describe "when there are nested scopes", ->

    model = undefined
    detector = undefined
    beforeEach =>
      # This test case is based on the following example:
      # public class Example {
      #   public static void main(String[] args) {
      #     int i = 1;
      #     {
      #         int i = 2;
      #         System.out.println(i);
      #     }
      #     i + 1;
      #   }
      # }

      iDef = createSymbol "path", "filename", "i", [2, 8], [2, 9], "int"
      iDef2 = createSymbol "path", "filename", "i", [4, 12], [4, 13], "int"
      iUse = createSymbol "path", "filename", "i", [5, 27], [5, 28], "int"
      iUse2 = createSymbol "path", "filename", "i", [7, 4], [7, 5], "int"

      model = new ExampleModel()
      model.getSymbols().getVariableUses().reset [iUse, iUse2]
      model.getSymbols().getVariableDefs().reset [iDef, iDef2]
      symbolTable = new SymbolTable()
      symbolTable.putDeclaration iDef, iDef.getSymbolText()
      symbolTable.putDeclaration iDef2, iDef2.getSymbolText()
      symbolTable.putDeclaration iUse, iDef2.getSymbolText()
      symbolTable.putDeclaration iUse2, iDef.getSymbolText()
      model.setSymbolTable symbolTable
      detector = new MediatingUseDetector model

    it "only detects uses that correspond to the declaration of the def", ->
      # In other words, it shouldn't find the printed `i` on line 5, which
      # refers to a different `i`.
      snippetRanges = [
        new Range [2, 0], [2, 14]  # 'i' def
        new Range [7, 0], [7, 10]  # 'i' final use
      ]
      model.getRangeSet().getSnippetRanges().reset snippetRanges
      (expect model.getEvents().length).toBe 0
