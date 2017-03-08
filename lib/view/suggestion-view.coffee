$ = require 'jquery'


# This is an extension to a jQuery object for a code modification suggestion.
# To extend it, you probably want to override the following handlers:
# onClick, onMouseOver, and onMouseOut
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
      .click (event) => @onClick event
      .mouseover (event) => @onMouseOver event
      .mouseout (event) => @onMouseOut event

    # Make this object one and the same with the div we just created
    @.extend @, element
