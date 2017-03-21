$ = require "jquery"
{ ExampleModel, ExampleModelState, ExampleModelProperty } = require "./model/example-model"
{ Range, RangeSet } = require "./model/range-set"
{ Replacement } = require "./edit/replacement"
{ MissingDefinitionError } = require "./error/missing-definition"
{ MissingDeclarationError } = require "./error/missing-declaration"
{ SymbolSuggestionBlockView } = require "./view/symbol-suggestion"
{ PrimitiveValueSuggestionBlockView } = require "./view/primitive-value-suggestion"
{ DeclarationSuggestionBlockView } = require "./view/declaration-suggestion"
{ InstanceStubSuggestionBlockView } = require "./view/instance-stub-suggestion"
{ StubPrinter } = require "./view/stub-printer"
{ Point } = require "atom"


module.exports.ExampleView = class ExampleView

  programTemplate:
    mainStart: [
      "public static void main(String[] args) {"
      ""
    ].join "\n"
    mainEnd : [
      ""
      "}"
      ""
    ].join "\n"
    classStart: [
      "public class SmallScoop {"
      ""
      ""
    ].join "\n"
    classEnd: [
      ""
      "}"
    ].join "\n"
    indentLevel: 2 # 2 indents * 2 spaces / indent = 4 spaces

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
    # Currently, replacements can only be applied without updating if
    # the symbol was already marked in the last update.  If not, then
    # the replacement will be in the wrong place.
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
    @_surroundWithMain()
    @_addClassStubs()
    @_surroundWithClass()
    @_indentCode()

  _clearMarkers: ->
    symbolMarkerPair[1].destroy() for symbolMarkerPair in @symbolMarkerPairs
    rangeMarkerPair[1].destroy() for rangeMarkerPair in @activeRangeMarkerPairs
    @symbolMarkerPairs = []
    @activeRangeMarkerPairs = []

  _addCodeLines: ->

    # Make a copy here, as sort mutates the array, and we don"t want to observe
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
      # This is oddly neceesary to make sure the marker doesn"t keep moving
      # this range"s end further and futher out.
      exampleRange = new Range exampleRange.start, [
        exampleRange.end.row - 1,
        @textEditor.getBuffer().lineLengthForRow exampleRange.end.row - 1
      ]

      # Save a reference to a movable buffer range for the active range"s
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

  _addClassStubs: ->
    stubSpecs = @model.getStubSpecs()
    return if stubSpecs.length is 0
    stubsText = ""
    for stubSpec, i in stubSpecs
      stubPrinter = new StubPrinter()
      stubsText += (stubPrinter.printToString stubSpec, { static: true })
      if i is stubSpecs.length - 1
        stubsText += "\n"
    @textEditor.setTextInBufferRange (new Range [0, 0], [0, 0]), stubsText

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

      # Some marked symbols (e.g., those created when replacing the contents
      # of a symbol with an new value) aren't associated with an error.  Skip
      # over any symbol not associated with an error.
      continue if not error?

      label = "???"
      label = "Define" if error instanceof MissingDefinitionError
      label = "Declare" if error instanceof MissingDeclarationError

      # Add a button for highlighting the undefined use
      # I find it necessary to bind the use as data: when I don"t do this,
      # use takes on the last value that it had in this loop
      decoration = $ "<div></div>"
        .text label
        .data "error", error
        .click (event) =>
          error = ($ (event.target)).data "error"
          @model.setErrorChoice error
      params =
        type: "overlay"
        class: "error-choice-button"
        item: decoration
        position: "tail"
      @textEditor.decorateMarker marker, params

      # Then add highlighting to pinpoint the use
      params =
        type: "highlight"
        class: "error-choice-highlight"
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

  _resetIndentation: ->
    ###
    for rowNumber in [0..@textEditor.getLastBufferRow()]
      @textEditor.setIndentationForBufferRow
    ###

  _indentAllLines: ->
    ###
    # Indent the existing lines
    # XXX: Brittle solution, at some point should do pretty-printing
    for rowNumber in [0..@textEditor.getLastBufferRow()]
      currentIndentation = @textEditor.indentationForBufferRow rowNumber
      @textEditor.setIndentationForBufferRow rowNumber,
        currentIndentation + @programTemplate.indentLevel
    ###

  _surroundCurrentText: (textBefore, textAfter) ->

    # Add text at the start of the file
    @textEditor.setTextInBufferRange (new Range [0, 0], [0, 0]), textBefore

    # Find the end of the buffer, and add text at the end
    lastLine = @textEditor.getLastBufferRow()
    lastChar = (@textEditor.lineTextForBufferRow lastLine).length
    range = new Range [lastLine, lastChar], [lastLine, lastChar]
    @textEditor.setTextInBufferRange range, textAfter

  _surroundWithMain: ->
    @_surroundCurrentText @programTemplate.mainStart, @programTemplate.mainEnd

  _surroundWithClass: ->
    @_surroundCurrentText @programTemplate.classStart, @programTemplate.classEnd

  _indentCode: ->

    # Auto-indent the code using the editor's grammar
    @textEditor.selectAll()
    selection = @textEditor.getLastSelection()
    @textEditor.autoIndentSelectedRows()
    selection.clear()

    # XXX: Manually correct columns for markers that started at 0 before
    # indenting, and mistakenly, preserved 0.
    # This works, but maybe there's got to be a better solution.
    for rangeMarkerPair in @symbolMarkerPairs
      marker = rangeMarkerPair[1]
      markerRange = marker.getBufferRange()
      if markerRange.start.column is 0
        markerRange.start.column = (
          (@textEditor.indentationForBufferRow markerRange.start.row) *
          @programTemplate.indentLevel)
        marker.setBufferRange markerRange

  getSymbolMarkers: ->
    (symbolMarkerPair[1] for symbolMarkerPair in @symbolMarkerPairs)
