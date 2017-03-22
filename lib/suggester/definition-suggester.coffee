{ ScopeFinder } = require '../analysis/scope'


module.exports.SymbolSuggestion = class SymbolSuggestion

  constructor: (symbol) ->
    @symbol = symbol

  getSymbol: ->
    @symbol


module.exports.DefinitionSuggester = class DefinitionSuggester

  getSuggestions: (error, model) ->

    use = error.getSymbol()

    parseTree = model.getParseTree()
    rangeSet = model.getRangeSet()
    symbolSet = model.getSymbols()

    scopeFinder = new ScopeFinder use.getFile(), parseTree
    useScopes = scopeFinder.findSymbolScopes use

    # Make a copy of the defs, as sort mutates the array, and we don't want to
    # observe each of the sorting events elsewhere
    defs = symbolSet.getVariableDefs().copy()

    # Consider only the definitions for the symbol that occured
    # in one a scope available to the use.
    defs = defs.filter (def) =>

      # If these don't have the same symbol name, skip it!
      return false if not (def.getName() is use.getName())

      # Look for a def in each of the use's scopes
      defScope = (scopeFinder.findSymbolScopes def)[0]
      return false if not defScope?
      for useScope in useScopes
        if useScope.equals defScope
          return true

      false

    # We sort definitions such that:
    # 1. All definitions above the use appear before those below the use
    # 2. All definitions closer to the use appear before those farther
    defs.sort (def1, def2) =>

      def1BeforeUse = ((def1.getRange().compare use.getRange()) is -1)
      def2BeforeUse = ((def2.getRange().compare use.getRange()) is -1)

      # If the defs are on opposite sides of the use, sort the one
      # above the use to a lower index
      if def1BeforeUse and not def2BeforeUse
        return -1
      else if def2BeforeUse and not def1BeforeUse
        return 1

      # Otherwise, return the one closest to the use
      if def1BeforeUse and def2BeforeUse
        return def2.getRange().compare def1.getRange()
      else if not (def1BeforeUse or def2BeforeUse)
        return def1.getRange().compare def2.getRange()

    # Package the sorted defs as a list of suggestions
    ((new SymbolSuggestion def) for def in defs)
