{ RangeTable } = require "./range-set"


module.exports.CatchTable = class CatchTable extends RangeTable

  addCatch: (throwingRange, catchRange) ->
    if not @containsRange throwingRange
      @put throwingRange, []
    (@get throwingRange).push catchRange

  getCatchRanges: (throwingRange) ->
    (@get throwingRange) or []
