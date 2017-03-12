{ ExampleModelState, ExampleModelProperty } = require "./model/example-model"
{ MissingDefinitionDetector } = require "./error/missing-definition"
{ MissingDeclarationDetector } = require "./error/missing-declaration"
{ MissingControlLogicDetector } = require "./concern/missing-control-logic"
{ DefinitionSuggester } = require "./suggester/definition-suggester"
{ DeclarationSuggester } = require "./suggester/declaration-suggester"
{ AddControlLogicSuggester } = require "./suggester/control-logic-suggester"
{ PrimitiveValueSuggester } = require "./suggester/primitive-value-suggester"
{ RangeAddition } = require "./edit/range-addition"
{ Fixer } = require "./fixer"

module.exports.ExampleController = class ExampleController

  constructor: (model, analyses, correctors) ->

    # Listen to all changes in the model
    @model = model
    @model.addObserver @

    defUseAnalysis = analyses.defUseAnalysis
    valueAnalysis = analyses.valueAnalysis

    @correctors = correctors
    # Load default correctors if none were passed in
    if not @correctors?
      @correctors = [
          checker: new MissingDeclarationDetector()
          suggesters: [ new DeclarationSuggester() ]
        ,
          checker: new MissingDefinitionDetector()
          suggesters: [
            new DefinitionSuggester()
            new PrimitiveValueSuggester()
          ]
        ,
          checker: new MissingControlLogicDetector()
          suggesters: [
            new AddControlLogicSuggester()
          ]
      ]

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
      errors = corrector.checker.detectErrors @model
      if errors.length > 0
        # It's important that the state gets set last, as it's the
        # state change that the view will be refreshing on
        @model.setErrors errors
        @model.setActiveCorrector corrector
        @model.setState ExampleModelState.ERROR_CHOICE
        break

  getSuggestions: ->
    error = @model.getErrorChoice()
    activeCorrector = @model.getActiveCorrector()
    suggestions = []
    for suggester in activeCorrector.suggesters
      suggesterSuggestions = suggester.getSuggestions error, @model
      suggestions = suggestions.concat suggesterSuggestions
    console.log suggestions
    suggestions

  onPropertyChanged: (object, propertyName, propertyValue) ->

    if @model.getState() is ExampleModelState.IDLE

      if propertyName is ExampleModelProperty.STATE
        @applyCorrectors()
      else if propertyName is ExampleModelProperty.ACTIVE_RANGES
        @applyCorrectors()

    else if @model.getState() is ExampleModelState.ERROR_CHOICE

      if (propertyName is ExampleModelProperty.ERROR_CHOICE) and propertyValue?
        suggestions = @getSuggestions()
        @model.setSuggestions suggestions
        @model.setState ExampleModelState.RESOLUTION

    else if @model.getState() is ExampleModelState.RESOLUTION

      if (propertyName is ExampleModelProperty.RESOLUTION_CHOICE) and propertyValue?

        if propertyValue instanceof RangeAddition
          @model.getRangeSet().getActiveRanges().push propertyValue.getRange()
        else
          fixer = new Fixer()
          fixer.apply @model, propertyValue

        @model.setActiveCorrector null
        @model.setState ExampleModelState.IDLE
