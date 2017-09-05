{ DeclarationSuggester } = require "../../lib/suggester/declaration-suggester"
{ ExampleModel } = require "../../lib/model/example-model"
{ MissingDeclarationError } = require "../../lib/error/missing-declaration"
{ File, Symbol, SymbolSet } = require "../../lib/model/symbol-set"
{ Range, RangeSet } = require "../../lib/model/range-set"


describe "DeclarationSuggester", ->

  it "suggests a declaration with the type and name of the undeclared variable", ->

    model = new ExampleModel undefined, new RangeSet(), new SymbolSet()
    suggester = new DeclarationSuggester()
    error = new MissingDeclarationError new Symbol \
      (new File "path", "file"), "i", (new Range [3, 8], [3, 9]), "int"

    suggestions = suggester.getSuggestions error, model
    (expect suggestions.length).toBe 1
    suggestion = suggestions[0]
    (expect suggestion.getName()).toEqual "i"
    (expect suggestion.getType()).toEqual "int"
    (expect suggestion.getSymbol().getRange()).toEqual new Range [3, 8], [3, 9]
