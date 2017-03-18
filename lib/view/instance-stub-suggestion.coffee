{ SuggestionView } = require './suggestion-view'
{ SuggestionBlockView } = require './suggestion-block-view'
{ Replacement } = require '../edit/replacement'


module.exports.InstanceStubSuggestionView = \
    class InstanceStubSuggestionView extends SuggestionView

  constructor: (suggestion, model, errorMarker) ->
    super suggestion, model, "Preview stub"
    @symbol = suggestion.getSymbol()
    @stubSpec = suggestion.getStubSpec()

  preview: ->
    @previewReplacement = new Replacement @symbol, "new #{@stubSpec.getClassName()}()"
    @model.getEdits().splice (@model.getEdits().indexOf @revertReplacement), 1
    @model.getEdits().push @previewReplacement
    @model.setStubOption @stubSpec

  revert: ->
    @revertReplacement = new Replacement @symbol, @symbol.getName()
    @model.getEdits().splice (@model.getEdits().indexOf @previewReplacement), 1
    @model.getEdits().push @revertReplacement
    @model.setStubOption null


module.exports.InstanceStubSuggestionBlockView = \
    class InstanceStubSuggestionBlockView extends SuggestionBlockView

  constructor: (suggestions, model, errorMarker) ->
    super "Stub out", suggestions, model, errorMarker

  createSuggestionView: (suggestion) ->
    new InstanceStubSuggestionView suggestion, @model, @errorMarker
