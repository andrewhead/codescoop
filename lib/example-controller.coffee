{ ExampleModelState, ExampleModelProperty } = require './example-view'

module.exports.ExampleController = class ExampleController

  constructor: (model, defUseAnalysis, valueAnalysis) ->
    @model = model
    @model.addObserver @
    @defUseAnalysis = defUseAnalysis
    @defUseAnalysis.run ((analysis) =>
        @model.setState ExampleModelState.PICK_UNDEFINED
        activeLineNumbers = @model.getLineSet().getActiveLineNumbers()
        undefinedUses = @defUseAnalysis.getUndefinedUses activeLineNumbers
        @model.getSymbols().setUndefinedUses undefinedUses
        ),
      console.error
    @valueAnalysis = (if valueAnalysis? then valueAnalysis else null)
    if @valueAnalysis?
      @valueAnalysis.run ((valueMap) =>
          @model.setValueMap valueMap
        ), console.error

  onPropertyChanged: (object, propertyName, propertyValue) ->

    if @model.getState() is ExampleModelState.PICK_UNDEFINED
      if propertyName is ExampleModelProperty.TARGET
        use = propertyValue
        @model.setState ExampleModelState.DEFINE
        def = @defUseAnalysis.getDefBeforeUse use
        @model.getSymbols().setDefinition def

    else if @model.getState() is ExampleModelState.DEFINE
      if propertyName is ExampleModelProperty.ACTIVE_LINE_NUMBERS
        @model.setState ExampleModelState.PICK_UNDEFINED
        activeLineNumbers = propertyValue
        undefinedUses = @defUseAnalysis.getUndefinedUses activeLineNumbers
        @model.getSymbols().setUndefinedUses undefinedUses
