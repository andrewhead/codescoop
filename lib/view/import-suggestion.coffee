{ SuggestionView } = require './suggestion-view'
{ SuggestionBlockView } = require './suggestion-block-view'


module.exports.ImportSuggestionView = class ImportSuggestionView extends SuggestionView

  constructor: (suggestion, model) ->
    super suggestion, model, suggestion.getImport().getName()

  preview: ->
    @rangeSet.getSuggestedRanges().push @suggestion.getImport().getRange()

  revert: ->
    @rangeSet.getSuggestedRanges().remove @suggestion.getImport().getRange()


module.exports.ImportSuggestionBlockView = \
    class ImportSuggestionBlockView extends SuggestionBlockView

  constructor: (suggestions, model, errorMarker) ->
    super "Import", suggestions, model, errorMarker

  createSuggestionView: (suggestion, model, errorMarker) ->
    new ImportSuggestionView suggestion, model
