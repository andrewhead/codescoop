$ = require 'jquery'
{ Range, RangeSet, RangeSetProperty } = require './range-set'


module.exports.ExampleModelProperty = ExampleModelProperty =
  UNKNOWN: { value: -1, name: "unknown" }
  ACTIVE_RANGES: { value: 0, name: "lines-changed" }
  UNDEFINED_USES: { value: 1, name: "undefined-use-added" }
  STATE: { value: 2, name: "state" }
  TARGET: { value: 3, name: "target "}
  VALUE_MAP: { value: 4, name: "value-map" }


module.exports.ExampleModelState = ExampleModelState =
  VIEW: { value: 0, name: "view" }
  PICK_UNDEFINED: { value: 1, name: "pick-undefined" }
  DEFINE: { value: 2, name: "define" }


module.exports.ExampleModel = class ExampleModel

  ###
  lineNumbers are assumed to be 1-indexed, corresponding to the line
  numbers as they would appear in a text editor.
  ###
  constructor: (codeBuffer, rangeSet, symbols, valueMap) ->
    @observers = []
    @codeBuffer = codeBuffer
    @rangeSet = rangeSet
    @rangeSet.addObserver @
    @symbols = symbols
    @symbols.addObserver @
    @valueMap = valueMap
    @state = ExampleModelState.VIEW

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

  setTarget: (symbol) ->
    @target = symbol
    @notifyObservers this, ExampleModelProperty.TARGET, @target

  getTarget: ->
    @target

  getValueMap: ->
    @valueMap

  setValueMap: (valueMap) ->
    @valueMap = valueMap
    @notifyObservers this, ExampleModelProperty.VALUE_MAP, @valueMap


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
      ExampleModelProperty.UNDEFINED_USES
      ExampleModelProperty.ACTIVE_RANGES
    ]

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
  _markUse: (use, rangeOffsets) ->

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

  _addUndefinedUseMarkers: (rangeOffsets) ->
    for use in @model.getSymbols().getUndefinedUses()
      @_markUse use, rangeOffsets

  _addUndefinedUseDecorations: ->
    for marker in @markers

      use = @markerUses[marker.id]

      # Add a button for highlighting the undefined use
      # I find it necessary to bind the use as data: when I don't do this,
      # use takes on the last value that it had in this loop
      decoration = $ "<div>Click to define</div>"
        .data 'use', use
        .click (event) =>
          use = ($ (event.target)).data 'use'
          @model.setTarget use
      params =
        type: 'overlay'
        class: 'undefined-use-button'
        item: decoration
        position: 'tail'
      @textEditor.decorateMarker marker, params

      # Then add highlighting to pinpoint the use
      params =
        type: 'highlight'
        class: 'undefined-use-highlight'
      @textEditor.decorateMarker marker, params

  _addDefinitionWidget: (rangeOffsets) ->

    # Make a marker for the target use
    targetUse = @model.getTarget()
    marker = @_markUse targetUse, rangeOffsets

    # Built up the interactive widget
    decoration = $ "<div></div>"
    originalText = @textEditor.getTextInBufferRange marker.getBufferRange()
    # XXX: This lookup uses the start row of the use, but what it should
    # really do is get the line that is invoked by the debugger when this
    # symbol is called, which might not be the same thing
    valueText = @model.getValueMap()[targetUse.file][targetUse.getRange().start.row][targetUse.name]
    setValueButton = $ "<div>Add Data</div>"
    if valueText?
      setValueButton
        .attr "id", "set-value-button"
        .addClass "definition-method-button"
        .mouseover (event) =>
          # XXX: Because an update may have clobbered the marker that
          # this decoration was initially attached to, when a click occurs,
          # we just find the only marker that is stored in this view.  It
          # should be the definition marker, as there's only one.
          marker = @markers[0]
          @textEditor.setTextInBufferRange marker.getBufferRange(), valueText
        .mouseout (event) =>
          marker = @markers[0]
          @textEditor.setTextInBufferRange marker.getBufferRange(), originalText
    else
      setValueButton.addClass 'disabled'
    decoration.append setValueButton

    addCodeButton = $ "<div>Add Code</div>"
      .attr "id", "add-code-button"
      .addClass "definition-method-button"
      .mouseover (event) =>
        def = @model.getSymbols().getDefinition()
        @model.getRangeSet().setSuggestedRanges [def.getRange()]
      .mouseout (event) =>
        def = @model.getSymbols().getDefinition()
        @model.getRangeSet().removeSuggestedRange def.getRange()
      .click (event) =>
        def = @model.getSymbols().getDefinition()
        @model.getRangeSet().removeSuggestedRange def.getRange()
        # XXX: For now, we get the range of the first line of the def.
        # In the future, we'll want to just get the relevant part
        # of the statement and not the whole line.
        @model.getRangeSet().getActiveRanges().push \
          @model.getCodeBuffer().rangeForRow def.getRange().start.row
    decoration.append addCodeButton

    # Create a decoration from the element
    params =
      type: "overlay"
      class: "definition-widget"
      item: decoration
      position: "tail"
    @textEditor.decorateMarker marker, params

  update: ->
    @_clearMarkers()
    # We add in the code, then add the markers, then the boilerplate.
    # By adding the code first, we get to use the character offsets of
    # each symbol to mark them, before inserting other boilerplate code
    activeRangeOffsets = @_addCodeLines()
    if @model.getState() is ExampleModelState.PICK_UNDEFINED
      @_addUndefinedUseMarkers activeRangeOffsets
      @_addUndefinedUseDecorations()
    else if @model.getState() is ExampleModelState.DEFINE
      @_addDefinitionWidget activeRangeOffsets
    @_insertBoilerplate()
