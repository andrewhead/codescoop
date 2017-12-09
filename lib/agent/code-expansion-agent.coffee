{ Agent } = require "./agent"
{ acceptOnlyForLoopsAndTryBlocks } = require "../../lib/agent/policies"
{ chooseFirstError } = require "../../lib/agent/policies"
{ DefinitionSuggestion } = require "../../lib/suggester/definition-suggester"


# This agent favors resolving errors by adding more code
module.exports.CodeExpansionAgent = class CodeExpansionAgent extends Agent

  chooseError: chooseFirstError

  chooseResolution: (resolutions) ->
    codeExpansionResolutions = resolutions.filter (resolution) =>
      resolution instanceof DefinitionSuggestion
    return codeExpansionResolutions[0] if codeExpansionResolutions.length > 0
    return resolutions[0]

  acceptExtension: acceptOnlyForLoopsAndTryBlocks
