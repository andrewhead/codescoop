{ ExampleModel } = require "../../lib/model/example-model"
{ AddThrows } = require "../../lib/command/add-throws"


describe "AddThrows", ->

  model = undefined
  beforeEach =>
    model = new ExampleModel()

  it "adds a throwable to the model when applied", ->
    command = new AddThrows "IOException"
    command.apply model
    (expect model.getThrows().length).toBe 1
    (expect model.getThrows()[0]).toEqual "IOException"

  it "removes its throwable from ExampleModel when reverted", ->
    command = new AddThrows "IOException"
    model.getThrows().push "IOException"
    command.revert model
    (expect model.getThrows().length).toBe 0
