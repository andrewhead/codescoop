{ IfControlStructure, ForControlStructure, WhileControlStructure, DoWhileControlStructure, TryCatchControlStructure } = require "../analysis/parse-tree"
{ ExtensionView } = require './extension-view'


module.exports.ControlStructureExtensionView = \
    class ControlStructureExtensionView extends ExtensionView

  constructor: (extension, model) ->
    structure = extension.getControlStructure()
    controlName = switch
      when (structure instanceof IfControlStructure) then "if"
      when (structure instanceof ForControlStructure) then "for"
      when (structure instanceof WhileControlStructure) then "while"
      when (structure instanceof DoWhileControlStructure) then "do-while"
      when (structure instanceof TryCatchControlStructure) then "try"
    super extension, model, "Include '#{controlName}' structure?"

  preview: ->
    for range in @extension.getRanges()
      @model.getRangeSet().getSuggestedRanges().push range

  revert: ->
    # Iterate backwards over suggested ranges as we'll be removing
    # ranges from the list, and don't want to mess with the iteration
    # for later elements as we remove items.
    suggestedRanges = @model.getRangeSet().getSuggestedRanges()
    return if suggestedRanges.length is 0
    for range in @extension.getRanges()
      suggestedRanges.remove range
