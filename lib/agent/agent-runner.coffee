{ CodeExpansionAgent } = require "./code-expansion-agent"
{ DataSubstitutionAgent } = require "./data-substitution-agent"


module.exports.AgentType = AgentType =
  CODE_EXPANSION: { value: 0, name: "code-expansion" }
  DATA_SUBSTITUTION: { value: 1, name: "data-substitution" }


module.exports.AgentRunner = class AgentRunner

  constructor: (model) ->
    @agents = [
      { type: AgentType.CODE_EXPANSION, agent: (new CodeExpansionAgent model) }
      { type: AgentType.DATA_SUBSTITUTION, agent: (new DataSubstitutionAgent model) }
    ]
    for agentElement in @agents
      agentElement.agent.deactivate()
    @setActiveAgentType @agents[0].type

  setActiveAgentType: (agentType) ->

    # Deactivate the current active agent first, to avoid side effects from
    # old active agents still mutating the model's state
    if @activeAgentType?
      activeAgent = @getAgentForType @activeAgentType
      activeAgent.deactivate()

    @activeAgentType = agentType

  getActiveAgentType: ->
    @activeAgentType

  getAgentForType: (agentType) ->
    for agentElement in @agents
      if agentElement.type is agentType
        return agentElement.agent

  setAgentForType: (agentType, agent) ->
    for agentElement in @agents
      if agentElement.type is agentType
        agentElement.agent = agent
        break

  runActiveAgent: ->
    for agentElement in @agents
      if agentElement.type is @activeAgentType
        agent = agentElement.agent
        agent.activate() if not agent.isActivated()
        agent.run()
