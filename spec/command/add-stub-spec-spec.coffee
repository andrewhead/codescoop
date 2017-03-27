{ ExampleModel } = require "../../lib/model/example-model"
{ StubSpec } = require "../../lib/model/stub"
{ AddStubSpec } = require "../../lib/command/add-stub-spec"


describe "AddDeclaration", ->

  model = undefined
  beforeEach =>
    model = new ExampleModel()

  it "removes its stub spec from ExampleModel when reverted", ->
    stubSpec = new StubSpec "className"
    command = new AddStubSpec stubSpec
    model.getStubSpecs().push stubSpec
    command.revert model
    (expect model.getStubSpecs().length).toBe 0
