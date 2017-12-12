$ = require 'jquery'
log = require 'examplify-log'


# This is an extension to a jQuery object for a code modification suggestion.
# To extend it, you want to override three handlers:
# * preview: show a preview of application of suggestion
# * revert: roll back a preview
# Each event handler takes a jQuery event as input
module.exports.SuggestionView = class SuggestionView extends $

  constructor: (suggestion, model, text) ->

    @suggestion = suggestion
    @model = model
    @rangeSet = model.getRangeSet()

    # Create a DOM div representing this suggestion view
    element = $ "<div></div>"
      .text text
      .addClass "suggestion"
      .click (event) =>
        @revert()
        @cleanup() if @cleanup?
        log.debug "Picked a correction",
          { type: suggestion.constructor.name, suggestion }
        @model.setResolutionChoice suggestion
      .mouseover (event) =>
        log.debug "Previewing a correction",
          { type: suggestion.constructor.name, suggestion }
        @preview()
      .mouseout (event) =>
        log.debug "Un-previewing a correction",
          { type: suggestion.constructor.name, suggestion }
        @revert()

    # Make this object one and the same with the div we just created
    @.extend @, element
