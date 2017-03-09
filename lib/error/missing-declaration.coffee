{ ScopeFinder } = require '../analysis/scope'


module.exports.MissingDeclarationError = class MissingDeclarationError

  constructor: (symbol) ->
    @symbol = symbol

  getSymbol: ->
    @symbol


# Detects which symbols from a set of symbols are undeclared, given the
# current code example (represented as a set of active ranges).
module.exports.MissingDeclarationDetector = class MissingDeclarationDetector

  detectErrors: (model) ->

    parseTree = model.getParseTree()
    rangeSet = model.getRangeSet()
    symbolSet = model.getSymbols()

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

      # We don't need to declare any temporary symbols
      continue if symbol.getName().startsWith "$"

      # Check to see if the symbol was declared in the auxiliary declarations
      for declaration in model.getAuxiliaryDeclarations()
        if (symbol.getName() is declaration.getName()) and
           (symbol.getType() is declaration.getType())
          foundDeclaration = true
          break
      continue if foundDeclaration

      # Look for a declaration in all scopes that the symbol appears in.  Only
      # report a declaration as "found" if it is in one of the active ranges.
      for scope in symbolScopes
        for declaredSymbolText in scope.getDeclarations()
          for activeRange in rangeSet.getActiveRanges()
            if (activeRange.containsRange declaredSymbolText.getRange()) and
               (declaredSymbolText.getName() is symbol.getName())
              foundDeclaration = true

      if not foundDeclaration
        missingDeclarations.push new MissingDeclarationError symbol

    missingDeclarations
