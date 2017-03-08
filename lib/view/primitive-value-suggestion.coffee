{ SuggestionView } = require './suggestion-view'
{ Replacement } = require '../edit/replacement'


module.exports.PrimitiveValueSuggestionView = \
    class PrimitiveValueSuggestionView extends SuggestionView

  constructor: (suggestion, model, errorMarker) ->
    super suggestion, model, suggestion.getValueString()
    # Pre-package the replacement so we can refer to the same one for all events
    @replacement = new Replacement \
      errorMarker.getBufferRange(), suggestion.getValueString()

  onMouseOver: (event) ->
    @model.getEdits().push @replacement

  onMouseOut: (event) ->
    @model.getEdits().splice (@model.getEdits().indexOf @replacement), 1

  onClick: (event) ->
    @model.getEdits().push @replacement
