module.exports.DeleteRange = class DeleteRange

  constructor: (range) ->
    @range = range

  apply: (model) ->
    model.getRangeSet().getSnippetRanges().remove @range

  revert: (model) ->
    model.getRangeSet().getSnippetRanges().push @range

  getRange: ->
    @range
