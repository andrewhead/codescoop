module.exports.MissingTypeDefinitionError = class MissingTypeDefinitionError

  constructor: (symbol) ->
    @symbol = symbol

  getSymbol: ->
    @symbol


module.exports.MissingTypeDefinitionDetector = class MissingTypeDefinitionDetector

  detectErrors: (model) ->

    importTable = model.getImportTable()
    activeImports = model.getImports()
    activeRanges = model.getRangeSet().getActiveRanges()
    classRanges = model.getRangeSet().getClassRanges()
    typeUses = model.getSymbols().getTypeUses()
    typeDefs = model.getSymbols().getTypeDefs()

    _getActiveSymbols = (symbolList) =>
      symbolList.filter (symbol) =>
        for activeRange in activeRanges
          return true if activeRange.containsRange symbol.getRange()
        return false

    usesInActiveRanges = _getActiveSymbols typeUses
    defsInActiveRanges = _getActiveSymbols typeDefs

    errors = []
    for use in usesInActiveRanges

      relatedDefsInActiveRanges = defsInActiveRanges.filter (def) =>
        (def.getFile() is use.getFile()) and (def.getName() is use.getName())

      relatedDefsInClassRanges = classRanges.filter (classRange) =>
        classSymbol = classRange.getSymbol()
        (classSymbol.getFile() is use.getFile()) and (classSymbol.getName() is use.getName())

      relatedImports = importTable.getImports use.getName()
      relatedActiveImports = []
      for relatedImport in relatedImports
        for activeImport in activeImports
          if relatedImport.equals activeImport
            relatedActiveImports.push relatedImport

      # Create an error if no appropriate def was found in the active ranges,
      # the class ranges, or the imports.
      relatedDefs = relatedDefsInActiveRanges.concat \
        relatedDefsInClassRanges, relatedActiveImports
      if relatedDefs.length is 0
        error = new MissingTypeDefinitionError use
        errors.push error

    errors
