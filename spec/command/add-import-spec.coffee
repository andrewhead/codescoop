{ ExampleModel } = require "../../lib/model/example-model"
{ Import } = require "../../lib/model/import"
{ AddImport } = require "../../lib/command/add-import"


describe "AddImport", ->

  model = undefined
  beforeEach =>
    model = new ExampleModel()

  it "removes its import from ExampleModel when reverted", ->
    import_ = new Import "ArrayList", new Range [0, 7], [0, 18]
    command = new AddImport import_
    model.getImports().push import_
    command.revert model
    (expect model.getImports().length).toBe 0
