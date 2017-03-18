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


module.exports.InstanceStubSuggestion = class InstanceStubSuggestion

  constructor: (symbol, stubSpec) ->
    @symbol = symbol
    @stubSpec = stubSpec

  getSymbol: ->
    @symbol

  getStubSpec: ->
    @stubSpec


module.exports.DeclarationSuggestion = class DeclarationSuggestion

  constructor: (name, type, symbol) ->
    @name = name
    @type = type
    @symbol = symbol

  getName: ->
    @name

  getType: ->
    @type

  getSymbol: ->
    @symbol
