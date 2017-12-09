module.exports.MissingDefinitionError = class MissingDefinitionError

  constructor: (symbol) ->
    @symbol = symbol

  getSymbol: ->
    @symbol


module.exports.MissingDefinitionDetector = class MissingDefinitionDetector

  detectErrors: (model) ->

    rangeSet = model.getRangeSet()
    symbolTable = model.getSymbolTable()
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
      # And if something is "args", then it will be defined for the main
      continue if use.getName() is "args"

      useDefined = false
      for def in activeDefs

        # If this is a definition for the use, check if the def comes before it.
        # If so, we'll consider the use as defined.
        if def.getName() is use.getName()
          if symbolTable.areTheSameVariable use, def
            if (def.getRange().compare use.getRange()) is -1
              useDefined = true
              break

        # XXX: There use to be a check here to see if the parameter was defined
        # in the method.  This functionality wasn't necessary for typical use
        # cases, so it was taken out.

      if not useDefined
        missingDefinitionErrors.push new MissingDefinitionError use

    missingDefinitionErrors
