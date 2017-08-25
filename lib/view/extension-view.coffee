$ = require 'jquery'


# This is an extension to a jQuery object for a code extension suggestion.
# To extend it, you want to override three handlers:
# * preview: show a preview of application of extension
# * revert: roll back a preview
# Each event handler takes a jQuery event as input
module.exports.ExtensionView = class ExtensionView extends $

  constructor: (extension, model, text) ->

    @extension = extension
    @model = model
    @rangeSet = model.getRangeSet()

    # Create a DOM div representing this suggestion view
    element = $ "<div></div>"
      .addClass "extension"

    label = $ "<div></div>"
      .text text
      .appendTo element

    # When the accept button is hovered over, we show a preview.
    # When it's clicked, we tell the model the extension was accepted.
    @acceptButton = $ "<div></div>"
      .attr "id", "accept_button"
      .text "Accept"
      .click (event) => @revert(); @model.setExtensionDecision true
      .mouseover (event) => @preview()
      .mouseout (event) => @revert()
      .appendTo element

    @rejectButton = $ "<div></div>"
      .attr "id", "reject_button"
      .text "Reject"
      .click (event) => @revert(); @model.setExtensionDecision false
      .appendTo element

    # Make this object one and the same with the div we just created
    @.extend @, element
