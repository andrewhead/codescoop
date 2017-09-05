{ ExampleModel } = require "../../lib/model/example-model"
{ MethodRange } = require "../../lib/model/range-set"
{ AddMethodRange } = require "../../lib/command/add-method-range"


describe "AddMethod", ->

  model = undefined
  beforeEach =>
    model = new ExampleModel()

  it "adds its method range to the model when applied", ->
    methodRange = new MethodRange (new Range [4, 2], [5, 3]), undefined, true
    command = new AddMethodRange methodRange
    command.apply model
    (expect model.getRangeSet().getMethodRanges().length).toBe 1
    (expect model.getRangeSet().getMethodRanges()[0].getRange()).toEqual \
      new Range [4, 2], [5, 3]

  it "removes its method range from ExampleModel when reverted", ->
    methodRange = new MethodRange (new Range [4, 2], [5, 3]), undefined, true
    command = new AddMethodRange methodRange
    model.getRangeSet().getMethodRanges().push methodRange
    command.revert model
    (expect model.getRangeSet().getMethodRanges().length).toBe 0
