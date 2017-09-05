{ DataSubstitutionAgent } = require "../../lib/agent/data-substitution-agent"
{ ExampleModel } = require "../../lib/model/example-model"
{ DefinitionSuggestion } = require "../../lib/suggester/definition-suggester"
{ PrimitiveValueSuggestion } = require "../../lib/suggester/primitive-value-suggester"
{ InstanceStubSuggestion } = require "../../lib/suggester/instance-stub-suggester"


describe "DataSubstitutionAgent", ->

  agent = undefined
  model = undefined

  beforeEach =>
    model = new ExampleModel()
    agent = new DataSubstitutionAgent model

  it "favors resolutions that add primitive values over those that add code", ->
    resolutions = [
      new DefinitionSuggestion()
      new InstanceStubSuggestion()
    ]
    resolution = agent.chooseResolution resolutions
    (expect resolution instanceof InstanceStubSuggestion).toBe true

  it "favors resolutions that stub out objects over those that add code", ->
    resolutions = [
      new DefinitionSuggestion()
      new PrimitiveValueSuggestion()
    ]
    resolution = agent.chooseResolution resolutions
    (expect resolution instanceof PrimitiveValueSuggestion).toBe true

  it "still returns code expansion resolutions if no substitution " +
      "resolutions are available", ->
    resolutions = [
      new DefinitionSuggestion()
    ]
    resolution = agent.chooseResolution resolutions
    (expect resolution).not.toBe null
