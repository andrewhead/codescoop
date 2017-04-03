{ getDeclarationScope } = require "../error/missing-declaration"
{ isSymbolDeclaredInParameters } = require "../error/missing-declaration"


module.exports.MissingDefinitionError = class MissingDefinitionError

  constructor: (symbol) ->
    @symbol = symbol

  getSymbol: ->
    @symbol


module.exports.MissingDefinitionDetector = class MissingDefinitionDetector

  detectErrors: (model) ->

    rangeSet = model.getRangeSet()
    methodRanges = rangeSet.getMethodRanges()
    symbolSet = model.getSymbols()
    activeUses = rangeSet.getActiveSymbols symbolSet.getVariableUses()
    activeDefs = rangeSet.getActiveSymbols symbolSet.getVariableDefs()
    missingDefinitionErrors = []

    # For each use in the active set, check to see if it was defined before
    # it was used.  If not, mark it as undefined
    for use in activeUses

      # We don't need to define any temporary symbols
      continue if use.getName().startsWith "$"
      # And `this` appears to be an erroneous name Soot gives to some ranges
      # of expressions that aren't variables.
      continue if use.getName() is "this"

      # Get the scope that the used symbol is declared in
      useDeclarationScope = getDeclarationScope use, model.getParseTree()

      useDefined = false
      for def in activeDefs

        # Get the scope that the def'd symbol is declared in
        defDeclarationScope = getDeclarationScope def, model.getParseTree()

        # If this is a definition for the use, check if the def comes before it.
        # If so, we'll consider the use as defined.
        if def.getName() is use.getName()
          if defDeclarationScope.equals useDeclarationScope
            if (def.getRange().compare use.getRange()) is -1
              useDefined = true
              break

      # One more option for symbols used in methods: they could be defined
      # in parameters to the method.
      for methodRange in methodRanges
        if methodRange.getRange().containsRange use.getRange()
          if isSymbolDeclaredInParameters use, model.getParseTree()
            useDefined = true

      if not useDefined
        missingDefinitionErrors.push new MissingDefinitionError use

    missingDefinitionErrors
