{ MissingMethodDefinitionDetector } = require "../../lib/error/missing-method-definition"
{ MissingMethodDefinitionError } = require "../../lib/error/missing-method-definition"
{ Range, ClassRange } = require "../../lib/model/range-set"
{ File, Symbol } = require "../../lib/model/symbol-set"
{ ExampleModel } = require "../../lib/model/example-model"


describe "MissingMethodDefinitionDetector", ->

  ### The error detection below is based on this fictional code snippet:
  code = [
    "public class Example {"
    ""
    "  private void method {}"
    ""
    "  private void method2 {"
    "     method();"
    "  }"
    ""
    "}"
  ].join "\n"
  ###

  testFile = new File "path", "filename"
  model = undefined
  detector = undefined

  beforeEach =>

    model = new ExampleModel()

    # Add the results of a mock def-use analysis to the model
    model.getSymbols().getMethodUses().reset [
      new Symbol testFile, "method", (new Range [4, 4], [4, 10]), "Method"
    ]
    model.getSymbols().getMethodDefs().reset [
      new Symbol testFile, "method", (new Range [2, 15], [2, 21]), "Method"
      new Symbol testFile, "method2", (new Range [5, 15], [5, 22]), "Method"
    ]

    detector = new MissingMethodDefinitionDetector()

  it "reports a missing definition if the corresponding declaration is not " +
     "in the active ranges", ->
    model.getRangeSet().getSnippetRanges().push new Range [4, 0], [4, 14]
    errors = detector.detectErrors model
    (expect errors.length).toBe 1
    (expect errors[0].getSymbol().getName()).toBe "method"
    (expect errors[0].getSymbol().getRange()).toEqual new Range [4, 4], [4, 10]

  it "doesn't report missing definitions when a declaration is active", ->
    model.getRangeSet().getSnippetRanges().push new Range [4, 0], [4, 14]
    model.getRangeSet().getSnippetRanges().push new Range [2, 0], [2, 24]
    errors = detector.detectErrors model
    (expect errors.length).toBe 0
