{ SuggestionView } = require './suggestion-view'
{ SuggestionBlockView } = require './suggestion-block-view'
{ Replacement } = require '../edit/replacement'


module.exports.PrimitiveValueSuggestionView = \
    class PrimitiveValueSuggestionView extends SuggestionView

  constructor: (suggestion, model, errorMarker) ->
    super suggestion, model, suggestion.getValueString()
    @symbol = suggestion.getSymbol()
    @valueString = suggestion.getValueString()

  preview: ->
    @previewReplacement = new Replacement @symbol, @valueString
    @model.getEdits().push @previewReplacement

  revert: ->
    @model.getEdits().remove @previewReplacement


module.exports.PrimitiveValueSuggestionBlockView = \
    class PrimitiveValueSuggestionBlockView extends SuggestionBlockView

  constructor: (suggestions, model, errorMarker) ->
    super "Set value", suggestions, model, errorMarker

  createSuggestionView: (suggestion, model, errorMarker) ->
    new PrimitiveValueSuggestionView suggestion, model, errorMarker
