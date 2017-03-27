{ ExampleModel } = require "../../lib/model/example-model"
{ Symbol } = require "../../lib/model/symbol-set"
{ RemoveUse } = require "../../lib/command/remove-use"


describe "RemoveUse", ->

  model = undefined
  beforeEach =>
    model = new ExampleModel()

  it "adds the symbol use back to the model when reverted", ->
    symbol = new Symbol undefined, "i", new Range [4, 4], [4, 5], "int"
    command = new RemoveUse symbol
    (expect model.getSymbols().getVariableUses().length).toBe 0
    command.revert model
    (expect model.getSymbols().getVariableUses().length).toBe 1
