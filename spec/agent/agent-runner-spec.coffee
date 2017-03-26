{ ExampleModel } = require "../../lib/model/example-model"
{ AgentRunner } = require "../../lib/agent/agent-runner"
{ AgentType } = require "../../lib/agent/agent-runner"
{ CodeExpansionAgent } = require "../../lib/agent/code-expansion-agent"
{ DataSubstitutionAgent } = require "../../lib/agent/data-substitution-agent"


describe "AgentRunner", ->

  it "runs the selected agent when `run` is called", ->

    model = new ExampleModel()
    agent0 = new CodeExpansionAgent model
    agent1 = new DataSubstitutionAgent model
    (spyOn agent0, "run").andCallThrough()
    (spyOn agent1, "run").andCallThrough()

    agents = [ agent0, agent1 ]
    agentRunner = new AgentRunner new ExampleModel()
    agentRunner.setAgentForType AgentType.CODE_EXPANSION, agent0
    agentRunner.setAgentForType AgentType.DATA_SUBSTITUTION, agent1
    agentRunner.setActiveAgentType AgentType.DATA_SUBSTITUTION
    agentRunner.runActiveAgent()

    (expect agent0.run).not.toHaveBeenCalled()
    (expect agent1.run).toHaveBeenCalled()

  it "initializes all agents in the deactivated state", ->
    agentRunner = new AgentRunner new ExampleModel()
    codeAgent = agentRunner.getAgentForType AgentType.CODE_EXPANSION
    dataAgent = agentRunner.getAgentForType AgentType.DATA_SUBSTITUTION
    (expect codeAgent.isActivated()).toBe false
    (expect dataAgent.isActivated()).toBe false

  it "activates the \"active\" agent before running it", ->
    model = new ExampleModel()
    agentRunner = new AgentRunner model
    agent = new CodeExpansionAgent model
    agent.deactivate()
    agentRunner.setAgentForType AgentType.CODE_EXPANSION, agent
    agentRunner.setActiveAgentType AgentType.CODE_EXPANSION
    (expect agent.isActivated()).toBe false
    agentRunner.runActiveAgent()
    (expect agent.isActivated()).toBe true

  it "deactivates the agent when it is not longer the active agent", ->
    model = new ExampleModel()
    agentRunner = new AgentRunner model
    agent0 = new CodeExpansionAgent model
    agent1 = new DataSubstitutionAgent model
    agent0.deactivate()
    agent1.deactivate()
    agentRunner.setAgentForType AgentType.CODE_EXPANSION, agent0
    agentRunner.setAgentForType AgentType.DATA_SUBSTITUTION, agent1
    agentRunner.setActiveAgentType AgentType.CODE_EXPANSION
    agent0.activate()
    (expect agent0.isActivated()).toBe true
    agentRunner.setActiveAgentType AgentType.DATA_SUBSTITUTION
    (expect agent0.isActivated()).toBe false
