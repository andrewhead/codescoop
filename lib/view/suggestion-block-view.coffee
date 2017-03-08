$ = require 'jquery'


# When extending this block view, you must define a custom title,
# and override the createSuggestionView class which produces interactive
# suggestions that have access to the model
module.exports.SuggestionBlockView = class SuggestionBlockView extends $

  constructor: (title, suggestions, model, errorMarker) ->

    @errorMarker = errorMarker
    @model = model
    @suggestions = suggestions
    @suggestionViews = []

    element = super "<div></div>"
      .addClass "resolution-class-block"
      .mouseout (event) => @onMouseOut event

    header = $ "<div></div>"
      .addClass "resolution-class-header"
      .text title
      .mouseout => false  # return false, prevent propagation to block
      .mouseover =>
        for suggestion in @suggestions
          suggestionView = @createSuggestionView suggestion, @model, @errorMarker
          @append suggestionView
          @suggestionViews.push suggestionView
    element.append header

    @.extend @, element

  onMouseOut: (event) ->
    # Propagate mouseout to suggestions and remove suggestions
    for suggestionView in @suggestionViews
      suggestionView.revert()
      suggestionView.remove()
    @suggestionView = []
