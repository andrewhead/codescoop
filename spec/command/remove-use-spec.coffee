{ ExampleModel } = require "../../lib/model/example-model"
{ Symbol, File } = require "../../lib/model/symbol-set"
{ Range } = require "../../lib/model/range-set"
{ RemoveUse } = require "../../lib/command/remove-use"


describe "RemoveUse", ->

  testFile = new File "path", "file_name"
  model = undefined
  beforeEach =>
    model = new ExampleModel()

  it "removes the symbol from the model when applied", ->
    symbol = new Symbol testFile, "i", (new Range [4, 4], [4, 5]), "int"
    model.getSymbols().getVariableUses().push symbol
    command = new RemoveUse symbol
    command.apply model
    (expect model.getSymbols().getVariableUses().length).toBe 0

  it "adds the symbol use back to the model when reverted", ->
    symbol = new Symbol testFile, "i", (new Range [4, 4], [4, 5]), "int"
    command = new RemoveUse symbol
    (expect model.getSymbols().getVariableUses().length).toBe 0
    command.revert model
    (expect model.getSymbols().getVariableUses().length).toBe 1
