{ PrimitiveValueSuggestion } = require "./suggestion"

module.exports.PrimitiveValueSuggester = class PrimitiveValueSuggester

  getSuggestions: (error, model) ->

    variableValuesMap = model.getValueMap()
    symbol = error.getSymbol()

    # Search through teh variable value map for the value of this symbol
    # on a particular line of code.  Return if any stage of lookup fails.
    fileValues = variableValuesMap[symbol.getFile().getName()]
    return [] if not fileValues?
    lineValues = fileValues[symbol.getRange().start.row]
    return [] if not lineValues?
    variableValues = lineValues[symbol.getName()]
    return [] if not variableValues?

    # Create a suggestion for each value found
    suggestions = []
    for value in variableValues
      suggestion = new PrimitiveValueSuggestion symbol, value
      suggestions.push suggestion

    suggestions
