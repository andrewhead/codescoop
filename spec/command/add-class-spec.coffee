{ ExampleModel } = require "../../lib/model/example-model"
{ ClassRange } = require "../../lib/model/range-set"
{ AddClassRange } = require "../../lib/command/add-class-range"


describe "AddClass", ->

  model = undefined
  beforeEach =>
    model = new ExampleModel()

  it "adds its class range to the model when applied", ->
    classRange = new ClassRange (new Range [4, 2], [5, 3]), undefined, true
    command = new AddClassRange classRange
    command.apply model
    (expect model.getRangeSet().getClassRanges().length).toBe 1
    (expect model.getRangeSet().getClassRanges()[0].getRange()).toEqual \
      new Range [4, 2], [5, 3]

  it "removes its class range from ExampleModel when reverted", ->
    classRange = new ClassRange (new Range [4, 2], [5, 3]), undefined, true
    command = new AddClassRange classRange
    model.getRangeSet().getClassRanges().push classRange
    command.revert model
    (expect model.getRangeSet().getClassRanges().length).toBe 0
