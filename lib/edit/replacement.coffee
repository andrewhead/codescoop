module.exports.Replacement = class Replacement

  constructor: (symbol, text) ->
    @symbol = symbol
    @text = text

  getSymbol: ->
    @symbol

  getText: ->
    @text
