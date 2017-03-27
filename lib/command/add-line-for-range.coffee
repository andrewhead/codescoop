module.exports.AddLineForRange = class AddRange

  constructor: (range) ->
    @range = range
    @lineRange = undefined

  apply: (model) ->
    codeBuffer = model.getCodeBuffer()
    startRowRange = codeBuffer.rangeForRow @range.start.row
    endRowRange = codeBuffer.rangeForRow @range.end.row
    @lineRange = startRowRange.union endRowRange
    model.getRangeSet().getActiveRanges().push @lineRange

  getRange: ->
    @range
