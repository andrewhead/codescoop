{ ExampleModel } = require "../../lib/model/example-model"
{ Declaration } = require "../../lib/edit/declaration"
{ AddDeclaration } = require "../../lib/command/add-declaration"


describe "AddDeclaration", ->

  model = undefined
  beforeEach =>
    model = new ExampleModel()

  it "adds a declaration to the model when applied", ->
    declaration = new Declaration "i", "int"
    command = new AddDeclaration declaration
    command.apply model
    declarations = model.getAuxiliaryDeclarations()
    (expect declarations.length).toBe 1
    declaration = declarations[0]
    (expect declaration instanceof Declaration).toBe true
    (expect declaration.getName()).toEqual "i"
    (expect declaration.getType()).toEqual "int"

  it "removes its declaration from ExampleModel when reverted", ->
    declaration = new Declaration "i", "int"
    command = new AddDeclaration declaration
    model.getAuxiliaryDeclarations().push declaration
    command.revert model
    (expect model.getAuxiliaryDeclarations().length).toBe 0
