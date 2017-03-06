{ ExampleModel, ExampleModelState } = require '../lib/example-view'
{ ExampleController } = require '../lib/example-controller'
{ DefUseAnalysis } = require '../lib/def-use'
{ Range, RangeSet } = require '../lib/model/range-set'
{ Symbol, SymbolSet } = require '../lib/model/symbol-set'
{ ValueAnalysis, ValueMap } = require '../lib/value-analysis'
{ PACKAGE_PATH } = require '../lib/paths'

describe "ExampleController", ->

  _makeCodeBuffer = =>
    editor = atom.workspace.buildTextEditor()
    editor.getBuffer()

  _makeMockDefUseAnalysis = =>
    # For the sake of fast timing, we mock out the def-use analysis.
    # We control the definition that it returns when looking for the earliest
    # definition before the symbol, trusting in practice it will do the right thing.
    defUseAnalysis = jasmine.createSpyObj 'defUseAnalysis',
      ['run', 'getDefBeforeUse']
    defUseAnalysis.getDefBeforeUse = (use) =>
      new Symbol "Example.java", "item", new Range [0, 5], [0, 8]
    defUseAnalysis.getUndefinedUses = (activeRanges) =>
      [ new Symbol "Example.java", "item", new Range [1, 12], [1, 16] ]
    defUseAnalysis

  _makeDefaultModel = =>
    new ExampleModel _makeCodeBuffer(), new RangeSet(), new SymbolSet(), new ValueMap()

  testFilePath = PACKAGE_PATH + "/java/tests/analysis_examples/Example.java"
  testFileName = "Example.java"

  it "updates model state to PICK_UNDEFINED when analysis done", ->

    defUseAnalysis = new DefUseAnalysis testFilePath, testFileName
    model = _makeDefaultModel()

    # Some time after the controller is created, the state should
    # transition to PICK_UNDEFINED (though it may take some time)
    runs =>
      controller = new ExampleController model, defUseAnalysis
    waitsFor =>
      model.getState() == ExampleModelState.PICK_UNDEFINED
    , "the controller to transition the state to PICK_UNDEFINED", 2000

  it "udates the symbol set using analysis results", ->

    defUseAnalysis = new DefUseAnalysis testFilePath, testFileName
    model = new ExampleModel _makeCodeBuffer(),
      (new RangeSet [ new Range [5, 0], [5, 10] ]),
      new SymbolSet(), new ValueMap()

    # Also, this list of undefined uses should be updated to those learned
    # from the def-use analysis
    runs ->
      controller = new ExampleController model, defUseAnalysis
    waitsFor =>
      undefinedUses = model.getSymbols().getUndefinedUses()
      use = undefinedUses[0]
      (undefinedUses.length is 1 and
        (use.name is "i") and
        (use.getRange().start.row is 5) and
        (use.getRange().start.column is 12) and
        (use.getRange().end.column is 13))
    , "undefined uses should be set once analysis complete", 2000

  it "updates the variable map with results of variable analysis", ->

    defUseAnalysis = _makeMockDefUseAnalysis()
    valueAnalysis = new ValueAnalysis testFilePath, testFileName
    model = _makeDefaultModel()

    runs ->
      controller = new ExampleController model, defUseAnalysis, valueAnalysis
    waitsFor =>
      valueMap = model.getValueMap()
      ("Example.java" of valueMap) and
        (5 of valueMap["Example.java"]) and
        ("i" of valueMap["Example.java"][5]) and
        (valueMap["Example.java"][5]["i"] is "1")
    , "value map should be updated by the controller", 2000

  describe "when a target has been set", ->

    defUseAnalysis = _makeMockDefUseAnalysis()
    model = _makeDefaultModel()
    controller = new ExampleController model, defUseAnalysis

    # Here is the stimulus that causes the state change in the model
    model.setState ExampleModelState.PICK_UNDEFINED
    model.setTarget new Symbol "Example.java", "item", new Range [1, 12], [1, 16]

    it "updates the state to DEFINE", ->
      (expect model.getState()).toBe ExampleModelState.DEFINE

    it "adds a definition to the symbol set", ->
      (expect model.getSymbols().getDefinition()).toEqual \
        new Symbol "Example.java", "item", new Range [0, 5], [0, 8]

  it "updates the state from DEFINE to PICK_UNDEFINED when new line added", ->

    defUseAnalysis = _makeMockDefUseAnalysis()
    model = _makeDefaultModel()
    controller = new ExampleController model, defUseAnalysis
    model.setState ExampleModelState.DEFINE

    (expect model.getState()).toBe ExampleModelState.DEFINE
    model.getRangeSet().getActiveRanges().push new Range [6, 0], [6, 10]
    (expect model.getState()).toBe ExampleModelState.PICK_UNDEFINED

  it "updates the undefined uses after new definitions", ->

    defUseAnalysis = _makeMockDefUseAnalysis()
    model = _makeDefaultModel()
    controller = new ExampleController model, defUseAnalysis
    model.setState ExampleModelState.DEFINE

    (expect model.getSymbols().getUndefinedUses()).toEqual []
    model.getRangeSet().getActiveRanges().push new Range [1, 0], [1, 10]
    (expect model.getSymbols().getUndefinedUses()).toEqual \
      [ new Symbol "Example.java", "item", new Range [1, 12], [1, 16] ]
