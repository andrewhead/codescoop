$ = require 'jquery'
{ Range } = require 'atom'
{ LineSet, LineSetProperty } = require './line-set'


module.exports.ExampleModelProperty = ExampleModelProperty =
  UNKNOWN: { value: -1, name: "unknown" }
  LINES_CHANGED: { value: 0, name: "lines-changed" }
  UNDEFINED_USE_ADDED: { value: 1, name: "undefined-use-added" }
  STATE: { value: 2, name: "state" }


module.exports.ExampleModelState = ExampleModelState =
  VIEW: { value: 0, name: "view" }
  PICK_UNDEFINED: { value: 1, name: "pick-undefined" }


module.exports.ExampleModel = class ExampleModel

  observers: []
  state: ExampleModelState.VIEW

  ###
  lineNumbers are assumed to be 1-indexed, corresponding to the line
  numbers as they would appear in a text editor.
  ###
  constructor: (codeBuffer, lineSet, symbols) ->
    @lineSet = lineSet
    @lineSet.addObserver @
    @symbols = symbols
    @symbols.addObserver @
    @codeBuffer = codeBuffer

  onPropertyChanged: (object, propertyName, propertyValue) ->
    @notifyObservers object, propertyName, propertyValue

  addObserver: (observer) ->
    @observers.push observer

  notifyObservers: (object, propertyName, propertyValue) ->
    # For now, it's sufficient to bubble up the event
    if propertyName is LineSetProperty.ACTIVE_LINE_NUMBERS_CHANGED
      propertyName = ExampleModelProperty.LINES_CHANGED
    else if object is @symbols
      propertyName = ExampleModelProperty.UNDEFINED_USE_ADDED
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

  getLineSet: ->
    @lineSet

  getCodeBuffer: ->
    @codeBuffer

  getSymbols: ->
    @symbols


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
    @update()

  setChosenLines: (lineNumbers) ->
    @chosenLines = lineNumbers
    # sortedLines = @chosenLines.sort()
    # @lineTexts = ((@codeBuffer.lineForRow i) for i in sortedLines)
    @update()

  getTextEditor: () ->
    @textEditor

  onPropertyChanged: (object, propertyName, propertyValue) ->
    @_clearMarkers() if propertyName is ExampleModelProperty.STATE
    @update()

  _clearMarkers: ->
    marker.destroy() for marker in @markers

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
    lastChar = @textEditor.lineTextForBufferRow(lastLine).length
    range = new Range [lastLine, lastChar], [lastLine, lastChar]
    @textEditor.setTextInBufferRange(
      range,
      @programTemplate.end
    )

  _addCodeLines: ->
    # Make a copy here, as sort mutates the array, and we don't want to observe
    # each of the sorting events (would cause infinite recursion)
    lineNumbers = @model.getLineSet().getActiveLineNumbers().copy()
    lineNumbersSorted = lineNumbers.sort()
    # Remember that row numbers in the buffer are zero-indexed.  But
    # the line numbers we save are one-indexed, as they appear in the editor
    textLines = (
      (@model.getCodeBuffer().lineForRow (lineNumber - 1)) \
      for lineNumber in lineNumbersSorted)
    code = textLines.join "\n"
    @textEditor.setText code

  _addUndefinedUseMarkers: ->
    @_clearMarkers()
    lineNumbers = @model.getLineSet().getActiveLineNumbers()
    for use in @model.getSymbols().getUndefinedUses()
      exampleLineNumber = (lineNumbers.indexOf use.line)
      continue if exampleLineNumber is -1
      range = new Range [exampleLineNumber, use.start - 1], [exampleLineNumber, use.end - 1]
      marker = @textEditor.markBufferRange range, { invalidate: "overlap" }
      @markers.push marker

  update: ->
    # We add in the code, then add the markers, then the boilerplate.
    # By adding the code first, we get to use the character offsets of
    # each symbol to mark them, before inserting other boilerplate code
    @_addCodeLines()
    if @model.getState() is ExampleModelState.PICK_UNDEFINED
      @_addUndefinedUseMarkers()
    @_insertBoilerplate()
