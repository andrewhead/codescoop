{ ExtensionView } = require "./extension-view"
{ Range } = require "../model/range-set"
log = require "examplify-log"
$ = require "jquery"


module.exports.MediatingUseExtensionView = \
    class MediatingUseExtensionView extends ExtensionView

  constructor: (extension, model) ->
    symbolName = extension.getUse().getName()
    @mediatingUses = extension.getMediatingUses()
    label = $ "<div></div>"
      .html "Do you want any of these uses of <code>#{symbolName}</code>?"
    super extension, model, "", label

    # Class this extension block so we can apply unique styling.
    @.attr "class", "mediating-use-extension"

    # Add a choice for each of the suggested lines.
    @mediatingUses.sort (a, b) => a.getRange().compare b.getRange()
    for mediatingUse in @mediatingUses
      lineButton = $ "<div></div>"
        .attr "class", "mediating-use-choice"
        .text ("Line " + (mediatingUse.getRange().start.row + 1))
        .data "range", mediatingUse.getRange()
        .mouseover ->
          range = ($ @).data 'range'
          rangeSet = model.getRangeSet()
          if range not in rangeSet.getSuggestedRanges()
            rangeSet.getSuggestedRanges().push range
        .mouseout ->
          range = ($ @).data 'range'
          rangeSet = model.getRangeSet()
          rangeSet.getSuggestedRanges().remove range
        .click ->
          if not (($ @).attr 'disabled')
            rangeSet = model.getRangeSet()
            rowNumber = (($ @).data 'range').start.row
            buffer = model.getCodeBuffer()
            lineLength = (buffer.lineForRow rowNumber).length
            newRange = new Range [rowNumber, 0], [rowNumber, lineLength]
            if newRange not in rangeSet.getChosenRanges()
              rangeSet.getChosenRanges().push newRange
      @.append lineButton

    # The expected user response is clicking on more lines in a code view;
    # they are not expected to accept all mediating uses with a button click.
    @acceptButton.remove()

    # Change the message on the reject button, and move it after the line
    # options.
    @rejectButton.text "No, Skip"
      .insertAfter lineButton
      .attr "class", "mediating-use-choice"

    # log.debug "Showing mediating uses", {
    #   use: extension.getUse()
    #   countOtherUses: extension.getMediatingUses().length
    # }

    # Suggest all ranges that are mediating uses, and let the user decide
    # which of them to accept, or which to ignore.
    # @preview()

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
    """
    log.debug "Rejected control structure", {
      type: extension.getControlStructure().constructor.name
      ranges: extension.getRanges()
    }
    """
