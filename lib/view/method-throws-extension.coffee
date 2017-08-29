{ ExtensionView } = require "./extension-view"
log = require "examplify-log"


module.exports.MethodThrowsExtensionView = \
    class MethodThrowsExtensionView extends ExtensionView

  constructor: (extension, model) ->
    throwableName = extension.getThrowableName()
    @throwsRange = extension.getThrowsRange()
    @throwableRange = extension.getThrowableRange()
    super extension, model, "Should the example throw '#{throwableName}' too?"

  preview: ->
    @model.getRangeSet().getSuggestedRanges().push @throwsRange
    @model.getRangeSet().getSuggestedRanges().push @throwableRange

  revert: ->
    @model.getRangeSet().getSuggestedRanges().remove @throwsRange
    @model.getRangeSet().getSuggestedRanges().remove @throwableRange

  onAccept: (extension) ->
    log.debug "Accepted throws", {
      throwsName: extension.getThrowableName()
      selectionRange: extension.getInnerRange()
    }

  onReject: (extension) ->
    log.debug "Rejected throws", {
      throwsName: extension.getThrowableName()
      selectionRange: extension.getInnerRange()
    }
