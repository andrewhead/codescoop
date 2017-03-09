$ = require 'jquery'


SuggestionBlockViewState =
  HEADER: { value: 0, name: "header" }
  SUGGESTIONS: { value: 1, name: "suggestions" }


# When extending this block view, you must define a custom title,
# and override the createSuggestionView class which produces interactive
# suggestions that have access to the model
module.exports.SuggestionBlockView = class SuggestionBlockView extends $

  constructor: (title, suggestions, model, errorMarker) ->

    @errorMarker = errorMarker
    @model = model
    @suggestions = suggestions
    @suggestionViews = []
    @state = SuggestionBlockViewState.HEADER

    element = super "<div></div>"
      .addClass "resolution-class-block"
      # This should be "mouseleave" and not "mouseout": with "mouseout",
      # the suggestions are cleared whenever the mouse leaves any descendant
      .mouseleave (event) => @onMouseLeave event

    header = $ "<div></div>"
      .addClass "resolution-class-header"
      .text title
      .mouseover =>
        if @state is SuggestionBlockViewState.HEADER
          for suggestion in @suggestions
            suggestionView = @createSuggestionView suggestion, @model, @errorMarker
            @append suggestionView
            @suggestionViews.push suggestionView
          @state = SuggestionBlockViewState.SUGGESTIONS
    element.append header

    @.extend @, element

  onMouseLeave: (event) ->
    # Propagate mouseout to suggestions and remove suggestions
    for suggestionView in @suggestionViews
      suggestionView.revert()
      suggestionView.remove()
    @suggestionView = []
    @state = SuggestionBlockViewState.HEADER
