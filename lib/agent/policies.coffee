{ ControlStructureExtension } = require "../../lib/extender/control-structure-extender"
{ IfControlStructure, ForControlStructure, WhileControlStructure, DoWhileControlStructure, TryCatchControlStructure } = require "../../lib/analysis/parse-tree"


###
Some policies for choosing errors and resolution and accepting extensions will
be common across many agents.  When there's a policy that multiple agents
might benefit from, we include it in this file.  Note that these policies should
be written in a way that is agnostic to the agent's state, given that it should
be possible to plug them in to any agent.
###


###
Error-choice policies
###
module.exports.chooseFirstError = chooseFirstError = (errors) ->
  errors[0]


###
Extension policies
###
module.exports.acceptOnlyForLoopsAndTryBlocks =\
  acceptOnlyForLoopsAndTryBlocks = (extension) ->
    return false if not (extension instanceof ControlStructureExtension)
    controlStructure = extension.getControlStructure()
    accept = ((controlStructure instanceof ForControlStructure) or
      (controlStructure instanceof TryCatchControlStructure))
    accept
