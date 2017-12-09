module.exports.AddClassRange = class AddClassRange

  constructor: (classRange) ->
    @classRange = classRange

  apply: (model) ->
    model.getRangeSet().getClassRanges().push @classRange

  revert: (model) ->
    model.getRangeSet().getClassRanges().remove @classRange

  getClassRange: ->
    @classRange
