{ SuggestionView } = require './suggestion-view'


module.exports.SymbolSuggestionView = class SymbolSuggestionView extends SuggestionView

  constructor: (suggestion, model) ->
    super suggestion, model,
      "L" + suggestion.getSymbol().getRange().start.row

  onMouseOver: (event) ->
    @rangeSet.addSuggestedRange @suggestion.getSymbol().getRange()

  onMouseOut: (event) ->
    @rangeSet.removeSuggestedRange @suggestion.getSymbol().getRange()

  onClick: (event) ->
    @model.setResolutionChoice @suggestion
