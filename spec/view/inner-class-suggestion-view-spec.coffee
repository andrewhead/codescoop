{ InnerClassSuggestionView } = require "../../lib/view/inner-class-suggestion"
{ InnerClassSuggestion } = require "../../lib/suggester/inner-class-suggester"
{ ExampleModel } = require "../../lib/model/example-model"
{ Range } = require "../../lib/model/range-set"
{ File, Symbol } = require "../../lib/model/symbol-set"


describe "InnerClassSuggestionView", ->

  testFile = new File "path", "file_name"
  suggestion = new InnerClassSuggestion \
    (new Symbol testFile, "InnerClass", (new Range [4, 2], [5, 3]), "Class"),
    (new Range [4, 2], [5, 3]), false
  model = undefined
  suggestedRanges = undefined
  view = undefined

  beforeEach =>
    model = new ExampleModel()
    view = new InnerClassSuggestionView suggestion, model
    suggestedRanges = model.getRangeSet().getSuggestedRanges()

  it "adds a suggested range for the import when previewing", ->
    (expect suggestedRanges.length).toBe 0
    view.preview()
    (expect suggestedRanges.length).toBe 1
    (expect suggestedRanges[0]).toEqual new Range [4, 2], [5, 3]

  it "removes the suggested range when reverting", ->
    view.preview()
    view.revert()
    (expect suggestedRanges.length).toBe 0
