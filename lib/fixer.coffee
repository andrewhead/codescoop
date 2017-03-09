{ SymbolSuggestion, PrimitiveValueSuggestion } = require '../lib/suggester/suggestion'


module.exports.Fixer = class Fixer

  apply: (model, suggestion) ->

    # TODO: eventually this should add the smallest range that defines
    # the symbol, but right now it adds lines
    if suggestion instanceof SymbolSuggestion
      codeBuffer = model.getCodeBuffer()
      symbolRange = suggestion.getSymbol().getRange()
      startRowRange = codeBuffer.rangeForRow symbolRange.start.row
      endRowRange = codeBuffer.rangeForRow symbolRange.end.row
      rangeUnion = startRowRange.union endRowRange
      model.getRangeSet().getActiveRanges().push rangeUnion

    else if suggestion instanceof PrimitiveValueSuggestion
      codeBuffer = model.getCodeBuffer()
      editRange = suggestion.getSymbol().getRange()
      codeBuffer.setTextInRange editRange, suggestion.getValueString()
