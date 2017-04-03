{ ExampleModel, ExampleModelState, ExampleModelProperty } = require "../model/example-model"
{ Range, RangeSet } = require "../model/range-set"
{ Point } = require "atom"
{ Replacement } = require "../edit/replacement"
{ StubPrinter } = require "../view/stub-printer"
$ = require "jquery"

{ MissingDeclarationError } = require "../error/missing-declaration"
{ MissingDefinitionError } = require "../error/missing-definition"
{ MissingMethodDefinitionError } = require "../error/missing-method-definition"
{ MissingTypeDefinitionError } = require "../error/missing-type-definition"
{ ControlStructureExtension } = require "../extender/control-structure-extender"
{ MediatingUseExtension } = require "../extender/mediating-use-extender"
{ MethodThrowsExtension } = require "../extender/method-throws-extender"

{ DefinitionSuggestionBlockView } = require "../view/symbol-suggestion"
{ PrimitiveValueSuggestionBlockView } = require "../view/primitive-value-suggestion"
{ DeclarationSuggestionBlockView } = require "../view/declaration-suggestion"
{ InstanceStubSuggestionBlockView } = require "../view/instance-stub-suggestion"
{ ImportSuggestionBlockView } = require "../view/import-suggestion"
{ InnerClassSuggestionBlockView } = require "../view/inner-class-suggestion"
{ LocalMethodSuggestionBlockView } = require "../view/local-method-suggestion"
{ ControlStructureExtensionView } = require "../view/control-structure-extension"
{ MediatingUseExtensionView } = require "../view/mediating-use-extension"
{ MethodThrowsExtensionView } = require "../view/method-throws-extension"


