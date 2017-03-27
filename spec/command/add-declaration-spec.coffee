{ ExampleModel } = require "../../lib/model/example-model"
{ Declaration } = require "../../lib/edit/declaration"
{ AddDeclaration } = require "../../lib/command/add-declaration"


describe "AddDeclaration", ->

  model = undefined
  beforeEach =>
    model = new ExampleModel()

  it "removes its declaration from ExampleModel when reverted", ->
    declaration = new Declaration "i", "int"
    command = new AddDeclaration declaration
    model.getAuxiliaryDeclarations().push declaration
    command.revert model
    (expect model.getAuxiliaryDeclarations().length).toBe 0
