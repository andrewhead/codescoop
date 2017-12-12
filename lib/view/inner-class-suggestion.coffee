{ SuggestionView } = require './suggestion-view'
{ SuggestionBlockView } = require './suggestion-block-view'


module.exports.InnerClassSuggestionView = class InnerClassSuggestionView extends SuggestionView

  constructor: (suggestion, model) ->
    super suggestion, model,
      "Inner class " + suggestion.getSymbol().getName()

  preview: ->
    @rangeSet.getSuggestedRanges().push @suggestion.getRange()

  revert: ->
    @rangeSet.getSuggestedRanges().remove @suggestion.getRange()


module.exports.InnerClassSuggestionBlockView = \
    class InnerClassSuggestionBlockView extends SuggestionBlockView

  constructor: (suggestions, model, errorMarker) ->
    super "Add inner class", suggestions, model, errorMarker

  createSuggestionView: (suggestion, model, errorMarker) ->
    new InnerClassSuggestionView suggestion, model
