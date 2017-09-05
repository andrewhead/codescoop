{ CodeExpansionAgent } = require "../../lib/agent/code-expansion-agent"
{ ExampleModel } = require "../../lib/model/example-model"
{ DefinitionSuggestion } = require "../../lib/suggester/definition-suggester"
{ PrimitiveValueSuggestion } = require "../../lib/suggester/primitive-value-suggester"
{ InstanceStubSuggestion } = require "../../lib/suggester/instance-stub-suggester"


describe "CodeExpansionAgent", ->

  agent = undefined
  model = undefined

  beforeEach =>
    model = new ExampleModel()
    agent = new CodeExpansionAgent model

  it "chooses resolutions involving code before those that substitute data", ->
    resolutions = [
      new PrimitiveValueSuggestion()
      new InstanceStubSuggestion()
      new DefinitionSuggestion()
    ]
    resolution = agent.chooseResolution resolutions
    (expect resolution instanceof DefinitionSuggestion).toBe true

  it "still returns resolutions that substitute data if no code-related " +
      "resolutions are available", ->
    resolutions = [
      new PrimitiveValueSuggestion()
      new InstanceStubSuggestion()
    ]
    resolution = agent.chooseResolution resolutions
    (expect resolution).not.toBe null
