{ ImportSuggestionView } = require "../../lib/view/import-suggestion"
{ ImportSuggestion } = require "../../lib/suggester/import-suggester"
{ ExampleModel } = require "../../lib/model/example-model"
{ Range } = require "../../lib/model/range-set"
{ File, Symbol } = require "../../lib/model/symbol-set"
{ Import } = require "../../lib/model/import"


describe "ImportSuggestionView", ->

  import_ = new Import "org.Book", new Range [0, 7], [0, 15]
  suggestion = new ImportSuggestion import_
  model = undefined
  suggestedRanges = undefined
  view = undefined

  beforeEach =>
    model = new ExampleModel()
    view = new ImportSuggestionView suggestion, model, undefined
    suggestedRanges = model.getRangeSet().getSuggestedRanges()

  it "adds a suggested range for the import when previewing", ->
    (expect suggestedRanges.length).toBe 0
    view.preview()
    (expect suggestedRanges.length).toBe 1
    (expect suggestedRanges[0]).toEqual new Range [0, 7], [0, 15]

  it "removes the suggested range when reverting", ->
    view.preview()
    view.revert()
    (expect suggestedRanges.length).toBe 0
