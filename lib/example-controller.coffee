{ ExampleModelState, ExampleModelProperty } = require "./model/example-model"
{ Fixer } = require "./command/fixer"

{ MissingDefinitionDetector } = require "./error/missing-definition"
{ MissingDeclarationDetector } = require "./error/missing-declaration"
{ MissingTypeDefinitionDetector } = require "./error/missing-type-definition"
{ ControlCrossingDetector } = require "./event/control-crossing"

{ DefinitionSuggester } = require "./suggester/definition-suggester"
{ DeclarationSuggester } = require "./suggester/declaration-suggester"
{ PrimitiveValueSuggester } = require "./suggester/primitive-value-suggester"
{ InstanceStubSuggester } = require "./suggester/instance-stub-suggester"
{ ImportSuggester } = require "./suggester/import-suggester"
{ ControlStructureExtender } = require "./extender/control-structure-extender"


module.exports.ExampleController = class ExampleController

  constructor: (model, extras = {}) ->

    # Listen to all changes in the model
    @model = model
    @model.addObserver @

    # Create a fixer that will update the model with corrections
    @fixer = extras.fixer or new Fixer()

    analyses = extras.analyses or {}
    importAnalysis = analyses.importAnalysis
    variableDefUseAnalysis = analyses.variableDefUseAnalysis
    typeDefUseAnalysis = analyses.typeDefUseAnalysis
    valueAnalysis = analyses.valueAnalysis
    stubAnalysis = analyses.stubAnalysis

    @correctors = extras.correctors or [
        checker: new MissingDefinitionDetector()
        suggesters: [
          new DefinitionSuggester()
          new PrimitiveValueSuggester()
          new InstanceStubSuggester()
        ]
      ,
        checker: new MissingTypeDefinitionDetector()
        suggesters: [ new ImportSuggester() ]
      ,
        checker: new MissingDeclarationDetector()
        suggesters: [ new DeclarationSuggester() ]
    ]
    @extenders = extras.extenders or [
        listener: new ControlCrossingDetector model
        extender: new ControlStructureExtender()
    ]

    # Before the state can update, the analyses must complete
    @_startAnalyses importAnalysis, variableDefUseAnalysis, typeDefUseAnalysis,
      valueAnalysis, stubAnalysis

  _startAnalyses: (importAnalysis, variableDefUseAnalysis, typeDefUseAnalysis,
    valueAnalysis, stubAnalysis) ->

    # Save a reference to analyses
    @analyses =
      import:
        runner: importAnalysis
        callback: (importTable) =>
          @model.setImportTable importTable
        error: console.error
      variableDefUse:
        runner: variableDefUseAnalysis
        callback: (analysis) =>
          @model.getSymbols().setVariableDefs analysis.getDefs()
          @model.getSymbols().setVariableUses analysis.getUses()
        error: console.error
      typeDefUse:
        runner: typeDefUseAnalysis
        callback: (result) =>
          @model.getSymbols().setTypeDefs result.typeDefs
          @model.getSymbols().setTypeUses result.typeUses
        error: console.error
      value:
        runner: valueAnalysis or= null
        callback: (valueMap) =>
          @model.setValueMap valueMap
        error: console.error
      stub:
        runner: stubAnalysis or= null
        callback: (stubSpecTable) =>
          @model.setStubSpecTable stubSpecTable
        error: console.error

    # Run analyses sequentially.  Soot can't handle when more than one
    # analysis is running at a time.  Pattern reference for chaining promises:
    # http://stackoverflow.com/questions/24586110/resolve-promises-one-after-another-i-e-in-sequence
    analysisDone = Promise.resolve()
    for _, analysis of @analyses
      analysisDone = analysisDone.then (() ->
        new Promise (resolve, reject) =>
          resolve() if not @runner?
          @runner.run ((outcome) =>
            @callback outcome
            resolve()
          ), () =>
            # Even on error, claim that we have "resolved" the promise,
            # just so we can keep moving onto the next analysis.
            @error()
            resolve()
        ).bind analysis
    analysisDone.then =>
      @model.setState ExampleModelState.IDLE

  checkForCorrections: ->
    for corrector in @correctors
      errors = corrector.checker.detectErrors @model
      if errors.length > 0
        # It's important that the state gets set last, as it's the
        # state change that the view will be refreshing on
        @model.setErrors errors
        @model.setActiveCorrector corrector
        @model.setState ExampleModelState.ERROR_CHOICE
        break

  checkForExtensions: ->
    event = @model.getEvents()[0]
    for extender in @extenders
      extension = extender.extender.getExtension event
      if extension?
        @model.setFocusedEvent event
        @model.setProposedExtension extension
        @model.setState ExampleModelState.EXTENSION
        return true
    false

  getSuggestions: ->
    error = @model.getErrorChoice()
    activeCorrector = @model.getActiveCorrector()
    suggestions = []
    for suggester in activeCorrector.suggesters
      suggesterSuggestions = suggester.getSuggestions error, @model
      suggestions = suggestions.concat suggesterSuggestions
    suggestions

  onPropertyChanged: (object, propertyName, oldValue, newValue) ->

    if @model.getState() is ExampleModelState.IDLE

      if (propertyName is ExampleModelProperty.STATE) or
          (propertyName is ExampleModelProperty.ACTIVE_RANGES)

        # First, see if any events have been detected.  If they have,
        # look if there are any extensions related to those events.  We'll
        # transition into EXTENSION state if an extension was found.
        handlingEvent = false
        if @model.getEvents().length > 0
          handlingEvent = @checkForExtensions()

        # Only check for errors if no extensions should be suggested
        if not handlingEvent
          @checkForCorrections()

    else if @model.getState() is ExampleModelState.ERROR_CHOICE

      if (propertyName is ExampleModelProperty.ERROR_CHOICE) and newValue?
        suggestions = @getSuggestions()
        @model.setSuggestions suggestions
        @model.setState ExampleModelState.RESOLUTION

    else if @model.getState() is ExampleModelState.RESOLUTION

      if (propertyName is ExampleModelProperty.RESOLUTION_CHOICE) and newValue?
        @fixer.apply @model, newValue
        @model.setActiveCorrector null
        @model.setState ExampleModelState.IDLE

    else if @model.getState() is ExampleModelState.EXTENSION

      # We need to check to see if extension decision is null before executing
      # this, as extension decision is set to 'null' in this handler, and
      # we'll cause an infinite loop if we keep watching it get set to null.
      if (propertyName is ExampleModelProperty.EXTENSION_DECISION) and newValue?

        extensionDecision = newValue
        if extensionDecision
          @fixer.apply @model, @model.getProposedExtension()

        # Regardless of the decision to extend or not, remove the event from the
        # list of events, and add it to the list of previously viewed events
        event = @model.getFocusedEvent()
        @model.getViewedEvents().push event
        eventIndex = @model.getEvents().indexOf event
        @model.getEvents().splice eventIndex, 1

        # Reset state and model variables
        @model.setFocusedEvent null
        @model.setProposedExtension null
        @model.setExtensionDecision null
        @model.setState ExampleModelState.IDLE
