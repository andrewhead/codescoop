{ ExampleModel } = require "../../lib/model/example-model"
{ AddPrintedSymbol } = require "../../lib/command/add-printed-symbol"


describe "AddPrintedSymbol", ->

  model = undefined
  symbolName = "temp"
  command = undefined
  beforeEach =>
    model = new ExampleModel()
    command = new AddPrintedSymbol symbolName

  it "adds a range to the model when applied", ->
    command.apply model
    printedSymbols = model.getPrintedSymbols()
    (expect printedSymbols.length).toBe 1
    (expect printedSymbols[0]).toEqual "temp"

  it "removes its range from ExampleModel when reverted", ->
    model.getPrintedSymbols().push "temp"
    command.revert model
    (expect model.getPrintedSymbols().length).toBe 0
