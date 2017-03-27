module.exports.AddRange = class AddRange

  constructor: (range) ->
    @range = range

  apply: (model) ->
    model.getRangeSet().getActiveRanges().push @range

  getRange: ->
    @range
