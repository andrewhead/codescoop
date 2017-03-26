{ ExampleModelState, ExampleModelProperty } = require "../../lib/model/example-model"
{ AgentType } = require "../../lib/agent/agent-runner"
$ = require 'jquery'

# Load "chosen" for styling the "select" element.  jQuery must be added
# as a property to the window before "chosen" can be used.
window.jQuery = $
require "chosen-js"


module.exports.AgentRunnerView = class AgentRunnerView extends $

  constructor: (model, agentRunner) ->

    @model = model
    @model.addObserver @
    @agentRunner = agentRunner

    element = $ "<div></div>"
      .addClass "agent-runner"

    @label = $ "<p></p>"
      .text "Finish the example for me, prioritizing:"
      .appendTo element

    # Prepare a drop-down for selecting agent type
    @select = $ "<select></select>"
      .attr "id", "agent-select"
      .appendTo element
    for agentTypeKey, agentType of AgentType
      $ "<option></option>"
        .text @_getOptionNameForAgentType agentType
        .addClass "agent-option"
        .data "agentType", agentType
        .appendTo @select

    # It's important to assign the "update" handler before the creation
    # of the `chosen` widget for the unit tests.  Assigning the handler early
    # makes it possible for us to catch update events sent by the tests
    agentRunnerViewThis = @
    @select.on "change", (event, params) ->
      optionName = ($ @).val()
      agentType = agentRunnerViewThis._getAgentTypeForOptionName optionName
      agentRunner.setActiveAgentType agentType
    @select.chosen { disable_search: true }

    # Make a button for running the chosen agent
    @button = $ "<button></button>"
      .addClass "agent-button"
      .text "Go!"
      .click => agentRunner.runActiveAgent()
      .appendTo element

    # Enable / disable the ability to run the agent based on the model's
    # current state (should only be able to run when resolving errors
    # or reviewing extensions)
    @_updateButtonState @model.getState()

    # Make this object one and the same with the created div
    @.extend @, element

  _updateButtonState: (modelState) ->
    if modelState in [ ExampleModelState.IDLE, ExampleModelState.ANALYSIS ]
      @button.attr "disabled", true
    else
      @button.attr "disabled", false

  _getOptionNameForAgentType: (agentType) ->
    switch agentType
      when AgentType.CODE_EXPANSION then "Code additions"
      when AgentType.DATA_SUBSTITUTION then "Data insertions"

  _getAgentTypeForOptionName: (optionName) ->
    switch optionName
      when "Code additions" then AgentType.CODE_EXPANSION
      when "Data insertions" then AgentType.DATA_SUBSTITUTION

  onPropertyChanged: (object, propertyName, oldValue, newValue) ->
    if propertyName is ExampleModelProperty.STATE
      @_updateButtonState newValue

  getNode: ->
    @[0]
