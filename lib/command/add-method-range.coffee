module.exports.AddMethodRange = class AddMethodRange

  constructor: (methodRange) ->
    @methodRange = methodRange

  apply: (model) ->
    model.getRangeSet().getMethodRanges().push @methodRange

  revert: (model) ->
    model.getRangeSet().getMethodRanges().remove @methodRange

  getMethodRange: ->
    @methodRange
