module.exports.AddPrintedSymbol = class AddPrintedSymbol

  constructor: (symbolName) ->
    @symbolName = symbolName

  apply: (model) ->
    model.getPrintedSymbols().push @symbolName

  revert: (model) ->
    model.getPrintedSymbols().remove @symbolName
