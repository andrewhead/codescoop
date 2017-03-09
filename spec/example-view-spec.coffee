{ ExampleView } = require '../lib/example-view'
{ ExampleModel, ExampleModelState, ExampleModelProperty } = require '../lib/model/example-model'
{ makeObservableArray } = require '../lib/example-view'
{ File, Symbol, SymbolSet } = require '../lib/model/symbol-set'
{ Range, RangeSet } = require '../lib/model/range-set'
{ ValueMap } = require '../lib/analysis/value-analysis'
{ MissingDefinitionError } = require '../lib/error/missing-definition'
{ SymbolSuggestion, PrimitiveValueSuggestion } = require '../lib/suggester/suggestion'
{ Replacement } = require '../lib/edit/replacement'
{ Declaration } = require "../lib/edit/declaration"
$ = require 'jquery'
_ = require 'lodash'


makeEditor = -> atom.workspace.buildTextEditor()

editor = makeEditor()
editor.setText [
  "int i = 0;"
  "int j = i;"
  "i = j + 1;"
  "j = j + 1;"
  ].join '\n'
codeBuffer = editor.getBuffer()
TEST_FILE = new File "fake/path", "FakeClass.java"


describe "ExampleView", ->

  parseTree = jasmine.createSpyObj "parseTree", [ "getRoot" ]

  it "shows text for the lines in the model's list", ->
    model = new ExampleModel codeBuffer,
      (new RangeSet [ (new Range [0, 0], [0, 10]), new Range [1, 0], [1, 10] ]),
      new SymbolSet(), parseTree, new ValueMap()
    view = new ExampleView model, makeEditor(), codeBuffer
    exampleText = view.getTextEditor().getText()
    expect(exampleText.indexOf "int i = 0;").not.toBe -1
    expect(exampleText.indexOf "int j = i;").not.toBe -1
    expect(exampleText.indexOf "i = j + 1;").toBe -1
    expect(exampleText.indexOf "j = j + 1;").toBe -1

  it "updates text display when the list of lines changes", ->

    rangeSet = new RangeSet [ (new Range [0, 0], [0, 10]), new Range [1, 0], [1, 10] ]
    model = new ExampleModel codeBuffer, rangeSet, new SymbolSet(), parseTree, new ValueMap()
    view = new ExampleView model, makeEditor()

    # Remove first line from the list
    rangeSet.getActiveRanges().splice 0, 1

    # Add another line index to the list
    rangeSet.getActiveRanges().push new Range [2, 0], [2, 10]

    exampleText = view.getTextEditor().getText()
    expect(exampleText.indexOf "int i = 0;").toBe -1
    expect(exampleText.indexOf "int j = i;").not.toBe -1
    expect(exampleText.indexOf "i = j + 1;").not.toBe -1
    expect(exampleText.indexOf "j = j + 1;").toBe -1

  it "updates text when declarations added", ->
    model = new ExampleModel codeBuffer,
      (new RangeSet [ (new Range [0, 0], [0, 10]), new Range [1, 0], [1, 10] ]),
      new SymbolSet(), parseTree, new ValueMap()
    view = new ExampleView model, makeEditor(), codeBuffer
    model.getAuxiliaryDeclarations().push new Declaration "k", "int"
    exampleText = view.getTextEditor().getText()
    (expect exampleText.indexOf "int k;").not.toBe -1
    (expect (exampleText.indexOf "int k;") < (exampleText.indexOf "int i = 0;")).toBe true

  it "applies replacement edits by changing the text immediately", ->

    rangeSet = new RangeSet [
      (new Range [0, 0], [0, 10]),
      new Range [1, 0], [1, 10]
    ]
    model = new ExampleModel codeBuffer, rangeSet, new SymbolSet(),
      parseTree, new ValueMap()
    editor = makeEditor()
    view = new ExampleView model, editor

    symbol = new Symbol TEST_FILE, "i", new Range [1, 8], [1, 9]
    model.getEdits().push new Replacement symbol, "42"
    exampleText = view.getTextEditor().getText()
    expect(exampleText.indexOf "int j = 42;").not.toBe -1

  it "marks up symbols with errors in ERROR_CHOICE mode", ->

    symbolSet = new SymbolSet()

    model = new ExampleModel codeBuffer,
      (new RangeSet [ new Range [2, 0], [3, 10] ] ),
      symbolSet, parseTree, new ValueMap()
    view = new ExampleView model, makeEditor()

    model.setErrors [
      (new MissingDefinitionError new Symbol TEST_FILE, "j", new Range [2, 4], [2, 5])
      (new MissingDefinitionError new Symbol TEST_FILE, "j", new Range [3, 4], [3, 5])
    ]
    model.setState ExampleModelState.ERROR_CHOICE

    editor = view.getTextEditor()
    markers = editor.getMarkers()
    (expect markers.length).toBe 3

    # The marked range will be different from original symbol position, due to
    # filtering to active lines and pretty-printing.  (The first marker is
    # to keep track of the active ranges; the second and third are markers
    # on each of the error choices.)
    markerBufferRange = markers[1].getBufferRange()
    (expect markerBufferRange).toEqual new Range [4, 12], [4, 13]
    (expect editor.getTextInBufferRange(markerBufferRange)).toBe "j"

  describe "after marking up a symbol", ->

    symbolSet = new SymbolSet()
    model = new ExampleModel codeBuffer,
      (new RangeSet [ new Range [2, 0], [2, 10] ]),
      symbolSet, parseTree, new ValueMap()
    view = new ExampleView model, makeEditor()

    model.setErrors [
      (new MissingDefinitionError new Symbol TEST_FILE, "j", new Range [2, 4], [2, 5])
    ]
    model.setState ExampleModelState.ERROR_CHOICE

    editor = view.getTextEditor()
    buttonDecorations = editor.getDecorations { class: 'error-choice-button' }
    highlightDecorations = editor.getDecorations { class: 'error-choice-highlight' }
    markers = editor.getMarkers()

    it "decorates the symbol", ->
      # Make sure that the decoration is associated with the marker created
      (expect buttonDecorations.length).toBe 1
      (expect highlightDecorations.length).toBe 1
      (expect buttonDecorations[0].getMarker()).toBe markers[1]
      (expect highlightDecorations[0].getMarker()).toBe markers[1]

    it "updates the target when the decoration is clicked", ->
      domElement = $ (buttonDecorations[0].getProperties()).item
      domElement.click()
      errorChoice = model.getErrorChoice()
      (expect errorChoice instanceof MissingDefinitionError).toBe true
      (expect errorChoice.getSymbol()).toEqual \
        new Symbol TEST_FILE, "j", new Range [2, 4], [2, 5]

  it "doesn't highlight symbols with errors when it's in IDLE mode", ->

    symbolSet = new SymbolSet()
    model = new ExampleModel codeBuffer,
      (new RangeSet [ new Range [2, 0], [2, 10] ]),
      symbolSet, parseTree, new ValueMap()
    view = new ExampleView model, makeEditor()

    model.setErrors [
      (new MissingDefinitionError new Symbol TEST_FILE, "j", new Range [2, 4], [2, 5])
    ]
    model.setState ExampleModelState.ERROR_CHOICE

    # Only show markers when we're picking from undefined uses
    model.setState ExampleModelState.ERROR_CHOICE
    (expect view.getTextEditor().getDecorations(
      { class: 'error-choice-highlight' }).length).toBe 1
    model.setState ExampleModelState.IDLE
    (expect view.getTextEditor().getDecorations(
      { class: 'error-choice-highlight' }).length).toBe 0

  describe "when the state is set to RESOLUTION", ->

    symbolSet = new SymbolSet()
    valueMap = new ValueMap()
    _.extend valueMap, {
      'Example.java':
        1: { i: '0' }
        2: { i: '0', j: '0' }
        3: { i: '1', j: '0' }
    }
    model = new ExampleModel codeBuffer,
      (new RangeSet [ new Range [2, 0], [2, 10] ]),
      symbolSet, parseTree, valueMap
    view = new ExampleView model, makeEditor()

    # By setting a chosen error, a set of suggestions, and the model state
    # to RESOLUTION, a decoration should be added for resolving the symbol
    useSymbol = new Symbol TEST_FILE, "j", new Range [2, 4], [2, 5]
    defSymbol = new Symbol TEST_FILE, "j", new Range [1, 4], [1, 5]
    model.setErrorChoice new MissingDefinitionError \
      new Symbol TEST_FILE, "j", new Range [2, 4], [2, 5]
    model.setSuggestions [
      new SymbolSuggestion defSymbol
      new PrimitiveValueSuggestion useSymbol, "1"
      new PrimitiveValueSuggestion useSymbol, "0"
    ]
    model.setState ExampleModelState.RESOLUTION

    it "adds a marker for resolving the error", ->
      markers = view.getSymbolMarkers()
      (expect markers.length).toBe 1
      markerBufferRange = markers[0].getBufferRange()
      (expect markerBufferRange).toEqual new Range [4, 12], [4, 13]

    describe "creates a new widget such that", ->

      editor = view.getTextEditor()
      decorations = editor.getDecorations { class: 'resolution-widget' }
      decoration = decorations[0]
      markers = view.getSymbolMarkers()

      it "corresponds to the new marker", ->
        (expect decorations.length).toBe 1
        (expect decoration.getMarker()).toBe markers[0]

      domElement = $ decoration.getProperties().item

      it "has a header for each class of suggestion", ->
        headers = ($ domElement).find 'div.resolution-class-header'
        (expect headers.length).toBe 2
        (expect ($ headers[0]).text()).toEqual "Add code"
        (expect ($ headers[1]).text()).toEqual "Set value"

      it "shows suggestions when the mouse enters the header for a class, " +
         "and hides them when the mouse leaves the block", ->

        # Default: no suggestions
        valueBlock = $ (($ domElement).find 'div.resolution-class-block')[1]
        suggestions = valueBlock.find 'div.suggestion'
        (expect suggestions.length).toBe 0

        # When mousing over the header, show the suggestions
        valueHeader = valueBlock.find 'div.resolution-class-header'
        valueHeader.mouseover()
        suggestions = valueBlock.find 'div.suggestion'
        (expect suggestions.length).toBe 2
        (expect ($ suggestions[0]).text()).toEqual "1"

        # When moving the mouse out of the block, hide the suggestions
        valueBlock.mouseout()
        suggestions = valueBlock.find 'div.suggestion'
        (expect suggestions.length).toBe 0

      # XXX: For the three tests below, we do not simulate the mouse leaving
      # header on the way to the suggestion, as this forces a mouseleave
      # event for the suggestion block as a whole.  While it's unrealistic
      # to leave out this event, it causes the test cases to fail when it
      # is left back in, even though it is handled correctly during interaction.
      it "chooses a resolution when the resolution is clicked", ->

        codeBlock = $ (($ domElement).find 'div.resolution-class-block')[0]
        codeHeader = codeBlock.find 'div.resolution-class-header'
        codeHeader.mouseover()
        codeSuggestion = $ (codeBlock.find 'div.suggestion')[0]
        codeSuggestion.mouseover()

        (expect model.getResolutionChoice()).toBe null
        codeSuggestion.click()
        resolutionChoice = model.getResolutionChoice()
        (expect resolutionChoice instanceof SymbolSuggestion).toBe true
        codeBlock.mouseleave()

      it "highlights suggested lines for symbol suggestions on mouse over", ->

        codeBlock = $ (($ domElement).find 'div.resolution-class-block')[0]
        codeHeader = codeBlock.find 'div.resolution-class-header'
        codeHeader.mouseover()
        codeSuggestion = $ (codeBlock.find 'div.suggestion')[0]

        # Simulate the mouse entering and exiting the suggestion button
        suggestedRanges = model.getRangeSet().getSuggestedRanges()
        (expect suggestedRanges.length).toBe 0
        codeSuggestion.mouseover()
        (expect suggestedRanges.length).toBe 1
        (expect suggestedRanges[0]).toEqual new Range [1, 4], [1, 5]
        codeBlock.mouseleave()
        (expect suggestedRanges.length).toBe 0

      it "previews values when the mouse enters the primitive suggestion button", ->

        valueBlock = $ (($ domElement).find 'div.resolution-class-block')[1]
        valueHeader = valueBlock.find 'div.resolution-class-header'
        valueHeader.mouseover()
        valueSuggestion = $ (valueBlock.find 'div.suggestion')[0]
        valueSuggestion.mouseover()

        (expect model.getEdits().length).toBe 1
        edit = model.getEdits()[0]
        (expect edit instanceof Replacement)
        (expect edit.getSymbol().getRange(), new Range [1, 4], [1, 5])
        (expect edit.getText(), "1")

        valueSuggestion.mouseout()
        (expect model.getEdits()[0].getText(), "i")
        valueBlock.mouseleave()
