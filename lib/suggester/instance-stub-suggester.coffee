module.exports.InstanceStubSuggestion = class InstanceStubSuggestion

  constructor: (symbol, stubSpec) ->
    @symbol = symbol
    @stubSpec = stubSpec

  getSymbol: ->
    @symbol

  getStubSpec: ->
    @stubSpec


module.exports.InstanceStubSuggester = class InstanceStubSuggester

  getSuggestions: (error, model) ->

    stubSpecTable = model.getStubSpecTable()
    symbol = error.getSymbol()

    # Get a copy of the defs so we can sort the list of defs by proximity
    # to the symbol that's missing a definition.  Filter to only the defs
    # that appear before the symbol, and then pick the symbol that's the closest
    # to the symbol's use.  XXX: This might yield invalid recommendations.
    defs = model.getSymbols().getVariableDefs().copy()
    defs = defs.filter (def) =>
      (def.getFile().equals symbol.getFile()) and
      (def.getName() is symbol.getName()) and
      ((def.getRange().compare symbol.getRange()) < 1)
    defs.sort (def1, def2) =>
      def2.getRange().compare def1.getRange()

    suggestions = []
    if defs.length > 0
      # Return all stub specs for instances defined at the closest def location
      closestDef = defs[0]
      className = closestDef.getFile().getName().replace /\.java$/, ''
      stubSpecs = stubSpecTable.getStubSpecs className,
        closestDef.getName(), closestDef.getRange().start.row
      for stubSpec in stubSpecs
        suggestions.push new InstanceStubSuggestion symbol, stubSpec

    suggestions
