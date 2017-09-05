{ parse } = require "../../lib/analysis/parse-tree"
{ ExampleModel } = require "../../lib/model/example-model"
{ MissingTypeDefinitionError } = require "../../lib/error/missing-type-definition"
{ File, Symbol } = require "../../lib/model/symbol-set"
{ Range } = require "../../lib/model/range-set"
{ InnerClassSuggester, InnerClassSuggestion } = require "../../lib/suggester/inner-class-suggester"


describe "InnerClassSuggester", ->

  model = undefined
  suggester = undefined
  testFile = undefined
  beforeEach =>
    parseTree = parse [
      "public class Example {"
      "  public static void main(String[] args) {"
      "    InnerClass innerClass;"
      "  }"
      "  private static class InnerClass {"
      "  }"
      "}"
    ].join '\n'
    testFile = new File "path", "file_name"
    model = new ExampleModel()
    model.setParseTree parseTree
    suggester = new InnerClassSuggester()

  describe "when it makes a suggestion", ->

    suggestions = undefined
    beforeEach =>
      model.getSymbols().getTypeDefs().push \
        new Symbol testFile, "InnerClass", (new Range [4, 23], [4, 24]), "Class"
      error = new MissingTypeDefinitionError \
        new Symbol testFile, "InnerClass", (new Range [2, 4], [2, 14]), "Class"
      suggestions = suggester.getSuggestions error, model

    it "suggests inner classes defined in this program", ->
      (expect suggestions.length).toBe 1
      (expect suggestions[0] instanceof InnerClassSuggestion)
      (expect suggestions[0].getRange()).toEqual new Range [4, 2], [5, 3]

    it "sets the static flag if the InnerClass is already static", ->
      (expect suggestions[0].isStatic()).toBe true

  it "only suggests inner classes for which there are defs in the model", ->
    # This skips the step where a type def is added to the model
    error = new MissingTypeDefinitionError \
      new Symbol testFile, "InnerClass", (new Range [2, 4], [2, 14]), "Class"
    suggestions = suggester.getSuggestions error, model
    (expect suggestions.length).toBe 0

  describe "if the InnerClass is not static", ->

    model = undefined
    suggester = undefined
    testFile = undefined
    beforeEach =>
      parseTree = parse [
        "public class Example {"
        "  public static void main(String[] args) {"
        "    InnerClass innerClass;"
        "  }"
        "  public class InnerClass {"
        "  }"
        "}"
      ].join '\n'
      testFile = new File "path", "file_name"
      model = new ExampleModel()
      model.setParseTree parseTree
      suggester = new InnerClassSuggester()

    it "does not set the static flag", ->
      model.getSymbols().getTypeDefs().push \
        new Symbol testFile, "InnerClass", (new Range [4, 22], [4, 32]), "Class"
      error = new MissingTypeDefinitionError \
        new Symbol testFile, "InnerClass", (new Range [2, 4], [2, 14]), "Class"
      suggestions = suggester.getSuggestions error, model
      (expect suggestions[0].isStatic()).toBe false
