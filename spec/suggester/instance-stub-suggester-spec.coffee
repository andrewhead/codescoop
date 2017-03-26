{ InstanceStubSuggester } = require "../../lib/suggester/instance-stub-suggester"
{ InstanceStubSuggestion } = require "../../lib/suggester/instance-stub-suggester"
{ ExampleModel } = require "../../lib/model/example-model"
{ File, Symbol } = require "../../lib/model/symbol-set"
{ Range } = require "../../lib/model/range-set"
{ StubSpec, StubSpecTable } = require "../../lib/model/stub"
{ MissingDefinitionError } = require "../../lib/error/missing-definition"


describe "InstanceStubSuggester", ->

  testFile = new File "path", "Example.java"
  use = new Symbol testFile, "book", (new Range [10, 16], [10, 20]), "Book"
  irrelevantDef = new Symbol testFile, "otherObject",
    (new Range [9, 11], [9, 22]), "OtherClass"
  recentDef = new Symbol testFile, "book", (new Range [8, 11], [8, 15]), "Book"
  oldDef = new Symbol testFile, "book", (new Range [4, 11], [4, 15]), "Book"
  model = new ExampleModel()
  model.getSymbols().setVariableUses [use]
  model.getSymbols().setVariableDefs [oldDef, recentDef, irrelevantDef]

  # Our example stub specs just has specs for two Book objects, each of which
  # returns a different title when called
  _makeSpec = (className, lineNumber, title) =>
    new StubSpec className,
      fieldAccesses:
        title:
          type: "String"
          values: [title]
  stubSpecTable = new StubSpecTable()
  line4Spec = _makeSpec "Book", 4, "Moby Dick"
  line8Spec1 = _makeSpec "Book", 8, "Little Women"
  line8Spec2 = _makeSpec "Book", 8, "Oliver Twist"
  line9Spec = _makeSpec "OtherClass", 9, "Red Herring"
  stubSpecTable.putStubSpec "Example", "book", 4, line4Spec
  stubSpecTable.putStubSpec "Example", "book", 8, line8Spec1
  stubSpecTable.putStubSpec "Example", "book", 8, line8Spec2
  stubSpecTable.putStubSpec "Example", "otherObject", 9, line9Spec
  model.setStubSpecTable stubSpecTable

  it "suggests all stubs for the nearest def above the symbol use", ->
    suggester = new InstanceStubSuggester()
    error = new MissingDefinitionError use
    suggestions = suggester.getSuggestions error, model
    (expect suggestions.length).toBe 2
    suggestion = suggestions[0]
    (expect suggestion instanceof InstanceStubSuggestion).toBe true
    for suggestion in suggestions
      (expect suggestion.getStubSpec() in [line8Spec1, line8Spec2]).toBe true
      (expect suggestion.getSymbol().getRange().start.row).toBe 10

  it "doesn't crash if there's not def above the symbol use", ->
    suggester = new InstanceStubSuggester()
    error = new MissingDefinitionError \
      new Symbol testFile, "undefinedInt", new Range [11, 16], [11, 28], "int"
    suggestions = suggester.getSuggestions error, model
    (expect suggestions.length).toBe 0
