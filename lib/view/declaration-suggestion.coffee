{ SuggestionView } = require './suggestion-view'
{ SuggestionBlockView } = require './suggestion-block-view'


module.exports.DeclarationSuggestionView = \
    class DeclarationSuggestionView extends SuggestionView

  constructor: (suggestion, model) ->
    super suggestion, model, suggestion.getName()

  preview: ->
    # @rangeSet.addSuggestedRange @suggestion.getSymbol().getRange()

  revert: ->
    # @rangeSet.removeSuggestedRange @suggestion.getSymbol().getRange()


module.exports.DeclarationSuggestionBlockView = \
    class DeclarationSuggestionBlockView extends SuggestionBlockView

  constructor: (suggestions, model, errorMarker) ->
    super "Declare", suggestions, model, errorMarker

  createSuggestionView: (suggestion) ->
    new DeclarationSuggestionView suggestion, @model
