{ LocalMethodSuggestionView } = require "../../lib/view/local-method-suggestion"
{ LocalMethodSuggestion } = require "../../lib/suggester/local-method-suggester"
{ ExampleModel } = require "../../lib/model/example-model"
{ Range } = require "../../lib/model/range-set"
{ File, Symbol } = require "../../lib/model/symbol-set"


describe "LocalMethodSuggestionView", ->

  testFile = new File "path", "file_name"
  suggestion = new LocalMethodSuggestion \
    (new Symbol testFile, "method", (new Range [7, 4], [7, 10]), "Method"),
    (new Range [4, 2], [5, 3]), false
  model = undefined
  suggestedRanges = undefined
  view = undefined

  beforeEach =>
    model = new ExampleModel()
    view = new LocalMethodSuggestionView suggestion, model
    suggestedRanges = model.getRangeSet().getSuggestedRanges()

  it "adds a suggested range for the method when previewing", ->
    (expect suggestedRanges.length).toBe 0
    view.preview()
    (expect suggestedRanges.length).toBe 1
    (expect suggestedRanges[0]).toEqual new Range [4, 2], [5, 3]

  it "removes the suggested range when reverting", ->
    view.preview()
    view.revert()
    (expect suggestedRanges.length).toBe 0
