{ ExampleModel, ExampleModelState } = require "../lib/model/example-model"
{ ExampleController } = require "../lib/example-controller"
{ VariableDefUseAnalysis } = require "../lib/analysis/variable-def-use"
{ Range, RangeSet } = require "../lib/model/range-set"
{ File, Symbol, SymbolSet } = require "../lib/model/symbol-set"
{ ValueAnalysis, ValueMap } = require "../lib/analysis/value-analysis"
{ StubAnalysis } = require "../lib/analysis/stub-analysis"
{ TypeDefUseAnalysis } = require "../lib/analysis/type-def-use"
{ ImportAnalysis } = require "../lib/analysis/import-analysis"
{ PACKAGE_PATH } = require "../lib/config/paths"
{ parse } = require "../lib/analysis/parse-tree"
fs = require "fs"


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

    code = (fs.readFileSync testFile.getPath()).toString()
    parseTree = parse code

    # Prepare the analyses
    variableDefUseAnalysis = new VariableDefUseAnalysis testFile
    typeDefUseAnalysis = new TypeDefUseAnalysis testFile, parseTree
    importAnalysis = new ImportAnalysis testFile
    valueAnalysis = new ValueAnalysis testFile
    stubAnalysis = new StubAnalysis testFile
    model = new ExampleModel _makeCodeBuffer(),
      (new RangeSet [ new Range [5, 0], [5, 10] ]), new SymbolSet(),
      parseTree, new ValueMap()

    controller = undefined
    importTable = undefined
    typeDefs = undefined
    variableDefs = undefined
    valueMap = undefined
    stubSpecTable = undefined

    it "enters the IDLE state when initial analyses finish", ->

      # When the controller starts, it will run the analyses one after another
      runs ->
        controller = new ExampleController model,
          analyses: { variableDefUseAnalysis, typeDefUseAnalysis, valueAnalysis,
              stubAnalysis, importAnalysis }

      # Wait for the analyses to finish
      waitsFor =>

        importTable = model.getImportTable()
        variableDefs = model.getSymbols().getVariableDefs()
        typeDefs = model.getSymbols().getTypeDefs()
        valueMap = model.getValueMap()
        stubSpecTable = model.getStubSpecTable()

        ((variableDefs.length > 0) and valueMap? and stubSpecTable? and
          (typeDefs.length > 0) and
          valueMap? and ("Example.java" of valueMap) and
          stubSpecTable? and
          importTable?)

      # Once analyses complete, we wait for a transition into the IDLE state
      waitsFor =>
        model.getState() is ExampleModelState.IDLE

      runs ->

        _expectIn = (name, range, symbols) =>
          foundSymbol = false
          for otherSymbol in symbols
            if (otherSymbol.getName() is name) and
                (otherSymbol.getRange().isEqual range)
              foundSymbol = true
          (expect foundSymbol).toBe true

        # Check that the analyses have updated the model with valid symbols
        _expectIn "j", (new Range [5, 8], [5, 9]), variableDefs
        _expectIn "Example", (new Range [0, 13], [0, 20]), typeDefs

  _makeMockVariableDefUseAnalysis = =>
    # For the sake of fast timing, we mock out the variable-def-use analysis.
    # We control the definition that it returns when looking for the earliest
    # definition before the symbol, trusting in practice it will do the right thing.
    variableDefUseAnalysis = jasmine.createSpyObj 'variableDefUseAnalysis', ['run', 'getDefs', 'getUses']
    variableDefUseAnalysis.getDefs = => []
    variableDefUseAnalysis.getUses = => []
    variableDefUseAnalysis.run = (success, error) => success variableDefUseAnalysis
    variableDefUseAnalysis

  describe "when in the IDLE state", ->

    model = undefined
    controller = undefined
    variableDefUseAnalysis = undefined
    correctors = undefined

    describe "when handling errors", ->

      beforeEach =>
        correctors = [
            checker:
              detectErrors: (parseTree, rangeSet, symbolSet) => []
        ]
        model = _makeDefaultModel()
        variableDefUseAnalysis = _makeMockVariableDefUseAnalysis()
        controller = new ExampleController model,
          { analyses: { variableDefUseAnalysis }, correctors }
        waitsFor (=>
            model.getState() is ExampleModelState.IDLE
          ), "Waiting for state"

      it "leaves the state at IDLE if no errors found", ->
        model.getRangeSet().getActiveRanges().push new Range [0, 0], [0, 10]
        (expect model.getState()).toBe ExampleModelState.IDLE

      it "applies correctors when new lines are added", ->

        # Spy on the first corrector to make sure that it was used to detect errors
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
        firstCorrector.checker.detectErrors = (parseTree, rangeSet, symbolSet) =>
          [ "error1", "error2"]

        secondCorrector =
          name: "mock-corrector-2"
          checker: { detectErrors: (parseTree, rangeSet, symbolSet) => [] }
          suggester: { getSuggestions: (error, parseTree, rangeSet, symbolSet) => [] }
          fixer: { applyFixes: (suggestion, rangeSet, symbolSet) => true }
        correctors.push secondCorrector

        (spyOn firstCorrector.checker, "detectErrors").andCallThrough()
        (spyOn secondCorrector.checker, "detectErrors").andCallThrough()

        model.getRangeSet().getActiveRanges().push new Range [0, 0], [0, 10]

        (expect firstCorrector.checker.detectErrors).toHaveBeenCalled()
        (expect secondCorrector.checker.detectErrors).not.toHaveBeenCalled()

      it "updates to ERROR_CHOICE when lines are chosen and errors found", ->
        correctors[0].checker.detectErrors = () => [ "error1" ]
        model.getRangeSet().getActiveRanges().push new Range [0, 0], [0, 10]
        (expect model.getState()).toBe ExampleModelState.ERROR_CHOICE

      it "updates model errors when lines are chosen and errors are found", ->
        correctors[0].checker.detectErrors = () => [ "error1", "error2" ]
        model.getRangeSet().getActiveRanges().push new Range [0, 0], [0, 10]
        (expect model.getErrors()).toEqual [ "error1", "error2" ]

      it "transitions to ERROR_CHOICE if it enters IDLE with errors", ->
        correctors[0].checker.detectErrors = () => [ "error1" ]
        model.getRangeSet().getActiveRanges().push new Range [0, 0], [0, 10]
        (expect model.getState()).toBe ExampleModelState.ERROR_CHOICE

      it "saves a reference to the corrector that found the error", ->
        (expect model.getActiveCorrector()).toBe null
        correctors[0].checker.detectErrors = () => [ "error1" ]
        model.getRangeSet().getActiveRanges().push new Range [0, 0], [0, 10]
        (expect model.getActiveCorrector()).toBe correctors[0]

    describe "when handling events", ->

      model = undefined
      controller = undefined
      extenders = undefined

      describe "where the events are enqueued in IDLE state", ->

        beforeEach =>
          correctors = [
              checker: { detectErrors: () => [] }
          ]
          extenders = [
              extender: { getExtension: (event) => { isExtension: true } }
          ]
          model = _makeDefaultModel()
          controller = new ExampleController model, { correctors, extenders }
          waitsFor =>
            model.getState() is ExampleModelState.IDLE

        it "transitions to EXTENSION if events were detected", ->
          event = { eventId: 42 }
          model.getEvents().push event
          model.getRangeSet().getActiveRanges().push new Range [0, 1], [0, 2]
          (expect model.getState()).toBe ExampleModelState.EXTENSION
          (expect "isExtension" of model.getProposedExtension()).toBe true
          (expect model.getFocusedEvent().eventId).toBe 42

        it "does not transition if there was no extension for the event", ->
          event = {}
          extenders[0].extender.getExtension = (event) => null
          model.getEvents().push event
          (expect model.getState()).toBe ExampleModelState.IDLE

      describe "where the events were already enqueued before IDLE state", ->

        beforeEach =>
          correctors = [
              # Add an error that could be detected, because we want IDLE
              # to transition to EXTENSION even when there are errors waiting
              # to be resolved.
              checker: { detectErrors: () => [ "error" ] }
          ]
          extenders = [
              extender: { getExtension: (event) => {} }
          ]
          model = _makeDefaultModel()
          model.getEvents().reset [ { eventId: 1 }, { eventId: 2 } ]
          controller = new ExampleController model, { correctors, extenders }

          # This time, the controller will go straight into extension state,
          # because events are waiting for it after it enters IDLE
          waitsFor =>
            model.getState() is ExampleModelState.EXTENSION

        it "prioritizes transition to EXTENSION of transition to ERROR_CHOICE", ->
          (expect model.getState()).toBe ExampleModelState.EXTENSION

        it "proposes extensions in the order that events were encountered", ->
          (expect model.getFocusedEvent().eventId).toBe 1


  describe "when in the ERROR_CHOICE state", ->

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
    model = undefined
    controller = undefined

    beforeEach =>

      runs =>
        model = _makeDefaultModel()
        controller = new ExampleController model, { correctors }

      waitsFor =>
        model.getState() is ExampleModelState.ERROR_CHOICE

      runs =>
        # Here, we simulate the choice of an error
        model.setErrorChoice "error"

    it "updates the state to RESOLUTION when an error is chosen", ->
      (expect model.getState()).toBe ExampleModelState.RESOLUTION

    it "populates the resolution options for the error from all suggesters", ->
      (expect model.getSuggestions()).toEqual [1, 2, 3, 5]


  describe "when in the RESOLUTION state", ->

    # These lines get the controller into the RESOLUTION state
    fixer = { apply: (model, update) -> @appliedUpdate = update }
    correctors = [{
      checker: { detectErrors: -> [ "error" ] }
      suggesters: [ { getSuggestions: -> [1] } ]
    }]
    model = _makeDefaultModel()
    controller = new ExampleController model, { correctors, fixer }
    model.getRangeSet().getActiveRanges().push new Range [0, 0], [0, 10]
    model.setState ExampleModelState.RESOLUTION
    model.setActiveCorrector correctors[0]

    # Before faking the resolution, pretend the errors have gone away
    correctors[0].checker.detectErrors = => []
    model.setResolutionChoice { resolutionId: 42 }

    it "updates the state to IDLE when a resolution was chosen", ->
      (expect model.getState()).toBe ExampleModelState.IDLE

    it "applies the corrector's fix", ->
      (expect fixer.appliedUpdate.resolutionId).toBe 42

    it "sets the active corrector back to nothing", ->
      (expect model.getActiveCorrector()).toBe null


  describe "when in the EXTENSION state", ->

    model = undefined
    controller = undefined
    fixer = undefined

    beforeEach =>
      extenders = [ extender: { getExtension: (event) => {} } ]
      fixer = { apply: (model, value) -> @wasCalledWithValue = value }
      model = _makeDefaultModel()
      model.getEvents().reset [ { eventId: 1 } ]
      controller = new ExampleController model, { extenders, fixer }
      waitsFor =>
        model.getState() is ExampleModelState.EXTENSION

    it "transitions back to IDLE when an extension was accepted", ->
      model.setExtensionDecision true
      (expect model.getState()).toBe ExampleModelState.IDLE

    it "transitions back to IDLE when an extension was rejected", ->
      model.setExtensionDecision false
      (expect model.getState()).toBe ExampleModelState.IDLE

    it "applies the extension when an extension was accepted", ->
      (expect fixer.wasCalledWithValue?).toBe false
      model.setExtensionDecision true
      (expect fixer.wasCalledWithValue).toEqual {}

    it "does not apply the extension when an extension was rejected", ->
      (expect fixer.wasCalledWithValue?).toBe false
      model.setExtensionDecision false
      (expect fixer.wasCalledWithValue?).toBe false

    it "dequeues the event when the extension was accepted", ->
      model.setExtensionDecision true
      (expect model.getEvents()).toEqual []

    it "dequeues the event when the extension was rejected", ->
      model.setExtensionDecision false
      (expect model.getEvents()).toEqual []

    it "saves the event that caused the extension, if accepted", ->
      model.setExtensionDecision true
      (expect model.getViewedEvents().length).toBe 1
      (expect model.getViewedEvents()[0].eventId).toBe 1

    it "saves the event that caused the extension, if rejected", ->
      model.setExtensionDecision true
      (expect model.getViewedEvents().length).toBe 1
      (expect model.getViewedEvents()[0].eventId).toBe 1

    it "on transition, it sets extension-related model fields to null", ->
      model.setExtensionDecision true
      (expect model.getFocusedEvent()).toBe null
      (expect model.getProposedExtension()).toBe null
      (expect model.getExtensionDecision()).toBe null
