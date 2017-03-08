{ ExampleModelState, ExampleModelProperty } = require './model/example-model'
{ RangeAddition } = require './edit/range-addition'


module.exports.ExampleController = class ExampleController

  constructor: (model, correctors, defUseAnalysis, valueAnalysis) ->

    # Listen to all changes in the model
    @model = model
    @model.addObserver @

    @correctors = correctors

    # Before the state can update, the analyses must complete
    @_startAnalyses defUseAnalysis, valueAnalysis

  _startAnalyses: (defUseAnalysis, valueAnalysis) ->

    # Save a reference to analyses
    @analyses =
      defUse:
        runner: defUseAnalysis
        callback: (analysis) =>
          @model.getSymbols().setDefs analysis.getDefs()
          @model.getSymbols().setUses analysis.getUses()
        error: console.error
      value:
        runner: valueAnalysis or= null
        callback: (valueMap) =>
          @model.setValueMap valueMap
        error: console.error

    # Kick off each of the analyses, changing state when all are done
    controller = @
    for name, analysis of @analyses
      continue if not analysis.runner
      analysis.runner.run (((result) ->
          @finished = true
          @callback result
          if controller._areAnalysesDone()
            controller.model.setState ExampleModelState.IDLE
        ).bind analysis), analysis.error

  _areAnalysesDone: ->
    for analysis in @analyses
      if analysis.runner? and (not analysis.finished)
        return false
    true

  applyCorrectors: ->
    for corrector in @correctors
      errors = corrector.checker.detectErrors \
        @model.getParseTree(), @model.getRangeSet(), @model.getSymbols()
      if errors.length > 0
        @model.setState ExampleModelState.ERROR_CHOICE
        @model.setErrors errors
        break

  onPropertyChanged: (object, propertyName, propertyValue) ->

    if @model.getState() is ExampleModelState.IDLE

      if propertyName is ExampleModelProperty.STATE
        @applyCorrectors()
      else if propertyName is ExampleModelProperty.ACTIVE_RANGES
        @applyCorrectors()

    else if @model.getState() is ExampleModelState.ERROR_CHOICE

      if (propertyName is ExampleModelProperty.ERROR_CHOICE) and propertyValue?
        @model.setState ExampleModelState.RESOLUTION

    else if @model.getState() is ExampleModelState.RESOLUTION

      if (propertyName is ExampleModelProperty.RESOLUTION_CHOICE) and propertyValue?

        if propertyValue instanceof RangeAddition
          @model.getRangeSet().getActiveRanges().push propertyValue.getRange()

        @model.setState ExampleModelState.IDLE

    ###
    if @model.getState() is ExampleModelState.PICK_UNDEFINED
      if propertyName is ExampleModelProperty.TARGET
        use = propertyValue
        # @model.setState ExampleModelState.DEFINE
        def = @defUseAnalysis.getDefBeforeUse use
        @model.getSymbols().setDefinition def

    else if @model.getState() is ExampleModelState.DEFINE
      if propertyName is ExampleModelProperty.ACTIVE_RANGES
        # @model.setState ExampleModelState.PICK_UNDEFINED
        activeRanges = propertyValue
        undefinedUses = @defUseAnalysis.getUndefinedUses activeRanges
        @model.getSymbols().setUndefinedUses undefinedUses
    ###
