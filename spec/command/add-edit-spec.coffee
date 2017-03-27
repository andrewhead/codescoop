{ ExampleModel } = require "../../lib/model/example-model"
{ Replacement } = require "../../lib/edit/replacement"
{ AddEdit } = require "../../lib/command/add-edit"


describe "AddEdit", ->

  model = undefined
  beforeEach =>
    model = new ExampleModel()

  it "removes its edit from ExampleModel when reverted", ->
    edit = new Replacement undefined, "newText"
    command = new AddEdit edit
    model.getEdits().push edit
    command.revert model
    (expect model.getEdits().length).toBe 0
