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
    @model.getEdits().splice (@model.getEdits().indexOf @revertReplacement), 1
    @model.getEdits().push @previewReplacement

  revert: ->
    @revertReplacement = new Replacement @symbol, @symbol.getName()
    @model.getEdits().splice (@model.getEdits().indexOf @previewReplacement), 1
    @model.getEdits().push @revertReplacement


module.exports.PrimitiveValueSuggestionBlockView = \
    class SymbolSuggestionBlockView extends SuggestionBlockView

  constructor: (suggestions, model, errorMarker) ->
    super "Set value", suggestions, model, errorMarker

  createSuggestionView: (suggestion) ->
    new PrimitiveValueSuggestionView suggestion, @model, @errorMarker
