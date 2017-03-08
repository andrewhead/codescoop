{ SuggestionView } = require './suggestion-view'
{ SuggestionBlockView } = require './suggestion-block-view'
{ Replacement } = require '../edit/replacement'


module.exports.PrimitiveValueSuggestionView = \
    class PrimitiveValueSuggestionView extends SuggestionView

  constructor: (suggestion, model, errorMarker) ->
    super suggestion, model, suggestion.getValueString()
    # Pre-package the replacement so we can refer to the same one for all events
    @replacement = new Replacement \
      errorMarker.getBufferRange(), suggestion.getValueString()

  preview: ->
    @model.getEdits().push @replacement

  revert: ->
    @model.getEdits().splice (@model.getEdits().indexOf @replacement), 1

  accept: ->
    @model.getEdits().push @replacement


module.exports.PrimitiveValueSuggestionBlockView = \
    class SymbolSuggestionBlockView extends SuggestionBlockView

  constructor: (suggestions, model, errorMarker) ->
    super "Set value", suggestions, model, errorMarker

  createSuggestionView: (suggestion) ->
    new PrimitiveValueSuggestionView suggestion, @model, @errorMarker
