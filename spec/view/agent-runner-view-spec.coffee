{ ExampleModel, ExampleModelState } = require "../../lib/model/example-model"
{ AgentRunner } = require "../../lib/agent/agent-runner"
{ AgentType } = require "../../lib/agent/agent-runner"
{ AgentRunnerView } = require "../../lib/view/agent-runner-view"


describe "AgentRunnerView", ->

  model = undefined
  agentRunner = undefined
  agentRunnerView = undefined

  beforeEach =>
    model = new ExampleModel()
    agentRunner = new AgentRunner model
    agentRunnerView = new AgentRunnerView model, agentRunner

  it "sets the active agent type when an agent type chosen in the dropdown", ->
    selectMenu = agentRunnerView.find "#agent-select"
    (selectMenu.val "Data insertions")
    selectMenu.trigger "change"
    activeAgentType = agentRunner.getActiveAgentType()
    (expect activeAgentType).toBe AgentType.DATA_SUBSTITUTION

  it "runs the active agent when the \"Go\" button is clicked", ->
    (spyOn agentRunner, "runActiveAgent").andCallThrough()
    goButton = agentRunnerView.find "button"
    (expect agentRunner.runActiveAgent).not.toHaveBeenCalled()
    goButton.click()
    (expect agentRunner.runActiveAgent).toHaveBeenCalled()

  it "disables the \"Run\" button if the model starts in IDLE state", ->
    model.setState ExampleModelState.IDLE
    agentRunner = new AgentRunner model
    agentRunnerView = new AgentRunnerView model, agentRunner
    goButton = agentRunnerView.find "button"
    (expect goButton.attr "disabled").toBe "disabled"

  it "disables the \"Run\" button if the model starts in ANALYSIS state", ->
    model.setState ExampleModelState.ANALYSIS
    agentRunner = new AgentRunner model
    agentRunnerView = new AgentRunnerView model, agentRunner
    goButton = agentRunnerView.find "button"
    (expect goButton.attr "disabled").toBe "disabled"

  it "disables the \"Run\" button whenever the model enters IDLE state", ->
    model.setState ExampleModelState.IDLE
    goButton = agentRunnerView.find "button"
    (expect goButton.attr "disabled").toBe "disabled"

  it "enables the \"Run\" button whenever the model leaves the IDLE state", ->
    model.setState ExampleModelState.IDLE
    model.setState ExampleModelState.ERROR_CHOICE
    goButton = agentRunnerView.find "button"
    (expect goButton.attr "disabled").not.toBe "disabled"
