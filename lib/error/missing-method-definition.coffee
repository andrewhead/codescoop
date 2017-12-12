module.exports.MissingMethodDefinitionError = class MissingMethodDefinitionError

  constructor: (symbol) ->
    @symbol = symbol

  getSymbol: ->
    @symbol


# The current missing method detector is limited to discovering uses of
# local methods that aren't yet defined.  It detects a method as resolved
# when a local method with the same name has been discovered (currently,
# ignoring the rest of the method's signature).  It also does not look
# at the import table to find what methods might have been imported.  It also
# doesn't yet disambiguate between methods defined in the current class
# and methods defined in internal classes.
module.exports.MissingMethodDefinitionDetector = class MissingMethodDefinitionDetector

  detectErrors: (model) ->

    methodUses = model.getSymbols().getMethodUses()
    methodDefs = model.getSymbols().getMethodDefs()

    activeRanges = model.getRangeSet().getActiveRanges()
    _getActiveSymbols = (symbolList) =>
      symbolList.filter (symbol) =>
        for activeRange in activeRanges
          return true if activeRange.containsRange symbol.getRange()
        return false

    usesInActiveRanges = _getActiveSymbols methodUses
    defsInActiveRanges = _getActiveSymbols methodDefs

    errors = []
    for use in usesInActiveRanges
      relatedDefsInActiveRanges = defsInActiveRanges.filter (def) =>
        (def.getFile() is use.getFile()) and (def.getName() is use.getName())
      if (relatedDefsInActiveRanges.length is 0)
        error = new MissingMethodDefinitionError use
        errors.push error

    errors
