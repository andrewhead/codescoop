{ ExampleModelState, ExampleModelProperty } = require "./model/example-model"
{ CommandCreator } = require "./command/command-creator"
{ CommandStack } = require "./command/command-stack"

{ MissingDefinitionDetector } = require "./error/missing-definition"
{ MissingDeclarationDetector } = require "./error/missing-declaration"
{ MissingTypeDefinitionDetector } = require "./error/missing-type-definition"
{ MissingMethodDefinitionDetector } = require "./error/missing-method-definition"
{ ControlCrossingDetector } = require "./event/control-crossing"
{ MediatingUseDetector } = require "./event/mediating-use"
{ MethodThrowsDetector } = require "./event/method-throws"

{ DefinitionSuggester } = require "./suggester/definition-suggester"
{ DeclarationSuggester } = require "./suggester/declaration-suggester"
{ PrimitiveValueSuggester } = require "./suggester/primitive-value-suggester"
{ InstanceStubSuggester } = require "./suggester/instance-stub-suggester"
{ ImportSuggester } = require "./suggester/import-suggester"
{ LocalMethodSuggester } = require "./suggester/local-method-suggester"
{ InnerClassSuggester } = require "./suggester/inner-class-suggester"
{ ExtensionDecision } = require "./extender/extension-decision"
{ ControlStructureExtender } = require "./extender/control-structure-extender"
{ MediatingUseExtender } = require "./extender/mediating-use-extender"
{ MethodThrowsExtender } = require "./extender/method-throws-extender"


module.exports.ExampleController = class ExampleController

  constructor: (model, extras = {}) ->

    # Listen to all changes in the model
    @model = model
    @model.addObserver @

    @commandCreator = extras.commandCreator or new CommandCreator()
    @commandStack = extras.commandStack or new CommandStack()

    analyses = extras.analyses or {}
    importAnalysis = analyses.importAnalysis
    variableDefUseAnalysis = analyses.variableDefUseAnalysis
    methodDefUseAnalysis = analyses.methodDefUseAnalysis
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
        checker: new MissingMethodDefinitionDetector()
        suggesters: [ new LocalMethodSuggester() ]
      ,
        checker: new MissingTypeDefinitionDetector()
        suggesters: [
          new ImportSuggester()
          new InnerClassSuggester()
        ]
      ,
        checker: new MissingDeclarationDetector()
        suggesters: [ new DeclarationSuggester() ]
    ]
    @extenders = extras.extenders or [
        listener: new ControlCrossingDetector model
        extender: new ControlStructureExtender()
      ,
        listener: new MediatingUseDetector model
        extender: new MediatingUseExtender()
      ,
        listender: new MethodThrowsDetector model
        extender: new MethodThrowsExtender()
    ]

    # Before the state can update, the analyses must complete
    @_startAnalyses importAnalysis, variableDefUseAnalysis, methodDefUseAnalysis,
      typeDefUseAnalysis, valueAnalysis, stubAnalysis

  _startAnalyses: (importAnalysis, variableDefUseAnalysis, methodDefUseAnalysis,
    typeDefUseAnalysis, valueAnalysis, stubAnalysis) ->

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
      methodDefUse:
        runner: methodDefUseAnalysis
        callback: (result) =>
          @model.getSymbols().getMethodDefs().reset result.methodDefs
          @model.getSymbols().getMethodUses().reset result.methodUses
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
      unfixedErrors = []

      # Automatically fix all the errors we can
      for error in errors
        suggestions = []
        for suggester in corrector.suggesters
          suggesterSuggestions = suggester.getSuggestions error, @model
          suggestions = suggestions.concat suggesterSuggestions
        if suggestions.length is 1
          commandGroup = @commandCreator.createCommandGroupForSuggestion suggestions[0]
          commandGroup.quickAdd = true
          @commandStack.push commandGroup
          for command in commandGroup
            command.apply @model
          @model.setState ExampleModelState.IDLE
          return
        else
          unfixedErrors.push error

      if unfixedErrors.length >= 1
        # It's important that the state gets set last, as it's the
        # state change that the view will be refreshing on
        @model.setErrors unfixedErrors
        @model.setActiveCorrector corrector
        @model.setState ExampleModelState.ERROR_CHOICE
        break

  checkForExtensions: ->

    event = @model.getEvents()[0]

    # Try to apply each extender to the event, returning once a viable
    # extension is found for the event.
    for extender in @extenders
      extension = extender.extender.getExtension event
      if extension?
        @model.setFocusedEvent event
        @model.setProposedExtension extension
        @model.setState ExampleModelState.EXTENSION
        return true

    # If we get to the end, there was no extension for this event.
    # The event is no longer of any use to us.  We move it to the set of
    # viewed events, to prevent it from being created later.
    @model.getEvents().remove event
    @model.getViewedEvents().push event
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

    # If the user picked a new range to add, then add it!
    if propertyName is ExampleModelProperty.CHOSEN_RANGES

      # Make a command for adding a range for each of the chosen ranges.
      if newValue.length > 0
        for newRange in newValue
          commandGroup = @commandCreator.createCommandGroupForChosenRange newRange
          @commandStack.push commandGroup
          for command in commandGroup
            command.apply @model

        # Clear out the list of chosen ranges
        newValue.reset()

    # If the active ranges have changed, stop what is currently happening,
    # and send the controller back to IDLE to check for errors and resolutions
    else if propertyName is ExampleModelProperty.ACTIVE_RANGES
      @_resetChoiceState()
      @model.setState ExampleModelState.IDLE

    # Otherwise, take actions based on the current state
    else if @model.getState() is ExampleModelState.IDLE

      if propertyName is ExampleModelProperty.STATE

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

        # Look up commands for this suggestion, execute and save them
        commandGroup = @commandCreator.createCommandGroupForSuggestion newValue
        @commandStack.push commandGroup
        for command in commandGroup
          command.apply @model

        @model.setActiveCorrector null
        @model.setState ExampleModelState.IDLE

    else if @model.getState() is ExampleModelState.EXTENSION

      # We need to check to see if extension decision is null before executing
      # this, as extension decision is set to 'null' in this handler, and
      # we'll cause an infinite loop if we keep watching it get set to null.
      if (propertyName is ExampleModelProperty.EXTENSION_DECISION) and newValue?

        extensionDecision = new ExtensionDecision \
          @model.getFocusedEvent(), @model.getProposedExtension(), newValue

        # Look up commands for this decision for this extension.
        # Then execute and save them to the stack.
        commandGroup = @commandCreator.createCommandGroupForExtensionDecision extensionDecision
        @commandStack.push commandGroup
        for command in commandGroup
          command.apply @model

        # Reset state and model variables
        @model.setFocusedEvent null
        @model.setProposedExtension null
        @model.setExtensionDecision null
        @model.setState ExampleModelState.IDLE

  undo: ->

    # Revert the last command and remove it from the stack
    quickAdd = true
    while quickAdd?
      lastCommandGroup = @commandStack.pop()
      for command in lastCommandGroup
        command.revert @model
      quickAdd = lastCommandGroup.quickAdd

    @_resetChoiceState()

    # Reset the example editor to IDLE
    @model.setState ExampleModelState.IDLE

  _resetChoiceState: ->

    # Reset state associated with... ERROR_CHOICE state...
    @model.getErrors().reset []
    @model.setActiveCorrector null
    @model.setErrorChoice null

    # RESOLUTION state...
    @model.getSuggestions().reset []
    @model.setResolutionChoice null

    # And EXTENSION state...
    @model.setFocusedEvent null
    @model.setProposedExtension null
    @model.setExtensionDecision null
