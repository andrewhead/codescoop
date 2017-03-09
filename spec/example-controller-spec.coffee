{ ExampleModel, ExampleModelState } = require '../lib/model/example-model'
{ ExampleController } = require '../lib/example-controller'
{ DefUseAnalysis } = require '../lib/analysis/def-use'
{ Range, RangeSet } = require '../lib/model/range-set'
{ File, Symbol, SymbolSet } = require '../lib/model/symbol-set'
{ ValueAnalysis, ValueMap } = require '../lib/analysis/value-analysis'
{ RangeAddition } = require '../lib/edit/range-addition'
{ PACKAGE_PATH } = require '../lib/config/paths'


describe "ExampleController", ->

  testFile = new File \
    PACKAGE_PATH + "/java/tests/analysis_examples/Example.java", "Example.java"

  _makeCodeBuffer = =>
    editor = atom.workspace.buildTextEditor()
    editor.getBuffer()

  _makeDefaultModel = =>
    new ExampleModel _makeCodeBuffer(), new RangeSet(), new SymbolSet(),
      (jasmine.createSpyObj 'parseTree', ['getRoot']), new ValueMap()

  describe "when in the ANALYSIS state", ->

    defUseAnalysis = new DefUseAnalysis testFile
    valueAnalysis = new ValueAnalysis testFile
    model = new ExampleModel _makeCodeBuffer(),
      (new RangeSet [ new Range [5, 0], [5, 10] ]), new SymbolSet(),
      (jasmine.createSpyObj 'parseTree', ['getRoot']), new ValueMap()

    # These variables will be set by our first test case
    controller = undefined
    defs = undefined
    valueMap = undefined

    it "enters the IDLE state when initial analyses finish", ->

      runs ->
        controller = new ExampleController model, { defUseAnalysis, valueAnalysis }, []

      # After creating the controller, we wait for analyses to finish
      waitsFor =>
        defs = model.getSymbols().getDefs()
        valueMap = model.getValueMap()
        ((defs.length > 0) and ("Example.java" of valueMap))

      runs ->
        (expect model.getState()).toEqual ExampleModelState.IDLE

        _in = (symbol, symbols) =>
          for otherSymbol in symbols
            return true if otherSymbol.equals symbol
          false

        # Check that the analyses have updated the model with valid symbols
        (expect _in \
          (new Symbol testFile, "j", (new Range [5, 8], [5, 9]), "int"),
          defs).toBe true

  _makeMockDefUseAnalysis = =>
    # For the sake of fast timing, we mock out the def-use analysis.
    # We control the definition that it returns when looking for the earliest
    # definition before the symbol, trusting in practice it will do the right thing.
    defUseAnalysis = jasmine.createSpyObj 'defUseAnalysis', ['run', 'getDefs', 'getUses']
    defUseAnalysis.getDefs = => []
    defUseAnalysis.getUses = => []
    defUseAnalysis.run = (success, error) => success defUseAnalysis
    defUseAnalysis

  describe "when in the IDLE state", ->

    correctors = [
        checker:
          detectErrors: (parseTree, rangeSet, symbolSet) => []
        # Checkers will also have suggesters, but that isn't important here.
    ]
    defUseAnalysis = _makeMockDefUseAnalysis()
    analyses = { defUseAnalysis }

    it "leaves the state at IDLE if no errors found", ->
      model = _makeDefaultModel()
      controller = new ExampleController model, analyses, correctors
      model.getRangeSet().getActiveRanges().push new Range [0, 0], [0, 10]
      (expect model.getState()).toBe ExampleModelState.IDLE

    it "applies correctors when new lines are added", ->

      # Spy on the first corrector to make sure that it was used to detect errors
      model = _makeDefaultModel()
      new ExampleController model, analyses, correctors

      # Update the corrector to return errors, as if they were caused by
      # the addition of new ranges.  XXX: this will cause this corrector
      # to return errors in the upcoming tests too.
      firstCorrector = correctors[0]
      firstCorrector.checker.detectErrors = (parseTree, rangeSet, symbolSet) =>
        [ "error1", "error2"]
      (spyOn firstCorrector.checker, "detectErrors").andCallThrough()
      (expect firstCorrector.checker.detectErrors).not.toHaveBeenCalled()

      # Once we update the active ranges, the corrector should be applied
      model.getRangeSet().getActiveRanges().push new Range [0, 0], [0, 10]
      (expect firstCorrector.checker.detectErrors).toHaveBeenCalled()

    it "applies correctors in the order they were added to the controller", ->

      # The first corrector returns a non-empty list of errors
      # (even a set of string).  Because it returns some errors, the second
      # corrector (initialized below) should never be invoked.
      firstCorrector = correctors[0]
      secondCorrector =
        name: "mock-corrector-2"
        checker: { detectErrors: (parseTree, rangeSet, symbolSet) => [] }
        suggester: { getSuggestions: (error, parseTree, rangeSet, symbolSet) => [] }
        fixer: { applyFixes: (suggestion, rangeSet, symbolSet) => true }
      correctors.push secondCorrector

      (spyOn firstCorrector.checker, "detectErrors").andCallThrough()
      (spyOn secondCorrector.checker, "detectErrors").andCallThrough()

      model = _makeDefaultModel()
      new ExampleController model, analyses, correctors
      model.getRangeSet().getActiveRanges().push new Range [0, 0], [0, 10]

      (expect firstCorrector.checker.detectErrors).toHaveBeenCalled()
      (expect secondCorrector.checker.detectErrors).not.toHaveBeenCalled()

    it "updates to ERROR_CHOICE when lines are chosen and errors found", ->
      model = _makeDefaultModel()
      controller = new ExampleController model, analyses, correctors
      model.getRangeSet().getActiveRanges().push new Range [0, 0], [0, 10]
      (expect model.getState()).toBe ExampleModelState.ERROR_CHOICE

    it "updates model errors when lines are chosen and errors are found", ->
      model = _makeDefaultModel()
      controller = new ExampleController model, analyses, correctors
      model.getRangeSet().getActiveRanges().push new Range [0, 0], [0, 10]
      (expect model.getErrors()).toEqual [ "error1", "error2" ]

    it "transitions to ERROR_CHOICE if it enters IDLE with errors", ->
      model = _makeDefaultModel()
      controller = new ExampleController model, analyses, correctors
      model.getRangeSet().getActiveRanges().push new Range [0, 0], [0, 10]
      (expect model.getState()).toBe ExampleModelState.ERROR_CHOICE

    it "saves a reference to the corrector that found the error", ->
      correctors = [ { checker: { detectErrors: -> ["error"] } } ]
      model = _makeDefaultModel()
      (expect model.getActiveCorrector()).toBe null
      controller = new ExampleController model, analyses, correctors
      (expect model.getActiveCorrector()).toBe correctors[0]


  describe "when in the ERROR_CHOICE state", ->

    defUseAnalysis = _makeMockDefUseAnalysis()
    analyses = { defUseAnalysis }

    # A mock corrector that does nothing but detect an error
    # and give primitive fix suggestions
    correctors = [{
      checker: { detectErrors: -> [ "error" ] }
      suggesters: [
        { getSuggestions: (error) -> if error is "error" then [1, 2] else [] }
        { getSuggestions: (error) -> if error is "error" then [3] else [4] }
        { getSuggestions: (error) -> [5] }
      ]
    }]

    # These lines get us into the ERROR_CHOICE state
    model = _makeDefaultModel()
    controller = new ExampleController model, analyses, correctors

    # Here, we simulate the choice of an error
    model.setErrorChoice "error"

    it "updates the state to RESOLUTION when an error is chosen", ->
      (expect model.getState()).toBe ExampleModelState.RESOLUTION

    it "populates the resolution options for the error from all suggesters", ->
      (expect model.getSuggestions()).toEqual [1, 2, 3, 5]


  describe "when in the RESOLUTION state", ->

    defUseAnalysis = _makeMockDefUseAnalysis()
    analyses = { defUseAnalysis }

    # These lines get the controller into the RESOLUTION state
    correctors = [{
      checker: { detectErrors: -> [ "error" ] }
      suggesters: [ { getSuggestions: -> [1] } ]
    }]
    model = _makeDefaultModel()
    controller = new ExampleController model, analyses, correctors
    model.getRangeSet().getActiveRanges().push new Range [1, 0], [1, 10]
    model.setErrorChoice "error"

    # Before faking the resolution, pretend the errors have gone away
    correctors[0].checker.detectErrors = => []

    model.setResolutionChoice new RangeAddition new Range [0, 0], [0, 10]

    it "updates the state to IDLE when a resolution was chosen", ->
      (expect model.getState()).toBe ExampleModelState.IDLE

    it "applies the corrector's fix", ->
      activeRanges = model.getRangeSet().getActiveRanges()
      (expect activeRanges.length).toBe 2
      (expect activeRanges[1]).toEqual new Range [0, 0], [0, 10]

    it "sets the active corrector back to nothing", ->
      (expect model.getActiveCorrector()).toBe null
