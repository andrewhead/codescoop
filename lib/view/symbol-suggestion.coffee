{ SuggestionView } = require './suggestion-view'
{ SuggestionBlockView } = require './suggestion-block-view'


module.exports.SymbolSuggestionView = class SymbolSuggestionView extends SuggestionView

  constructor: (suggestion, model) ->
    super suggestion, model,
      "L" + suggestion.getSymbol().getRange().start.row

  preview: ->
    @rangeSet.addSuggestedRange @suggestion.getSymbol().getRange()

  revert: ->
    @rangeSet.removeSuggestedRange @suggestion.getSymbol().getRange()

  accept: ->
    @model.setResolutionChoice @suggestion


module.exports.SymbolSuggestionBlockView = \
    class SymbolSuggestionBlockView extends SuggestionBlockView

  constructor: (suggestions, model, errorMarker) ->
    super "Add code", suggestions, model, errorMarker

  createSuggestionView: (suggestion) ->
    new SymbolSuggestionView suggestion, @model
