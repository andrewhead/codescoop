{ SuggestionView } = require './suggestion-view'
{ SuggestionBlockView } = require './suggestion-block-view'


module.exports.DefinitionSuggestionView = class DefinitionSuggestionView extends SuggestionView

  constructor: (suggestion, model) ->
    super suggestion, model,
      # Recall that line numbers in our models are one less than
      # the line numbers as they're displayed in the editor
      "Line " + (suggestion.getSymbol().getRange().start.row + 1)

  preview: ->
    @rangeSet.addSuggestedRange @suggestion.getSymbol().getRange()

  revert: ->
    @rangeSet.removeSuggestedRange @suggestion.getSymbol().getRange()


module.exports.DefinitionSuggestionBlockView = \
    class DefinitionSuggestionBlockView extends SuggestionBlockView

  constructor: (suggestions, model, errorMarker) ->
    super "Add code", suggestions, model, errorMarker

  createSuggestionView: (suggestion, model, errorMarker) ->
    new DefinitionSuggestionView suggestion, model
