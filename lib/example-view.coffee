$ = require 'jquery'
{ ExampleModel, ExampleModelState, ExampleModelProperty } = require './model/example-model'
{ Range, RangeSet } = require './model/range-set'
{ Replacement } = require './edit/replacement'
{ MissingDefinitionError } = require './error/missing-definition'
{ MissingDeclarationError } = require "./error/missing-declaration"
{ SymbolSuggestion, PrimitiveValueSuggestion } = require './suggester/suggestion'
{ SymbolSuggestionBlockView } = require "./view/symbol-suggestion"
{ PrimitiveValueSuggestionBlockView } = require "./view/primitive-value-suggestion"
{ DeclarationSuggestionBlockView } = require "./view/declaration-suggestion"
{ InstanceStubSuggestionBlockView } = require "./view/instance-stub-suggestion"
{ Point } = require 'atom'


module.exports.ExampleView = class ExampleView

  programTemplate:
    start: [
      "public class SmallScoop {"
      ""
      "    public static void main(String[] args) {"
      ""
    ].join '\n'
    end: [
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
    @symbolMarkerPairs = []
    @activeRangeMarkerPairs = []
    @update()

  getTextEditor: () ->
    @textEditor

  onPropertyChanged: (object, propertyName, propertyValue) ->
    @update() if propertyName in [
      ExampleModelProperty.STATE
      ExampleModelProperty.ACTIVE_RANGES
      ExampleModelProperty.AUXILIARY_DECLARATIONS
    ]
    @_applyReplacements() if propertyName in [
      ExampleModelProperty.EDITS
    ]

  update: ->
    @_clearMarkers()
    # We add in the code, then add the markers, then the boilerplate.
    # By adding the code first, we get to use the character offsets of
    # each symbol to mark them, before inserting other boilerplate code
    @_addCodeLines()
    @_addAuxiliaryDeclarations()
    @_applyReplacements()
    if @model.getState() is ExampleModelState.ERROR_CHOICE
      @_markErrors @model.getErrors()
    else if @model.getState() is ExampleModelState.RESOLUTION
      @_addResolutionWidget @model.getSuggestions()
    @_insertBoilerplate()

  _clearMarkers: ->
    symbolMarkerPair[1].destroy() for symbolMarkerPair in @symbolMarkerPairs
    rangeMarkerPair[1].destroy() for rangeMarkerPair in @activeRangeMarkerPairs
    @symbolMarkerPairs = []
    @activeRangeMarkerPairs = []

  _addCodeLines: ->

    # Make a copy here, as sort mutates the array, and we don't want to observe
    # each of the sorting events (would cause infinite recursion)
    ranges = @model.getRangeSet().getActiveRanges().copy()
    rangesSorted = ranges.sort (a, b) => a.compare b

    @textEditor.setText "\n"
    nextInsertionPoint = new Point 1, 0

    for range in rangesSorted

      # We store the offset of each active range within the editor so that
      # in the next step we can locate where the symbols have been moved,
      # so we can add markers and decorations
      endRange = new Range nextInsertionPoint, nextInsertionPoint
      codeText = @model.getCodeBuffer().getTextInRange range
      exampleRange = @textEditor.setTextInBufferRange endRange, codeText + "\n"
      nextInsertionPoint = exampleRange.end

      # Step back over the newline when getting the range in the example.
      # This is oddly neceesary to make sure the marker doesn't keep moving
      # this range's end further and futher out.
      exampleRange = new Range exampleRange.start, [
        exampleRange.end.row - 1,
        @textEditor.getBuffer().lineLengthForRow exampleRange.end.row - 1
      ]

      # Save a reference to a movable buffer range for the active range's
      # position within the example code.
      marker = @textEditor.markBufferRange exampleRange
      @activeRangeMarkerPairs.push [range, marker]

  _addAuxiliaryDeclarations: ->
    declarations = @model.getAuxiliaryDeclarations()
    return if declarations.length is 0
    declarationText = "\n"
    for declaration in declarations
      declarationText +=
        (declaration.getType() + " " + declaration.getName() + ";\n")
    @textEditor.setTextInBufferRange \
      (new Range [0, 0], [0, 0]), declarationText

  _getAdjustedSymbolRange: (symbol, rangeMarkers) ->

    # Find the active range that contains the symbol
    symbolInActiveRange = false
    for rangeMarkerPair in @activeRangeMarkerPairs
      activeRange = rangeMarkerPair[0]
      if activeRange.containsRange symbol.getRange()
        symbolInActiveRange = true
        marker = rangeMarkerPair[1]
        markerRange = marker.getBufferRange()
        break

    return null if not symbolInActiveRange  # if use not in active ranges, skip it

    symbolRange = symbol.getRange()
    columnOffset = symbolRange.start.column - activeRange.start.column
    rowOffset = symbolRange.start.row - activeRange.start.row
    width = symbolRange.end.column - symbolRange.start.column
    height = symbolRange.end.row - symbolRange.start.row
    adjustedRange = new Range [
        markerRange.start.row + rowOffset
        markerRange.start.column + columnOffset
      ], [
        markerRange.start.row + rowOffset + height
        markerRange.start.column + columnOffset + width
      ]
    adjustedRange

  # It's assumed that this is called before any boilerplate text and edits
  # (besides the active lines) have been added to the buffer
  _markSymbol: (symbol) ->
    adjustedRange = @_getAdjustedSymbolRange symbol
    return if not adjustedRange?
    marker = @textEditor.markBufferRange adjustedRange, { invalidate: "overlap" }
    @symbolMarkerPairs.push [symbol, marker]
    marker

  _markErrors: (errors) ->
    for error in errors
      marker = @_markSymbol error.getSymbol()
      marker.examplifyError = error
    @_addErrorDecorations()

  _addErrorDecorations: ->

    for symbolMarkerPair in @symbolMarkerPairs

      marker = symbolMarkerPair[1]
      error = marker.examplifyError

      label = "ResolveError"
      label = "Click to define" if error instanceof MissingDefinitionError
      label = "Click to declare" if error instanceof MissingDeclarationError

      # Add a button for highlighting the undefined use
      # I find it necessary to bind the use as data: when I don't do this,
      # use takes on the last value that it had in this loop
      decoration = $ "<div></div>"
        .text label
        .data 'error', error
        .click (event) =>
          error = ($ (event.target)).data 'error'
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

  _addResolutionWidget: (suggestions) ->

    # Make a marker for the target use
    errorChoice = @model.getErrorChoice()
    marker = @_markSymbol errorChoice.getSymbol()

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
      else if class_ is "DeclarationSuggestion"
        block = new DeclarationSuggestionBlockView suggestions, @model, marker
      else if class_ is "InstanceStubSuggestion"
        block = new InstanceStubSuggestionBlockView suggestions, @model, marker
      decoration.append block

    # Create a decoration from the element
    params =
      type: "overlay"
      class: "resolution-widget"
      item: decoration
      position: "tail"
    @textEditor.decorateMarker marker, params

  _applyReplacements: ->

    for edit in @model.getEdits()
      continue if edit not instanceof Replacement
      symbol = edit.getSymbol()

      foundSymbol = false
      for symbolMarkerPair in @symbolMarkerPairs
        continue if not symbolMarkerPair[0].equals symbol
        foundSymbol = true
        marker = symbolMarkerPair[1]

      # The first time we find the symbol (presumably before any
      # replacements have been performed), mark it and save a reference
      # to the marker, for later replacements.
      if not foundSymbol
        adjustedRange = @_getAdjustedSymbolRange symbol
        marker = @_markSymbol symbol

      @textEditor.setTextInBufferRange marker.getBufferRange(), edit.getText()

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
    for rangeMarkerPair in @activeRangeMarkerPairs
      marker = rangeMarkerPair[1]
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

  getSymbolMarkers: ->
    (symbolMarkerPair[1] for symbolMarkerPair in @symbolMarkerPairs)
