module.exports.DefinitionSuggestion = class DefinitionSuggestion

  constructor: (symbol) ->
    @symbol = symbol

  getSymbol: ->
    @symbol


# Defs are sorted by proximity to the use, with all defs that appear above
# the use appearing before all of those that appear below the use
module.exports.getDefsForUse = getDefsForUse = (use, model) ->

  symbolTable = model.getSymbolTable()

  # Consider only the definitions for the symbol that modify the same
  # variable that the use uses.  Check on this to make sure that the def
  # relates to the same declaration that the use relates to.
  defs = model.getSymbols().getVariableDefs().copy()
  defs = defs.filter (def) =>

    # If these don't have the same symbol name, skip it!
    return false if not (def.getName() is use.getName())

    # All defs need to come before the use
    return false if (def.getRange().compare use.getRange()) > -1

    return symbolTable.areTheSameVariable def, use

  # We sort definitions such that:
  # 1. All definitions above the use appear before those below the use
  # 2. All definitions closer to the use appear before those farther
  defs.sort (def1, def2) => def2.getRange().compare def1.getRange()
  defs


module.exports.DefinitionSuggester = class DefinitionSuggester

  getSuggestions: (error, model) ->

    use = error.getSymbol()

    parseTree = model.getParseTree()
    rangeSet = model.getRangeSet()
    symbolSet = model.getSymbols()

    # Make a copy of the defs, as sort mutates the array, and we don't want to
    # observe each of the sorting events elsewhere
    defs = getDefsForUse use, model

    # Package the sorted defs as a list of suggestions
    ((new DefinitionSuggestion def) for def in defs)
