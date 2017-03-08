{ ScopeFinder } = require '../analysis/scope'


module.exports.MissingDeclarationError = class MissingDeclarationError

  constructor: (symbol) ->
    @symbol = symbol

  getSymbol: ->
    @symbol


# Detects which symbols from a set of symbols are undeclared, given the
# current code example (represented as a set of active ranges).
module.exports.MissingDeclarationDetector = class MissingDeclarationDetector

  detectErrors: (parseTree, rangeSet, symbolSet) ->

    # First, just look for all symbols that used in the example editor
    activeSymbols = []
    for symbol in symbolSet.getAllSymbols()
      for activeRange in rangeSet.getActiveRanges()
        if activeRange.containsRange symbol.getRange()
          activeSymbols.push symbol
        break

    # Then, we collect the active symbols that are undeclared
    missingDeclarations = []
    for symbol in activeSymbols

      scopeFinder = new ScopeFinder symbol.getFile(), parseTree
      symbolScopes = scopeFinder.findSymbolScopes symbol
      foundDeclaration = false

      # Look for a declaration in all scopes that the symbol appears in.  Only
      # report a declaration as "found" if it is in one of the active ranges.
      for scope in symbolScopes
        for declaredSymbol in scope.getDeclaredSymbols()
          for activeRange in rangeSet.getActiveRanges()
            if (activeRange.containsRange declaredSymbol.getRange()) and
               (declaredSymbol.getName() is symbol.getName())
              foundDeclaration = true

      if not foundDeclaration
        missingDeclarations.push new MissingDeclarationError symbol

    missingDeclarations
