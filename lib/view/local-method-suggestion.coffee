{ SuggestionView } = require './suggestion-view'
{ SuggestionBlockView } = require './suggestion-block-view'


module.exports.LocalMethodSuggestionView = class LocalMethodSuggestionView extends SuggestionView

  constructor: (suggestion, model) ->
    super suggestion, model, suggestion.getSymbol().getName() + "()"

  preview: ->
    @rangeSet.getSuggestedRanges().push @suggestion.getRange()

  revert: ->
    @rangeSet.getSuggestedRanges().remove @suggestion.getRange()


module.exports.LocalMethodSuggestionBlockView = \
    class LocalMethodSuggestionBlockView extends SuggestionBlockView

  constructor: (suggestions, model, errorMarker) ->
    super "Add local method", suggestions, model, errorMarker

  createSuggestionView: (suggestion, model, errorMarker) ->
    new LocalMethodSuggestionView suggestion, model
