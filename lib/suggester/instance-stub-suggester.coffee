{ InstanceStubSuggestion } = require "./suggestion"

module.exports.InstanceStubSuggester = class InstanceStubSuggester

  getSuggestions: (error, model) ->

    stubSpecTable = model.getStubSpecTable()
    symbol = error.getSymbol()

    # Get a copy of the defs so we can sort the list of defs by proximity
    # to the symbol that's missing a definition.  Filter to only the defs
    # that appear before the symbol, and then pick the symbol that's the closest
    # to the symbol's use.  XXX: This might yield invalid recommendations.
    defs = model.getSymbols().getDefs().copy()
    defs = defs.filter (def) =>
      (def.getRange().compare symbol.getRange()) < 1
    defs.sort (def1, def2) =>
      def2.getRange().compare def1.getRange()
    closestDef = defs[0]

    # Return all stub specs for instances defined at that location
    className = closestDef.getFile().getName().replace /\.java$/, ''
    stubSpecs = stubSpecTable.getStubSpecs className,
      closestDef.getName(), closestDef.getRange().start.row
    suggestions = []
    for stubSpec in stubSpecs
      suggestions.push new InstanceStubSuggestion symbol, stubSpec

    suggestions
