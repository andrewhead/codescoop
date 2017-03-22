module.exports.MissingTypeDefinitionError = class MissingTypeDefinitionError

  constructor: (symbol) ->
    @symbol = symbol

  getSymbol: ->
    @symbol


module.exports.MissingTypeDefinitionDetector = class MissingTypeDefinitionDetector

  detectErrors: (model) ->

    importTable = model.getImportTable()
    activeRanges = model.getRangeSet().getActiveRanges()
    typeUses = model.getSymbols().getTypeUses()
    typeDefs = model.getSymbols().getTypeDefs()

    _getActiveSymbols = (symbolList) =>
      symbolList.filter (symbol) =>
        for activeRange in activeRanges
          return true if activeRange.containsRange symbol.getRange()
        return false

    activeTypeUses = _getActiveSymbols typeUses
    activeTypeDefs = _getActiveSymbols typeDefs

    errors = []
    for use in activeTypeUses

      activeRelatedDefs = activeTypeDefs.filter (def) =>
        (def.getFile() is use.getFile()) and (def.getName() is use.getName())

      relatedImports = importTable.getImports use.getName()
      activeRelatedImports = []
      for import_ in relatedImports
        for activeRange in activeRanges
          if activeRange.containsRange import_.getRange()
            activeRelatedImports.push import_

      if activeRelatedDefs.length is 0 and activeRelatedImports.length is 0
        error = new MissingTypeDefinitionError use
        errors.push error

    errors
