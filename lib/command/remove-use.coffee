module.exports.RemoveUse = class RemoveUse

  constructor: (usedSymbol) ->
    @symbol = usedSymbol

  apply: (model) ->
    uses = model.getSymbols().getVariableUses()
    for use, useIndex in uses
      if @symbol.equals use
        uses.splice useIndex, 1
        break

  getSymbol: ->
    @symbol
