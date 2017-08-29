{ ExtensionView } = require "./extension-view"
log = require "examplify-log"


module.exports.MediatingUseExtensionView = \
    class MediatingUseExtensionView extends ExtensionView

  constructor: (extension, model) ->
    symbolName = extension.getUse().getName()
    @mediatingUses = extension.getMediatingUses()
    message = "← Do you want any of those uses of \"#{symbolName}\"?"
    super extension, model, message

    # The expected user response is clicking on more lines in a code view;
    # they are not expected to accept all mediating uses with a button click.
    @acceptButton.remove()

    # Change the message on the reject button.
    @rejectButton.text "No"

    log.debug "Showing mediating uses", {
      use: extension.getUse()
      countOtherUses: extension.getMediatingUses().length
    }

    # Suggest all ranges that are mediating uses, and let the user decide
    # which of them to accept, or which to ignore.
    @preview()

  preview: ->
    for mediatingUse in @mediatingUses
      # XXX: for some reason, ranges are getting added multiple times.  This
      # prevents us from a situation where we add a range more than once
      # (making it hard to remove a suggestion), but we should find the
      # root of the problem too.
      if mediatingUse.getRange() not in @model.getRangeSet().getSuggestedRanges()
        @model.getRangeSet().getSuggestedRanges().push mediatingUse.getRange()

  revert: ->
    for mediatingUse in @mediatingUses
      @model.getRangeSet().getSuggestedRanges().remove mediatingUse.getRange()

  onReject: (extension) ->
    log.debug "Rejected control structure", {
      type: extension.getControlStructure().constructor.name
      ranges: extension.getRanges()
    }
