{ InstanceStubSuggester } = require "../../lib/suggester/instance-stub-suggester"
{ InstanceStubSuggestion } = require "../../lib/suggester/suggestion"
{ ExampleModel } = require "../../lib/model/example-model"
{ File, Symbol } = require "../../lib/model/symbol-set"
{ Range } = require "../../lib/model/range-set"
{ StubSpec, StubSpecTable } = require "../../lib/model/stub-spec"
{ MissingDefinitionError } = require "../../lib/error/missing-definition"


describe "InstanceStubSuggester", ->

  testFile = new File "path", "Example.java"
  use = new Symbol testFile, "book", new Range [10, 16], [10, 20], "Book"
  recentDef = new Symbol testFile, "book", new Range [9, 11], [9, 15], "Book"
  oldDef = new Symbol testFile, "book", new Range [4, 11], [4, 15], "Book"
  model = new ExampleModel()
  model.getSymbols().setUses [use]
  model.getSymbols().setDefs [oldDef, recentDef]

  # Our example stub specs just has specs for two Book objects, each of which
  # returns a different title when called
  _makeBookSpec = (lineNumber, title) =>
    new StubSpec "Book",
      fieldAccesses:
        title:
          type: "String"
          values: [title]
  stubSpecTable = new StubSpecTable()
  line4Spec = _makeBookSpec 4, "Moby Dick"
  line9Spec1 = _makeBookSpec 9, "Little Women"
  line9Spec2 = _makeBookSpec 9, "Oliver Twist"
  stubSpecTable.putStubSpec "Example", "book", 4, line4Spec
  stubSpecTable.putStubSpec "Example", "book", 9, line9Spec1
  stubSpecTable.putStubSpec "Example", "book", 9, line9Spec2
  model.setStubSpecTable stubSpecTable

  it "suggests all stubs for the nearest def above the symbol use", ->
    suggester = new InstanceStubSuggester()
    error = new MissingDefinitionError use
    suggestions = suggester.getSuggestions error, model
    (expect suggestions.length).toBe 2
    suggestion = suggestions[0]
    (expect suggestion instanceof InstanceStubSuggestion).toBe true
    for suggestion in suggestions
      (expect suggestion.getStubSpec() in [line9Spec1, line9Spec2]).toBe true
