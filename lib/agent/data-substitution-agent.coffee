{ Agent } = require "./agent"
{ acceptOnlyForLoopsAndTryBlocks } = require "../../lib/agent/policies"
{ chooseFirstError } = require "../../lib/agent/policies"
{ PrimitiveValueSuggestion } = require "../../lib/suggester/primitive-value-suggester"
{ InstanceStubSuggestion } = require "../../lib/suggester/instance-stub-suggester"


# This agent favors resolving errors by substituting in data
module.exports.DataSubstitutionAgent = class DataSubstitutionAgent extends Agent

  chooseError: chooseFirstError

  chooseResolution: (resolutions) ->

    dataSubstitutionResolutions = resolutions.filter (resolution) =>
      ((resolution instanceof PrimitiveValueSuggestion) or
        (resolution instanceof InstanceStubSuggestion))

    if dataSubstitutionResolutions.length > 0
      return dataSubstitutionResolutions[0]
    resolutions[0]

  acceptExtension: acceptOnlyForLoopsAndTryBlocks
