{ ExampleModelState } = require './example-view'

module.exports.ExampleController = class ExampleController

  constructor: (model, defUseAnalysis) ->
    @model = model
    @defUseAnalysis = defUseAnalysis
    @defUseAnalysis.run ((analysis) =>
        @model.setState ExampleModelState.PICK_UNDEFINED
        activeLineNumbers = @model.getLineSet().getActiveLineNumbers()
        undefinedUses = analysis.getUndefinedUses activeLineNumbers
        @model.getSymbols().setUndefinedUses undefinedUses
        ),
      console.error
