module.exports.AddRange = class AddRange

  constructor: (range) ->
    @range = range

  apply: (model) ->
    model.getRangeSet().getSnippetRanges().push @range

  revert: (model) ->
    model.getRangeSet().getSnippetRanges().remove @range

  getRange: ->
    @range
