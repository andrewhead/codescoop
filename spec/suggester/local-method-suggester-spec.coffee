{ parse } = require "../../lib/analysis/parse-tree"
{ ExampleModel } = require "../../lib/model/example-model"
{ MissingMethodDefinitionError } = require "../../lib/error/missing-method-definition"
{ File, Symbol } = require "../../lib/model/symbol-set"
{ Range } = require "../../lib/model/range-set"
{ LocalMethodSuggester, LocalMethodSuggestion } = require "../../lib/suggester/local-method-suggester"


describe "LocalMethodSuggester", ->

  model = undefined
  suggester = undefined
  testFile = undefined
  beforeEach =>
    parseTree = parse [
      "public class Example {"
      ""
      "  public Example() {"
      "    instanceMethod();"
      "  }"
      ""
      "  public static void main(String[] args) {"
      "    staticMethod();"
      "    new Example();"
      "  }"
      ""
      "  private static void staticMethod() {"
      "  }"
      ""
      "  private void instanceMethod() {"
      "  }"
      ""
      "}"
    ].join '\n'
    testFile = new File "path", "file_name"
    model = new ExampleModel()
    model.setParseTree parseTree
    model.getSymbols().getMethodDefs().reset [
      new Symbol testFile, "staticMethod", (new Range [11, 22], [11, 34]), "Method"
      new Symbol testFile, "instanceMethod", (new Range [14, 15], [14, 29]), "Method"
    ]
    suggester = new LocalMethodSuggester()

  describe "when suggesting a static method", ->

    suggestions = undefined
    beforeEach =>
      error = new MissingMethodDefinitionError \
        new Symbol testFile, "staticMethod", (new Range [7, 4], [7, 16]), "Method"
      suggestions = suggester.getSuggestions error, model

    it "suggests the static method defined in this program", ->
      (expect suggestions.length).toBe 1
      (expect suggestions[0] instanceof LocalMethodSuggestion)
      (expect suggestions[0].getRange()).toEqual new Range [11, 2], [12, 3]

    it "sets the static flag if the method is already static", ->
      (expect suggestions[0].isStatic()).toBe true

  describe "if the LocalMethod is not static", ->

    suggestions = undefined
    beforeEach =>
      error = new MissingMethodDefinitionError \
        new Symbol testFile, "instanceMethod", (new Range [3, 4], [3, 18]), "Method"
      suggestions = suggester.getSuggestions error, model

    it "does not set the static flag", ->
      (expect suggestions[0].isStatic()).toBe false
