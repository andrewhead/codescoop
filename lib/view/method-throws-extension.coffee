{ ExtensionView } = require "./extension-view"
log = require "examplify-log"


module.exports.MethodThrowsExtensionView = \
    class MethodThrowsExtensionView extends ExtensionView

  constructor: (extension, model) ->
    throwableName = extension.getSuggestedThrows()
    @throwingRange = extension.getThrowingRange()
    super extension, model,
      "This function can cause an '#{throwableName}'. Add it to the throws?"

  preview: ->
    @model.getRangeSet().getSuggestedRanges().push @throwingRange

  revert: ->
    @model.getRangeSet().getSuggestedRanges().remove @throwingRange

  onAccept: (extension) ->
    # log.debug "Accepted throws", {
    #   throwsName: extension.getSuggestedThrows()
    #   selectionRange: extension.getThrowingRange()
    # }

  onReject: (extension) ->
    # log.debug "Rejected throws", {
    #   throwsName: extension.getSuggestedThrows()
    #   selectionRange: extension.getThrowingRange()
    # }
