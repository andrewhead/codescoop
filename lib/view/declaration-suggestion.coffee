{ SuggestionView } = require './suggestion-view'
{ SuggestionBlockView } = require './suggestion-block-view'


module.exports.DeclarationSuggestionView = \
    class DeclarationSuggestionView extends SuggestionView

  constructor: (suggestion, model) ->
    super suggestion, model, suggestion.getName()

  preview: ->

  revert: ->


module.exports.DeclarationSuggestionBlockView = \
    class DeclarationSuggestionBlockView extends SuggestionBlockView

  constructor: (suggestions, model, errorMarker) ->
    super "Declare", suggestions, model, errorMarker

  createSuggestionView: (suggestion, model, errorMarker) ->
    new DeclarationSuggestionView suggestion, model
