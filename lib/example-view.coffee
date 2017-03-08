$ = require 'jquery'
{ makeObservableArray } = require './model/observable-array'
{ Range, RangeSet, RangeSetProperty } = require './model/range-set'
{ MissingDefinitionError } = require './error/missing-definition'
{ SymbolSuggestion, PrimitiveValueSuggestion } = require './suggestor/suggestion'
{ SymbolSuggestionView } = require "./view/symbol-suggestion"
{ PrimitiveValueSuggestionView } = require "./view/primitive-value-suggestion"


module.exports.ExampleModelProperty = ExampleModelProperty =
  UNKNOWN: { value: -1, name: "unknown" }
  ACTIVE_RANGES: { value: 0, name: "lines-changed" }
  UNDEFINED_USES: { value: 1, name: "undefined-use-added" }
  STATE: { value: 2, name: "state" }
  ERROR_CHOICE: { value: 3, name: "error-choice"}
  RESOLUTION_CHOICE: { value: 4, name: "resolution-choice" }
  VALUE_MAP: { value: 5, name: "value-map" }
  ERRORS: { value: 6, name: "errors" }
  SUGGESTIONS: { value: 7, name: "suggestions" }


module.exports.ExampleModelState = ExampleModelState =
  ANALYSIS: { value: 0, name: "analysis" }
  IDLE: { value: 1, name: "idle" }
  ERROR_CHOICE: { value: 2, name: "error-choice" }
  RESOLUTION: { value: 3, name: "resolution" }


module.exports.ExampleModel = class ExampleModel

  constructor: (codeBuffer, rangeSet, symbols, parseTree, valueMap) ->

    @observers = []

    @rangeSet = rangeSet
    @rangeSet.addObserver @

    @symbols = symbols
    @symbols.addObserver @

    @errors = makeObservableArray []
    @errors.addObserver @

    @suggestions = makeObservableArray []
    @suggestions.addObserver @

    @edits = makeObservableArray []
    @edits.addObserver @

    @codeBuffer = codeBuffer
    @parseTree = parseTree
    @valueMap = valueMap
    @errorChoice = null
    @resolutionChoice = null

    @state = ExampleModelState.ANALYSIS

  onPropertyChanged: (object, propertyName, propertyValue) ->
    @notifyObservers object, propertyName, propertyValue

  addObserver: (observer) ->
    @observers.push observer

  notifyObservers: (object, propertyName, propertyValue) ->
    # For now, it's sufficient to bubble up the event
    if propertyName is RangeSetProperty.ACTIVE_RANGES_CHANGED
      propertyName = ExampleModelProperty.ACTIVE_RANGES
    else if object is @symbols
      propertyName = ExampleModelProperty.UNDEFINED_USES
    else if object is @
      proprtyName = propertyName
    else
      propertyName = ExampleModelProperty.UNKNOWN
    for observer in @observers
      observer.onPropertyChanged this, propertyName, propertyValue

  setState: (state) ->
    @state = state
    @notifyObservers this, ExampleModelProperty.STATE, @state

  getState: ->
    @state

  getRangeSet: ->
    @rangeSet

  getCodeBuffer: ->
    @codeBuffer

  getSymbols: ->
    @symbols

  setErrorChoice: (error) ->
    @errorChoice = error
    @notifyObservers @, ExampleModelProperty.ERROR_CHOICE, @errorChoice

  getErrorChoice: ->
    @errorChoice

  setResolutionChoice: (resolution) ->
    @resolutionChoice = resolution
    @notifyObservers @, ExampleModelProperty.RESOLUTION_CHOICE, @resolutionChoice

  getResolutionChoice: ->
    @resolutionChoice

  getValueMap: ->
    @valueMap

  setValueMap: (valueMap) ->
    @valueMap = valueMap
    @notifyObservers @, ExampleModelProperty.VALUE_MAP, @valueMap

  setErrors: (errors) ->
    @errors.reset errors
    @notifyObservers @, ExampleModelProperty.ERRORS, @errors

  getErrors: ->
    @errors

  getParseTree: ->
    @parseTree

  setSuggestions: (suggestions) ->
    @suggestions.reset suggestions

  getSuggestions: ->
    @suggestions

  getEdits: ->
    @edits


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

    # Get names of all suggestion classes
    suggestionClasses = []
    suggestionsByClass = {}
    for suggestion in suggestions

      # Start making a list of all types of suggestions
      class_ = suggestion.constructor.name
      suggestionClasses.push class_ if (class_ not in suggestionClasses)

      # Group suggestions by class
      if class_ not of suggestionsByClass
        suggestionsByClass[class_] = []
      suggestionsByClass[class_].push suggestion

    _textForClass = (className) =>
      return "Set value" if className is "PrimitiveValueSuggestion"
      return "Add code" if className is "SymbolSuggestion"

    # Add a UI element for each class of suggestion
    classHeaders = {}
    for class_ in suggestionClasses
      classBlock = $ "<div></div>"
        .addClass "resolution-class-block"
        .mouseout (event) =>
          block = ($ event.target)
          # Propagate mouseout to suggestions and remove suggestions
          (block.find 'div.suggestion').each ->
            ($ @).mouseout()
            ($ @).remove()
      classHeader = $ "<div></div>"
        .addClass "resolution-class-header"
        .text _textForClass class_
        .data "suggestions", suggestionsByClass[class_]
        .data "block", classBlock
        .data "class", class_
      classBlock.append classHeader
      decoration.append classBlock
      classHeaders[class_] = classHeader

    _textForSuggestion = (suggestion) =>
      if suggestion instanceof SymbolSuggestion
        return "L" + suggestion.getSymbol().getRange().start.row
      else if suggestion instanceof PrimitiveValueSuggestion
        return suggestion.getValueString()

    _makeSuggestionOption = (suggestion, model) =>
      if suggestion instanceof SymbolSuggestion
        option = new SymbolSuggestionView suggestion, model
      else if suggestion instanceof PrimitiveValueSuggestion
        option = new PrimitiveValueSuggestionView suggestion, model, marker
      option

    # For each suggestion, add another block when hovering over the header
    for class_, header of classHeaders
      header.mouseover (event) =>
        target = ($ event.target)
        block = target.data "block"
        for suggestion in target.data "suggestions"
          option = _makeSuggestionOption suggestion, @model
          block.append option

    # Create a decoration from the element
    params =
      type: "overlay"
      class: "resolution-widget"
      item: decoration
      position: "tail"
    @textEditor.decorateMarker marker, params
