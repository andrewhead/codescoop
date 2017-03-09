module.exports.SymbolSuggestion = class SymbolSuggestion

  constructor: (symbol) ->
    @symbol = symbol

  getSymbol: ->
    @symbol


# We assume that all primitives can be represented by a short string of
# characters.  That's why the only data that this suggestion has is
# a string representation of its value.
module.exports.PrimitiveValueSuggestion = class PrimitiveValueSuggestion

  constructor: (symbol, valueString) ->
    @symbol = symbol
    @valueString = valueString

  getSymbol: ->
    @symbol

  getValueString: ->
    @valueString