module.exports.ExampleView = class ExampleView

  programTemplate:
    mainStart: [
      "public static void main(String[] args) <throwsClause>{"
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
    @extraRangeMarkerPairs = []
    @activeRangeMarkerPairs = []
    @editMarkerPairs = []
    @update()

  getTextEditor: () ->
    @textEditor

  onPropertyChanged: (object, propertyName, oldValue, newValue) ->
    @update() if propertyName in [
      ExampleModelProperty.STATE
      ExampleModelProperty.AUXILIARY_DECLARATIONS
    ]
    if (propertyName is ExampleModelProperty.ACTIVE_RANGES) and
        (newValue.length > oldValue.length)
      @update()
    if (propertyName is ExampleModelProperty.EDITS)
      if (newValue.length > oldValue.length)
        @_applyReplacements()
      else if (newValue.length < oldValue.length)
        deletedReplacements = oldValue.filter (replacement) =>
          replacement not in newValue
        (@_revertReplacement replacement) for replacement in deletedReplacements

  update: ->

    # Remove any markers that were on the code before
    @_clearMarkers()

    # Add in the code!  We do this before we add markers to any of it.
    # One of the most important steps is to mark this code as it's
    # added, so we can locate errors in their new, relative positions in the
    # example editor, instead of using their positions in the original code.
    @_addCodeLines()
    @_addAuxiliaryDeclarations()
    @_applyReplacements()
    @_surroundWithMain()
    @_addClassStubs()
    @_addLocalMethods()
    @_addInnerClasses()

    # Add user interface that marks up the code and accepts user input
    if @model.getState() is ExampleModelState.ERROR_CHOICE
      @_markErrors @model.getErrors()
    else if @model.getState() is ExampleModelState.RESOLUTION
      @_addResolutionWidget @model.getSuggestions()
    else if @model.getState() is ExampleModelState.EXTENSION
      @_addExtensionWidget @model.getProposedExtension()

    # Finish up the code with more boilerplace, imports, and pretty-printing
    @_surroundWithClass()
    @_addImports()
    @_indentCode()

  _clearMarkers: ->
    rangeMarkerPair[1].destroy() for rangeMarkerPair in @extraRangeMarkerPairs
    rangeMarkerPair[1].destroy() for rangeMarkerPair in @activeRangeMarkerPairs
    for editMarkerPair in @editMarkerPairs
      markerFromSymbol = editMarkerPair[2]
      editMarkerPair[1].destroy() if not markerFromSymbol
    @extraRangeMarkerPairs = []
    @activeRangeMarkerPairs = []
    @editMarkerPairs = []

  _addCodeLines: ->

    # Make a copy here, as sort mutates the array, and we don"t want to observe
    # each of the sorting events (would cause infinite recursion)
    ranges = @model.getRangeSet().getSnippetRanges().copy()
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

  _addTextAtEndOfBuffer: (text) =>
    # Find the end of the buffer, and add text at the end
    lastLine = @textEditor.getLastBufferRow()
    lastChar = (@textEditor.lineTextForBufferRow lastLine).length
    range = new Range [lastLine, lastChar], [lastLine, lastChar]
    return @textEditor.setTextInBufferRange range, text

  # Follows the same process as @_addInnerClasses.  See that method for
  # more annotations of the procedure in this method.
  _addLocalMethods: ->
    methodRanges = @model.getRangeSet().getMethodRanges()
    @_addTextAtEndOfBuffer "\n" if methodRanges.length > 0

    for methodRange, i in methodRanges

      rangeInCode = methodRange.getRange()
      declaration = @model.getCodeBuffer().getTextInRange rangeInCode
      if not methodRange.isStatic()
        declaration = declaration.replace /(\w+\s+\w+\s*\()/, "static $1"
      declarationRange = @_addTextAtEndOfBuffer declaration

      marker = @textEditor.markBufferRange declarationRange
      @activeRangeMarkerPairs.push [rangeInCode, marker]

      @_addTextAtEndOfBuffer "\n"
      if i isnt methodRanges.length - 1
        @_addTextAtEndOfBuffer "\n"

  _addInnerClasses: ->

    classRanges = @model.getRangeSet().getClassRanges()
    @_addTextAtEndOfBuffer "\n" if classRanges.length > 0

    # For each class, print its declaration to file
    for classRange, i in classRanges

      # Get the original class declaration from the code editor.
      # If it wasn't defined as a static class, we redefine it as one.
      rangeInCode = classRange.getRange()
      declaration = @model.getCodeBuffer().getTextInRange rangeInCode
      if not classRange.isStatic()
        declaration = declaration.replace /\bclass\b/, "static class"
      declarationRange = @_addTextAtEndOfBuffer declaration

      # Mark the range of this declaration, so we can annotate it with
      # errors and resolutions at some later time.
      marker = @textEditor.markBufferRange declarationRange
      @activeRangeMarkerPairs.push [rangeInCode, marker]

      # White space between class declarations
      @_addTextAtEndOfBuffer "\n"
      if i isnt classRanges.length - 1
        @_addTextAtEndOfBuffer "\n"

  # Find the location that an active range from the code view maps to in
  # the example view.  There are two steps:
  # 1. Find this range's position relative to an active range that has
  #    already been included in the example
  # 2. Make corrections based on which parts of that range have been
  #    altered by edits (like replacements)
  _getAdjustedRange: (range) ->

    # Find the active range that contains the range.  Both the range passed in
    # and the active ranges here are in terms of coordinates in the original
    # source code.  We do the mapping to example editor coordinates later.
    rangeInActiveRange = false
    for rangeMarkerPair in @activeRangeMarkerPairs
      activeRange = rangeMarkerPair[0]
      if activeRange.containsRange range
        rangeInActiveRange = true
        marker = rangeMarkerPair[1]
        markerRange = marker.getBufferRange()
        break

    # If we can't find the range in one of the included ranges, skip it.
    return null if not rangeInActiveRange

    # Determine range size.
    width = range.end.column - range.start.column
    height = range.end.row - range.start.row

    # Step 2.  If there are no replacements in this range, we're almost done!
    # If there are replacements in this range, we want to adjust the position
    # of the range relative to the end of the last replacement before the
    # range.  Find this range before this one, and adjust offset.
    # XXX: Replacement adjustments only work when all replacements are on
    # the same line and none have newlines.
    replacementBeforeRange = undefined
    @model.getEdits().forEach (edit) =>
      if (edit instanceof Replacement)
        replacement = edit
        replacementRange = edit.getSymbol().getRange()
        if (activeRange.containsRange replacementRange) and
            ((replacementRange.compare range) is -1) and
            (replacementRange.start.row is range.start.row)
          if not replacementBeforeRange?
            replacementBeforeRange = replacement
          else if (replacementRange.compare replacementRange) is -1
            replacementBeforeRange = replacement

    if replacementBeforeRange?

      priorRange = replacementBeforeRange.getSymbol().getRange()
      columnsAfterReplacement = range.start.column - priorRange.end.column

      # Find out how many characters the prior replacement added / subtracted
      priorRangeOriginalWidth = priorRange.end.column - priorRange.start.column
      priorRangeNewText = replacementBeforeRange.getText()
      replacementWidthDelta = priorRangeNewText.length - priorRangeOriginalWidth

      # Recursively look of the position of the replacement range, in case it
      # might be offset by some replacement before it.
      adjustedPriorRange = @_getAdjustedRange priorRange

      # Create a new range relative to the prior replacement
      adjustedStartColumn = adjustedPriorRange.end.column +
        columnsAfterReplacement + replacementWidthDelta
      nextRange = new Range [
        adjustedPriorRange.end.row,
        adjustedStartColumn,
      ], [
        adjustedPriorRange.end.row + height,
        adjustedStartColumn + width
      ]
      return nextRange

    # If there were no replacements before this, just return the offset of
    # this range relative to its active range's position in the example editor.
    else

      startColumn = undefined
      if range.start.row is activeRange.start.row
        columnOffset = range.start.column - activeRange.start.column
        startColumn = markerRange.start.column + columnOffset
      else
        startColumn = range.start.column

      rowOffset = range.start.row - activeRange.start.row
      adjustedRange = new Range [
          markerRange.start.row + rowOffset
          startColumn
        ], [
          markerRange.start.row + rowOffset + height
          startColumn + width
        ]
      return adjustedRange

  # It's assumed that this is called before any boilerplate text and edits
  # (besides the active lines) have been added to the buffer
  _markRange: (range) ->
    adjustedRange = @_getAdjustedRange range
    return if not adjustedRange?
    marker = @textEditor.markBufferRange adjustedRange, { invalidate: "overlap" }
    @extraRangeMarkerPairs.push [range, marker]
    marker

  _markErrors: (errors) ->
    for error in errors
      marker = @_markRange error.getSymbol().getRange()
      marker.examplifyError = error
    @_addErrorDecorations()

  _addErrorDecorations: ->

    for rangeMarkerPair in @extraRangeMarkerPairs

      marker = rangeMarkerPair[1]
      error = marker.examplifyError

      # Some marked symbols (e.g., those created when replacing the contents
      # of a symbol with an new value) aren't associated with an error.  Skip
      # over any symbol not associated with an error.
      continue if not error?

      label = "???"
      label = "Define" if error instanceof MissingDefinitionError
      label = "Define" if error instanceof MissingTypeDefinitionError
      label = "Define" if error instanceof MissingMethodDefinitionError
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
    marker = @_markRange errorChoice.getSymbol().getRange()

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
      if class_ is "DefinitionSuggestion"
        block = new DefinitionSuggestionBlockView suggestions, @model, marker
      else if class_ is "PrimitiveValueSuggestion"
        block = new PrimitiveValueSuggestionBlockView suggestions, @model, marker
      else if class_ is "DeclarationSuggestion"
        block = new DeclarationSuggestionBlockView suggestions, @model, marker
      else if class_ is "InstanceStubSuggestion"
        block = new InstanceStubSuggestionBlockView suggestions, @model, marker
      else if class_ is "LocalMethodSuggestion"
        block = new LocalMethodSuggestionBlockView suggestions, @model, marker
      else if class_ is "ImportSuggestion"
        block = new ImportSuggestionBlockView suggestions, @model, marker
      else if class_ is "InnerClassSuggestion"
        block = new InnerClassSuggestionBlockView suggestions, @model, marker
      decoration.append block

    # Create a decoration from the element
    params =
      type: "overlay"
      class: "resolution-widget"
      item: decoration
      position: "tail"
    @textEditor.decorateMarker marker, params

    params =
      type: "highlight"
      class: "resolution-highlight"
    @textEditor.decorateMarker marker, params

  _addExtensionWidget: (extension) ->

    # Make a marker for the range inside the control structure
    marker = undefined

    # Built up the interactive widget
    decoration = undefined
    if extension instanceof ControlStructureExtension
      rangeInsideControl = extension.getEvent().getInsideRange()
      marker = @_markRange rangeInsideControl
      decoration = new ControlStructureExtensionView extension, @model
    else if extension instanceof MediatingUseExtension
      marker = @_markRange extension.getUse().getRange()
      decoration = new MediatingUseExtensionView extension, @model
    else if extension instanceof MethodThrowsExtension
      marker = @_markRange extension.getInnerRange()
      decoration = new MethodThrowsExtensionView extension, @model

    # Create a decoration for deciding whether to accept the extension
    params =
      type: "overlay"
      class: "extension-widget"
      item: decoration
      position: "tail"
    @textEditor.decorateMarker marker, params

    # Highlight the range that the extension is augmenting
    params =
      type: "highlight"
      class: "extension-highlight"
    @textEditor.decorateMarker marker, params

  _revertReplacement: (replacement) ->

    for editMarkerPair, i in @editMarkerPairs

      # Find the marker that corresponds to the edit
      edit = editMarkerPair[0]
      marker = editMarkerPair[1]
      isMarkerFromSymbol = editMarkerPair[2]
      if edit is replacement

        # Revert the text to the original text
        @textEditor.setTextInBufferRange marker.getBufferRange(),
          edit.getSymbol().getName()

        # Cleanup: destroy the marker for the edit
        if not isMarkerFromSymbol
          marker.destroy()
        @editMarkerPairs.splice i, 1
        break

  _applyReplacements: ->

    # Sort the edits from first to last as they appear in the original code.
    # This should ensure that when we're resolving we resolve offsets for
    # later edits, they take into account the offset changes from performing
    # the earlier edits.
    edits = @model.getEdits().copy().sort (edit1, edit2) =>
      edit1.getSymbol().getRange().compare edit2.getSymbol().getRange()

    # Recall the edits that have been made in the past.  Don't add any edits
    # a second time if they were already marked
    savedEdits = (editMarkerPair[0] for editMarkerPair in @editMarkerPairs)

    for edit in edits

      continue if edit in savedEdits
      continue if edit not instanceof Replacement

      # Look if the range for the symbol was already marked.  If so,
      # just reuse that symbol.
      symbol = edit.getSymbol()
      foundSymbol = false
      for rangeMarkerPair in @extraRangeMarkerPairs
        continue if not rangeMarkerPair[0].isEqual symbol.getRange()
        foundSymbol = true
        marker = rangeMarkerPair[1]

      # Otherwise, we need to mark the range for the first time.
      if not foundSymbol
        marker = @_markRange symbol.getRange()

      # Replace the text in the range with the replacement text
      if marker?
        @textEditor.setTextInBufferRange marker.getBufferRange(), edit.getText()
        @editMarkerPairs.push [ edit, marker, foundSymbol ]

  _surroundCurrentText: (textBefore, textAfter) ->

    # Add text at the start of the file
    @textEditor.setTextInBufferRange (new Range [0, 0], [0, 0]), textBefore

    # Find the end of the buffer, and add text at the end
    lastLine = @textEditor.getLastBufferRow()
    lastChar = (@textEditor.lineTextForBufferRow lastLine).length
    range = new Range [lastLine, lastChar], [lastLine, lastChar]
    @textEditor.setTextInBufferRange range, textAfter

  _surroundWithMain: ->
    throwablesText = ''
    if @model.getThrows().length >= 1
      throwablesText = "throws " + (@model.getThrows().join ", ") + " "
    mainStart = @programTemplate.mainStart.replace \
      /<throwsClause>/, throwablesText
    @_surroundCurrentText mainStart, @programTemplate.mainEnd

  _surroundWithClass: ->
    @_surroundCurrentText @programTemplate.classStart, @programTemplate.classEnd

  _addImports: ->

    imports = @model.getImports()
    return if imports.length is 0

    # Format an import statement for each of the imports
    importsString = ""
    for import_ in imports
      importsString += "import #{import_.getName()};\n"
    importsString += "\n"

    # Set the text at the very start of the buffer to the import strings
    @textEditor.setTextInBufferRange (new Range [0, 0], [0, 0]), importsString

  _indentCode: ->

    # Auto-indent the code using the editor's grammar
    @textEditor.selectAll()
    selection = @textEditor.getLastSelection()
    @textEditor.autoIndentSelectedRows()
    selection.clear()

    # XXX: Manually correct columns for markers that started at 0 before
    # indenting, and mistakenly, preserved 0.
    # This works, but maybe there's got to be a better solution.
    for rangeMarkerPair in @extraRangeMarkerPairs
      marker = rangeMarkerPair[1]
      markerRange = marker.getBufferRange()
      if markerRange.start.column is 0
        markerRange.start.column = (
          (@textEditor.indentationForBufferRow markerRange.start.row) *
          @programTemplate.indentLevel)
        marker.setBufferRange markerRange

  getExtraRangeMarkers: ->
    (rangeMarkerPair[1] for rangeMarkerPair in @extraRangeMarkerPairs)
