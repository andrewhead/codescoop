{ ExampleModel } = require "../../lib/model/example-model"
{ StubSpec } = require "../../lib/model/stub"
{ AddStubSpec } = require "../../lib/command/add-stub-spec"


describe "AddDeclaration", ->

  model = undefined
  beforeEach =>
    model = new ExampleModel()

  it "adds its stub spec to the model when applied", ->
    stubSpec = new StubSpec "className"
    command = new AddStubSpec stubSpec
    command.apply model
    (expect model.getStubSpecs().length).toBe 1
    (expect model.getStubSpecs()[0].className).toEqual "className"

  it "removes its stub spec from ExampleModel when reverted", ->
    stubSpec = new StubSpec "className"
    command = new AddStubSpec stubSpec
    model.getStubSpecs().push stubSpec
    command.revert model
    (expect model.getStubSpecs().length).toBe 0
