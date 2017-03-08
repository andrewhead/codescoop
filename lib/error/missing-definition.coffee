module.exports.MissingDefinitionError = class MissingDefinitionError

  constructor: (symbol) ->
    @symbol = symbol

  getSymbol: ->
    @symbol


module.exports.MissingDefinitionDetector = class MissingDefinitionDetector

  detectErrors: (parseTree, rangeSet, symbolSet) ->

    activeUses = rangeSet.getActiveSymbols symbolSet.getUses()
    activeDefs = rangeSet.getActiveSymbols symbolSet.getDefs()
    missingDefinitionErrors = []

    # For each use in the active set, check to see if it was defined before
    # it was used.  If not, mark it as undefined
    for use in activeUses

      useDefined = false
      for def in activeDefs

        # If this is a definition for the use, check if the def comes before it.
        # If so, we'll consider the use as defined.
        if def.getName() is use.getName()
          if (def.getRange().compare use.getRange()) is -1
            useDefined = true
            break

      if not useDefined
        missingDefinitionErrors.push new MissingDefinitionError use

    missingDefinitionErrors
