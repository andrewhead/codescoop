{ ExampleModel } = require "../../lib/model/example-model"
{ Range } = require "../../lib/model/range-set"
{ AddRange } = require "../../lib/command/add-range"


describe "AddRange", ->

  model = undefined
  beforeEach =>
    model = new ExampleModel()

  it "adds a range to the model when applied", ->
    range = new Range [0, 7], [0, 18]
    command = new AddRange range
    command.apply model
    snippetRanges = model.getRangeSet().getSnippetRanges()
    (expect snippetRanges.length).toBe 1
    (expect snippetRanges[0]).toEqual new Range [0, 7], [0, 18]

  it "removes its range from ExampleModel when reverted", ->

    rangeToRevert = new Range [0, 7], [0, 18]
    otherRange = new Range [1, 7], [1, 18]  # should be left after rever
    snippetRanges = model.getRangeSet().getSnippetRanges()
    snippetRanges.push otherRange
    snippetRanges.push rangeToRevert

    command = new AddRange rangeToRevert
    command.revert model
    (expect snippetRanges.length).toBe 1
    (expect snippetRanges[0]).toEqual new Range [1, 7], [1, 18]
