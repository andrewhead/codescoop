{ ImportSuggester } = require "../../lib/suggester/import-suggester"
{ MissingTypeDefinitionError } = require "../../lib/error/missing-type-definition"
{ File, Symbol } = require "../../lib/model/symbol-set"
{ Range } = require "../../lib/model/range-set"
{ Import, ImportTable } = require "../../lib/model/import"
{ ExampleModel } = require "../../lib/model/example-model"


describe "ImportSuggester", ->

  importSuggester = new ImportSuggester()

  testFile = new File "path", "filename"
  model = new ExampleModel()
  importTable = new ImportTable()
  importTable.addImport "Book", new Import "org.Book", new Range [0, 7], [0, 15]
  model.setImportTable importTable

  it "suggests imports corresponding for the type from the error", ->
    symbol = new Symbol testFile, "Book", new Range [2, 4], [2, 8], "Class"
    error = new MissingTypeDefinitionError symbol
    suggestions = importSuggester.getSuggestions error, model
    (expect suggestions.length).toBe 1
    suggestion = suggestions[0]
    (expect suggestion.getImport().getName()).toEqual "org.Book"
    (expect suggestion.getImport().getRange()).toEqual new Range [0, 7], [0, 15]

  it "returns no suggestions if there are no relevant imports", ->
    symbol = new Symbol testFile, "NotBook", new Range [2, 4], [2, 14], "Class"
    error = new MissingTypeDefinitionError symbol
    suggestions = importSuggester.getSuggestions error, model
    (expect suggestions.length).toBe 0
