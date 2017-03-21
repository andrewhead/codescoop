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


module.exports.PrimitiveValueSuggester = class PrimitiveValueSuggester

  getSuggestions: (error, model) ->

    variableValuesMap = model.getValueMap()
    symbol = error.getSymbol()

    # Search through the variable value map for the value of this symbol
    # on a particular line of code.  Return if any stage of lookup fails.
    fileValues = variableValuesMap[symbol.getFile().getName()]
    return [] if not fileValues?
    lineValues = fileValues[symbol.getRange().start.row]
    return [] if not lineValues?
    variableValues = lineValues[symbol.getName()]
    return [] if not variableValues?

    # Create a suggestion for each distinct value found
    suggestions = []
    suggestedValues = []
    for value in variableValues
      if value not in suggestedValues
        suggestion = new PrimitiveValueSuggestion symbol, value
        suggestions.push suggestion
        suggestedValues.push value

    suggestions
