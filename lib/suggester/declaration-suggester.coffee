{ DeclarationSuggestion } = require "./suggestion"


module.exports.DeclarationSuggester = class DeclarationSuggester

  getSuggestions: (error, model) ->
    symbol = error.getSymbol()
    suggestions = []
    suggestion = new DeclarationSuggestion symbol.getName(), symbol.getType(), symbol
    suggestions.push suggestion
    suggestions
