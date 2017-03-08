$ = require 'jquery'
{ ExampleModel, ExampleModelState, ExampleModelProperty } = require './model/example-model'
{ Range, RangeSet } = require './model/range-set'
{ MissingDefinitionError } = require './error/missing-definition'
{ SymbolSuggestion, PrimitiveValueSuggestion } = require './suggestor/suggestion'
{ SymbolSuggestionBlockView } = require "./view/symbol-suggestion"
{ PrimitiveValueSuggestionBlockView } = require "./view/primitive-value-suggestion"


module.exports.ExampleView = class ExampleView

  programTemplate:
    start: [
      "public class SmallScoop {"
      ""
      "    public static void main(String[] args) {"
      ""
      ""
    ].join '\n'
    end: [
      ""
      ""
      "    }"
      ""
      "}"
    ].join '\n'
    mainIndentLevel: 4  # 4 indents * 2 spaces / indent = 8 spaces

  constructor: (model, textEditor) ->
    @model = model
    @model.addObserver @
    @textEditor = textEditor
    @markers = []
    @markerUses = {}
    @update()

  getTextEditor: () ->
    @textEditor

  onPropertyChanged: (object, propertyName, propertyValue) ->
    @update() if propertyName in [
      ExampleModelProperty.STATE
      # ExampleModelProperty.UNDEFINED_USES
      ExampleModelProperty.ACTIVE_RANGES
    ]

  update: ->
    @_clearMarkers()
    # We add in the code, then add the markers, then the boilerplate.
    # By adding the code first, we get to use the character offsets of
    # each symbol to mark them, before inserting other boilerplate code
    activeRangeOffsets = @_addCodeLines()
    if @model.getState() is ExampleModelState.ERROR_CHOICE
      @_markErrors @model.getErrors(), activeRangeOffsets
    else if @model.getState() is ExampleModelState.RESOLUTION
      @_addDefinitionWidget @model.getSuggestions(), activeRangeOffsets
    @_insertBoilerplate()

  _clearMarkers: ->
    marker.destroy() for marker in @markers
    @markers = []
    @markerUses = {}

  _insertBoilerplate: ->

    # Indent the existing lines
    # XXX: Brittle solution, at some point should do pretty-printing
    for rowNumber in [0..@textEditor.getLastBufferRow()]
      @textEditor.setIndentationForBufferRow rowNumber, @programTemplate.mainIndentLevel

    # XXX: Manually correct columns that may have stated at 0 while indenting
    # was done.  There's gotta be a better solution.
    # Note that by doing this before we insert text, we also solve the problem
    # where, if one of the symbols appears at the very top left of the editor,
    # its marker range grows to include the starter boilerplate.  Score!
    for marker in @markers
      markerRange = marker.getBufferRange()
      if markerRange.start.column is 0
        markerRange.start.column = @programTemplate.mainIndentLevel * @textEditor.getTabLength()
        marker.setBufferRange markerRange

    # Add the starter boilerplate to the start of the example
    @textEditor.setTextInBufferRange(
      (new Range [0, 0], [0, 0]),
      @programTemplate.start
    )

    # Find the end of the file and add the ending boilerplate
    lastLine = @textEditor.getLastBufferRow()
    lastChar = (@textEditor.lineTextForBufferRow lastLine).length
    range = new Range [lastLine, lastChar], [lastLine, lastChar]
    @textEditor.setTextInBufferRange(
      range,
      @programTemplate.end
    )

  _addCodeLines: ->

    # Make a copy here, as sort mutates the array, and we don't want to observe
    # each of the sorting events (would cause infinite recursion)
    ranges = @model.getRangeSet().getActiveRanges().copy()
    rangesSorted = ranges.sort (a, b) => a.compare b

    rangeOffsets = []
    text = ""

    for range in rangesSorted
      # We store the offset of each active range within the editor so that
      # in the next step we can locate where the symbols have been moved,
      # so we can add markers and decorations
      rangeOffset = (text.split "\n").length - 1
      rangeText = @model.getCodeBuffer().getTextInRange range
      text += (rangeText + "\n")
      rangeOffsets.push [range, rangeOffset]

    @textEditor.setText text
    rangeOffsets

  # It's assumed that this is called before any boilerplate text and edits
  # (besides the active lines) have been added to the buffer
  _markSymbol: (use, rangeOffsets) ->

    symbolInActiveRange = false
    for activeRange in @model.getRangeSet().getActiveRanges()
      if activeRange.containsRange use.getRange()
        symbolInActiveRange = true
        filteredRangeOffsets = rangeOffsets.filter (element) =>
          activeRange.isEqual element[0]
        rangeOffset = filteredRangeOffsets[0]
        exampleRow = rangeOffset[1] +
          (use.getRange().start.row - activeRange.start.row)
    return if not symbolInActiveRange  # if use not in active ranges, skip it

    markerRange = new Range \
     [exampleRow, use.getRange().start.column],
     [exampleRow, use.getRange().end.column]
    marker = @textEditor.markBufferRange markerRange, { invalidate: "overlap" }
    @markers.push marker

    # We need to hold onto the use that each marker refers to.  We use
    # marker.id, using the recommendation of an error message that we
    # encountered when trying to set custom properties
    @markerUses[marker.id] = use

    marker

  _markErrors: (errors, rangeOffsets) ->
    for error in errors
      if error instanceof MissingDefinitionError
        marker = @_markSymbol error.getSymbol(), rangeOffsets
        marker.examplifyError = error
    @_addErrorDecorations()

  _addErrorDecorations: ->

    for marker in @markers

      error = marker.examplifyError

      # Add a button for highlighting the undefined use
      # I find it necessary to bind the use as data: when I don't do this,
      # use takes on the last value that it had in this loop
      decoration = $ "<div>Click to define</div>"
        .data 'error', error
        .click (event) =>
          use = ($ (event.target)).data 'error'
          @model.setErrorChoice error
      params =
        type: 'overlay'
        class: 'error-choice-button'
        item: decoration
        position: 'tail'
      @textEditor.decorateMarker marker, params

      # Then add highlighting to pinpoint the use
      params =
        type: 'highlight'
        class: 'error-choice-highlight'
      @textEditor.decorateMarker marker, params

  _addDefinitionWidget: (suggestions, rangeOffsets) ->

    # Make a marker for the target use
    errorChoice = @model.getErrorChoice()
    marker = @_markSymbol errorChoice.getSymbol(), rangeOffsets

    # Built up the interactive widget
    decoration = $ "<div></div>"
    originalText = @textEditor.getTextInBufferRange marker.getBufferRange()

    # Group suggestions by class
    suggestionClasses = []
    suggestionsByClass = {}
    for suggestion in suggestions
      class_ = suggestion.constructor.name
      suggestionClasses.push class_ if (class_ not in suggestionClasses)
      if class_ not of suggestionsByClass
        suggestionsByClass[class_] = []
      suggestionsByClass[class_].push suggestion

    for class_ in suggestionClasses
      suggestions = suggestionsByClass[class_]
      if class_ is "SymbolSuggestion"
        block = new SymbolSuggestionBlockView suggestions, @model, marker
      else if class_ is "PrimitiveValueSuggestion"
        block = new PrimitiveValueSuggestionBlockView suggestions, @model, marker
      decoration.append block

    _makeSuggestionOption = (suggestion, model) =>
      if suggestion instanceof SymbolSuggestion
        option = new SymbolSuggestionView suggestion, model
      else if suggestion instanceof PrimitiveValueSuggestion
        option = new PrimitiveValueSuggestionView suggestion, model, marker
      option

    # Create a decoration from the element
    params =
      type: "overlay"
      class: "resolution-widget"
      item: decoration
      position: "tail"
    @textEditor.decorateMarker marker, params
