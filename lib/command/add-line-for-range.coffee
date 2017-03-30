module.exports.AddLineForRange = class AddRange

  constructor: (range) ->
    @range = range
    @lineRange = undefined

  apply: (model) ->
    codeBuffer = model.getCodeBuffer()
    startRowRange = codeBuffer.rangeForRow @range.start.row
    endRowRange = codeBuffer.rangeForRow @range.end.row
    @lineRange = startRowRange.union endRowRange
    model.getRangeSet().getSnippetRanges().push @lineRange

  revert: (model) ->
    model.getRangeSet().getSnippetRanges().remove @lineRange

  getRange: ->
    @range
