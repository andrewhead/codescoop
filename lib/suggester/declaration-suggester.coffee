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


module.exports.DeclarationSuggester = class DeclarationSuggester

  getSuggestions: (error, model) ->
    symbol = error.getSymbol()
    suggestions = []
    suggestion = new DeclarationSuggestion symbol.getName(), symbol.getType(), symbol
    suggestions.push suggestion
    suggestions
