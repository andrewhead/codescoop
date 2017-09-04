{ ExampleModel, ExampleModelState } = require "../lib/model/example-model"
{ ExampleController } = require "../lib/example-controller"
{ Range, RangeSet } = require "../lib/model/range-set"
{ File, Symbol, SymbolSet } = require "../lib/model/symbol-set"

{ ImportAnalysis } = require "../lib/analysis/import-analysis"
{ VariableDefUseAnalysis } = require "../lib/analysis/variable-def-use"
{ MethodDefUseAnalysis } = require "../lib/analysis/method-def-use"
{ TypeDefUseAnalysis } = require "../lib/analysis/type-def-use"
{ ValueAnalysis, ValueMap } = require "../lib/analysis/value-analysis"
{ StubAnalysis } = require "../lib/analysis/stub-analysis"
{ DeclarationsAnalysis } = require "../lib/analysis/declarations"
{ RangeGroupsAnalysis } = require "../lib/analysis/range-groups"
{ ThrowsAnalysis } = require "../lib/analysis/throws-analysis"
{ CatchAnalysis } = require "../lib/analysis/catch"
{ CatchVariableDefAnalysis } = require "../lib/analysis/catch-variable-def"

{ AddRange } = require "../lib/command/add-range"
{ AddPrintedSymbol } = require "../lib/command/add-printed-symbol"
{ ArchiveEvent } = require "../lib/command/archive-event"
{ CommandStack } = require "../lib/command/command-stack"
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
    parseTree = jasmine.createSpyObj 'parseTree', ['getRoot', 'getCtxForRange']
    parseTree.getCtxForRange = => null
    new ExampleModel _makeCodeBuffer(), new RangeSet(), new SymbolSet(),
      parseTree, new ValueMap()

  describe "when in the ANALYSIS state", ->

    code = (fs.readFileSync testFile.getPath()).toString()
    parseTree = parse code

    symbolSet = new SymbolSet()
    model = new ExampleModel _makeCodeBuffer(),
      (new RangeSet [ new Range [5, 0], [5, 10] ]), symbolSet,
      parseTree, new ValueMap()

    # Prepare the analyses
    variableDefUseAnalysis = new VariableDefUseAnalysis testFile
    catchVariableDefAnalysis = new CatchVariableDefAnalysis testFile, parseTree, model
    methodDefUseAnalysis = new MethodDefUseAnalysis testFile, parseTree
    typeDefUseAnalysis = new TypeDefUseAnalysis testFile, parseTree
    importAnalysis = new ImportAnalysis testFile
    valueAnalysis = new ValueAnalysis testFile
    stubAnalysis = new StubAnalysis testFile
    declarationsAnalysis = new DeclarationsAnalysis symbolSet, testFile, parseTree
    rangeGroupsAnalysis = new RangeGroupsAnalysis parseTree
    throwsAnalysis = new ThrowsAnalysis testFile
    catchAnalysis = new CatchAnalysis model

    controller = undefined
    importTable = undefined
    variableDefs = undefined
    methodDefs = undefined
    typeDefs = undefined
    valueMap = undefined
    stubSpecTable = undefined
    symbolTable = undefined
    rangeGroupTable = undefined
    throwsTable = undefined

    it "enters the IDLE state when initial analyses finish", ->

      # When the controller starts, it will run the analyses one after another
      runs ->
        controller = new ExampleController model,
          analyses: { importAnalysis, catchVariableDefAnalysis,
            variableDefUseAnalysis, methodDefUseAnalysis, typeDefUseAnalysis,
            valueAnalysis, stubAnalysis, declarationsAnalysis,
            rangeGroupsAnalysis, throwsAnalysis, catchAnalysis }

      # Wait for the analyses to finish
      waitsFor =>

        importTable = model.getImportTable()
        variableDefs = model.getSymbols().getVariableDefs()
        methodDefs = model.getSymbols().getMethodDefs()
        typeDefs = model.getSymbols().getTypeDefs()
        valueMap = model.getValueMap()
        stubSpecTable = model.getStubSpecTable()
        symbolTable = model.getSymbolTable()
        rangeGroupTable = model.getRangeGroupTable()
        throwsTable = model.getThrowsTable()
        catchTable = model.getCatchTable()

        ((variableDefs.length > 0) and valueMap? and stubSpecTable? and
          (methodDefs.length > 0) and (typeDefs.length > 0) and
          valueMap? and ("Example.java" of valueMap) and
          stubSpecTable? and
          importTable? and
          symbolTable? and
          rangeGroupTable? and
          throwsTable? and
          catchTable?)

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
        _expectIn "main", (new Range [2, 21], [2, 25]), methodDefs
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
            suggesters: []
        ]
        model = _makeDefaultModel()
        variableDefUseAnalysis = _makeMockVariableDefUseAnalysis()
        controller = new ExampleController model,
          { analyses: { variableDefUseAnalysis }, correctors }
        waitsFor (=>
            model.getState() is ExampleModelState.IDLE
          ), "Waiting for state"

      it "leaves the state at IDLE if no errors found", ->
        model.getRangeSet().getSnippetRanges().push new Range [0, 0], [0, 10]
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
        model.getRangeSet().getSnippetRanges().push new Range [0, 0], [0, 10]
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
          suggesters: [{ getSuggestions: (error, parseTree, rangeSet, symbolSet) => [] }]
          commandCreator: { applyFixes: (suggestion, rangeSet, symbolSet) => true }
        correctors.push secondCorrector

        (spyOn firstCorrector.checker, "detectErrors").andCallThrough()
        (spyOn secondCorrector.checker, "detectErrors").andCallThrough()

        model.getRangeSet().getSnippetRanges().push new Range [0, 0], [0, 10]

        (expect firstCorrector.checker.detectErrors).toHaveBeenCalled()
        (expect secondCorrector.checker.detectErrors).not.toHaveBeenCalled()

      it "updates to ERROR_CHOICE when lines are chosen and errors found", ->
        correctors[0].checker.detectErrors = () => [ "error1" ]
        model.getRangeSet().getSnippetRanges().push new Range [0, 0], [0, 10]
        (expect model.getState()).toBe ExampleModelState.ERROR_CHOICE

      it "updates model errors when lines are chosen and errors are found", ->
        correctors[0].checker.detectErrors = () => [ "error1", "error2" ]
        model.getRangeSet().getSnippetRanges().push new Range [0, 0], [0, 10]
        (expect model.getErrors()).toEqual [ "error1", "error2" ]

      it "transitions to ERROR_CHOICE if it enters IDLE with errors", ->
        correctors[0].checker.detectErrors = () => [ "error1" ]
        model.getRangeSet().getSnippetRanges().push new Range [0, 0], [0, 10]
        (expect model.getState()).toBe ExampleModelState.ERROR_CHOICE

      it "saves a reference to the corrector that found the error", ->
        (expect model.getActiveCorrector()).toBe null
        correctors[0].checker.detectErrors = () => [ "error1" ]
        model.getRangeSet().getSnippetRanges().push new Range [0, 0], [0, 10]
        (expect model.getActiveCorrector()).toBe correctors[0]

    describe "when handling events", ->

      model = undefined
      controller = undefined
      extenders = undefined

      it "discards events that couldn't be handled by any extender", ->
        extenders = [ extender: { getExtension: (event) => null } ]
        model = new ExampleModel()
        model.getEvents().push { eventId: 42 }
        (expect model.getEvents().length).toBe 1
        controller = new ExampleController model, { extenders }
        waitsFor =>
          model.getState() is ExampleModelState.IDLE
        runs =>
          (expect model.getEvents().length).toBe 0

      describe "where the events are enqueued in IDLE state", ->

        beforeEach =>
          correctors = [
              checker: { detectErrors: () => [] }
              suggesters: []
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
          model.getRangeSet().getSnippetRanges().push new Range [0, 1], [0, 2]
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
              suggesters: []
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

    command = { apply: (model) -> @wasApplied = true }
    commandStack = new CommandStack()
    commandCreator = { createCommandGroupForSuggestion: (s) -> [ command ] }
    model = _makeDefaultModel()
    controller = new ExampleController model, { commandCreator, commandStack }
    model.getRangeSet().getSnippetRanges().push new Range [0, 0], [0, 10]
    model.setState ExampleModelState.RESOLUTION
    model.setActiveCorrector { correctorId: 42 }
    model.setResolutionChoice { resolutionId: 42 }

    it "updates the state to IDLE when a resolution was chosen", ->
      (expect model.getState()).toBe ExampleModelState.IDLE

    it "adds a relevant command to the stack", ->
      (expect commandStack.peek()[0]).toBe command

    it "applies the corrector's fix", ->
      (expect command.wasApplied).toBe true

    it "sets the active corrector back to nothing", ->
      (expect model.getActiveCorrector()).toBe null

  describe "when in the EXTENSION state", ->

    model = undefined
    controller = undefined
    commandStack = undefined

    beforeEach =>
      extenders = [ extender: { getExtension: (event) => {} } ]
      commandStack = new CommandStack()
      model = _makeDefaultModel()
      model.getEvents().reset [ { eventId: 1 } ]
      controller = new ExampleController model, { extenders, commandStack }
      waitsFor =>
        model.getState() is ExampleModelState.EXTENSION
      runs =>
        model.setExtensionDecision true

    it "transitions back to IDLE when an extension was accepted", ->
      (expect model.getState()).toBe ExampleModelState.IDLE

    it "applies archive commands and adds them to the stack", ->
      (expect commandStack.getHeight()).toBe 1
      commandGroup = commandStack.peek()
      (expect commandGroup[0] instanceof ArchiveEvent)

    it "on transition, it sets extension-related model fields to null", ->
      (expect model.getFocusedEvent()).toBe null
      (expect model.getProposedExtension()).toBe null
      (expect model.getExtensionDecision()).toBe null

  describe "when `undo` is called on it", ->

    model = undefined
    controller = undefined
    commandCreator = undefined
    commandStack = undefined
    command = undefined

    beforeEach =>

      commandStack = new CommandStack()
      command = { revert: (model) -> @revertCalled = true }
      commandStack.push [ command ]

      # Move the controller into the RESOLUTION state
      correctors = [{
        checker: { detectErrors: -> [] }
        suggesters: [ { getSuggestions: -> [1] } ]
      }]
      model = _makeDefaultModel()
      controller = new ExampleController model, { correctors, commandStack }
      model.setState ExampleModelState.RESOLUTION

      # Set a bunch of properties on the model that should be rewound
      model.setActiveCorrector correctors[0]
      model.setErrorChoice { errorId: 42 }
      model.getSuggestions().reset [{ suggestionId: 42 }]

      # Now, the important part: call undo
      controller.undo()

    it "sets the state to IDLE", ->
      (expect model.getState()).toBe ExampleModelState.IDLE

    it "pops one command off the command stack", ->
      (expect commandStack.getHeight()).toBe 0

    it "calls revert on the command at the top of the stack", ->
      (expect command.revertCalled).toBe true

    it "sets decision-related model variables to null", ->
      (expect model.getActiveCorrector()).toBe null
      (expect model.getErrorChoice()).toBe null
      (expect model.getSuggestions().length).toBe 0

  describe "when active ranges are added in the middle of another task", ->

    model = undefined
    controller = undefined

    beforeEach =>

      # Move the controller into the RESOLUTION state
      correctors = [{
        checker: { detectErrors: -> [] }
        suggesters: [ { getSuggestions: -> [1] } ]
      }]
      model = _makeDefaultModel()
      controller = new ExampleController model, { correctors }
      model.setState ExampleModelState.RESOLUTION

      # Set a bunch of properties on the model that should be rewound
      model.setActiveCorrector correctors[0]
      model.setErrorChoice { errorId: 42 }
      model.getSuggestions().reset [{ suggestionId: 42 }]

      # Add a new range to the model
      model.getRangeSet().getSnippetRanges().push new Range [0, 0], [0, 10]

    it "resets the state to IDLE", ->
      (expect model.getState()).toBe ExampleModelState.IDLE

    it "resets decision-related model variables to null", ->
      (expect model.getActiveCorrector()).toBe null
      (expect model.getErrorChoice()).toBe null
      (expect model.getSuggestions().length).toBe 0

  describe "when active ranges are added in the middle of another task", ->

    commandStack = new CommandStack()
    model = _makeDefaultModel()
    controller = new ExampleController model, { commandStack }

    # Simulate a user choosing a new range
    model.getRangeSet().getChosenRanges().push new Range [0, 0], [0, 10]

    it "removes the range from the list of chosen ranges", ->
      (expect model.getRangeSet().getChosenRanges().length).toBe 0

    it "adds the range to the list of snippet ranges", ->
      (expect commandStack.getHeight()).toBe 1
      commandGroup = commandStack.peek()
      (expect commandGroup[0] instanceof AddRange)
      (expect commandGroup[0].getRange()).toEqual new Range [0, 0], [0, 10]

  describe "when a print request is added in the middle of another task", ->

    commandStack = undefined
    model = undefined
    controller = undefined
    beforeEach =>
      commandStack = new CommandStack()
      model = _makeDefaultModel()
      controller = new ExampleController model, { commandStack }

    it "adds the print request to the command stack", ->
      controller.addPrintedSymbol "temp"
      (expect commandStack.getHeight()).toBe 1
      (expect (commandStack.peek()[0] instanceof AddPrintedSymbol)).toBe true

    it "applies the print request to the model", ->
      controller.addPrintedSymbol "temp"
      (expect model.getPrintedSymbols().length).toBe 1
      (expect model.getPrintedSymbols()[0]).toBe "temp"
