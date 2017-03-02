{ ExampleModel, ExampleModelState } = require '../lib/example-view'
{ ExampleController } = require '../lib/example-controller'
{ DefUseAnalysis } = require '../lib/def-use'
{ LineSet } = require '../lib/line-set'
{ SymbolSet } = require '../lib/symbol-set'
{ PACKAGE_PATH } = require '../lib/paths'

describe "ExampleController", ->

  _makeCodeBuffer = =>
    editor = atom.workspace.buildTextEditor()
    editor.getBuffer()

  # Make def-use analysis that automatically returns itself
  testFilePath = PACKAGE_PATH + "/java/tests/analysis_examples/Example.java"
  testFileName = "Example.java"

  it "updates model state to PICK_UNDEFINED when analysis done", ->

    defUseAnalysis = new DefUseAnalysis testFilePath, testFileName
    model = new ExampleModel _makeCodeBuffer(), new LineSet(), new SymbolSet()

    # Some time after the controller is created, the state should
    # transition to PICK_UNDEFINED (though it may take some time)
    runs =>
      controller = new ExampleController model, defUseAnalysis
    waitsFor =>
      model.getState() == ExampleModelState.PICK_UNDEFINED
    , "The model state should become PICK_UNDEFINED", 2000

  it "udates the symbol set using analysis results", ->

    defUseAnalysis = new DefUseAnalysis testFilePath, testFileName
    model = new ExampleModel _makeCodeBuffer(), new LineSet([6]), new SymbolSet()

    # Also, this list of undefined uses should be updated to those learned
    # from the def-use analysis
    runs ->
      controller = new ExampleController model, defUseAnalysis
    waitsFor =>
      undefinedUses = model.getSymbols().getUndefinedUses()
      use = undefinedUses[0]
      (undefinedUses.length is 1 and
        (use.name is "i") and
        (use.line is 6) and
        (use.start is 13) and
        (use.end is 14))
    , "Undefined uses don't match expectation", 2000
