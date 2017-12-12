module.exports.ImportSuggestion = class ImportSuggestion

  constructor: (import_) ->
    @import = import_

  getImport: ->
    @import


module.exports.ImportSuggester = class ImportSuggester

  getSuggestions: (error, model) ->

    importTable = model.getImportTable()
    typeName = error.getSymbol().getName()

    # Get a list of imports that could define this type
    imports = importTable.getImports typeName

    # Create a suggestion for each import
    suggestions = []
    for import_ in imports
      suggestion = new ImportSuggestion import_
      suggestions.push suggestion

    suggestions
