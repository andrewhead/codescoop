{ ExampleModel } = require "../../lib/model/example-model"
{ Range } = require "../../lib/model/range-set"
{ AddLineForRange } = require "../../lib/command/add-line-for-range"
{ TextBuffer } = require "atom"


describe "AddLineForRange", ->

  model = undefined
  beforeEach =>
    model = new ExampleModel new TextBuffer { text: "Hello world" }

  it "removes its range from ExampleModel when reverted", ->
    range = new Range [0, 1], [0, 2]
    command = new AddLineForRange range
    command.apply model
    (expect model.getRangeSet().getActiveRanges().length).toBe 1
    command.revert model
    (expect model.getRangeSet().getActiveRanges().length).toBe 0
