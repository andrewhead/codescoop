{ SuggestionView } = require './suggestion-view'
{ SuggestionBlockView } = require './suggestion-block-view'


module.exports.ControlLogicSuggestionView = \
    class ControlLogicSuggestionView extends SuggestionView

  constructor: (suggestion, model) ->
    super suggestion, model,
      # Recall that line numbers in our models are one less than
      # the line numbers as they're displayed in the editor
      "Add control logic starting on " + (suggestion.getRanges()[0].start.row + 1)

  preview: ->
    @rangeSet.addSuggestedRange @suggestion.getRanges()

  revert: ->
    @rangeSet.removeSuggestedRange @suggestion.getRanges()

module.exports.ControlLogicSuggestionBlockView = \
    class ControlLogicSuggestionBlockView extends SuggestionBlockView

  constructor: (suggestions, model, errorMarker) ->
    super "Add control logic", suggestions, model, errorMarker

  createSuggestionView: (suggestion) ->
    new ControlLogicSuggestionView suggestion, @model
