{ ExtensionView } = require './extension-view'


module.exports.MediatingUseExtensionView = \
    class MediatingUseExtensionView extends ExtensionView

  constructor: (extension, model) ->
    @mediatingUse = extension.getMediatingUse()
    symbolName = @mediatingUse.getName()
    lineNumber = @mediatingUse.getRange().start.row + 1
    message = "Include previous use of \"#{symbolName}\" on L#{lineNumber}?"
    super extension, model, message

  preview: ->
    @model.getRangeSet().getSuggestedRanges().push @mediatingUse.getRange()

  revert: ->
    @model.getRangeSet().getSuggestedRanges().remove @mediatingUse.getRange()
