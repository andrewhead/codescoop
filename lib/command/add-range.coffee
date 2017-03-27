module.exports.AddRange = class AddRange

  constructor: (range) ->
    @range = range

  apply: (model) ->
    model.getRangeSet().getActiveRanges().push @range

  revert: (model) ->
    model.getRangeSet().getActiveRanges().remove @range

  getRange: ->
    @range
