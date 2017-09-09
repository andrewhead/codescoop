$ = require 'jquery'


SuggestionBlockViewState =
  HEADER: { value: 0, name: "header" }
  SUGGESTIONS: { value: 1, name: "suggestions" }


# When extending this block view, you must define a custom title,
# and override the createSuggestionView class which produces interactive
# suggestions that have access to the model. The createSuggestionView
# function takes four parameters:
# * suggestion: the suggestion for this item in the suggestion list
# * model: the example model
# * errorMarker: the text editor marker that points to the error
# * i: the index of the suggestion (starts at 0)
# The createSuggestionView function should return a SuggestionView
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
          for suggestion, i in @suggestions
            suggestionView = @createSuggestionView suggestion, @model, @errorMarker, i
            @append suggestionView
            @suggestionViews.push suggestionView
          @state = SuggestionBlockViewState.SUGGESTIONS
    element.append header

    @.extend @, element

  dismiss: ->
    for suggestionView in @suggestionViews
      suggestionView.revert()
      suggestionView.remove()
    @suggestionView = []
    @state = SuggestionBlockViewState.HEADER
    # XXX: This is a hack.  Suggested ranges should probably only be rewound
    # one at a time whenever a suggestion or extension is reverted
    ranges = @model.getRangeSet().getSuggestedRanges()
    range_index = ranges.length
    while range_index > 0
      ranges.remove(ranges[range_index])
      range_index -= 1
    # for range in @model.getRangeSet().getSuggestedRanges().reset []

  # Propagate mouseout to suggestions and remove suggestions
  onMouseLeave: (event) -> @dismiss()
