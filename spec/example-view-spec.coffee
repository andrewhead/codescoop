{ ExampleView } = require '../lib/example-view'
{ ExampleModel, ExampleModelState, ExampleModelProperty } = require '../lib/model/example-model'
{ makeObservableArray } = require '../lib/example-view'
{ File, Symbol, SymbolSet } = require '../lib/model/symbol-set'
{ Range, RangeSet } = require '../lib/model/range-set'
{ ValueMap } = require '../lib/analysis/value-analysis'
{ MissingDefinitionError } = require '../lib/error/missing-definition'
{ SymbolSuggestion, PrimitiveValueSuggestion } = require '../lib/suggestor/suggestion'
{ Replacement } = require '../lib/edit/replacement'
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


describe "ExampleModel", ->

  observer =
    onPropertyChanged: (object, name, value) ->
      @object = object
      @propertyName = name
      @propertyValue = value

  parseTree = jasmine.createSpyObj "parseTree", [ "getRoot" ]

  it "notifies observers when lines changed", ->
    rangeSet = new RangeSet()
    exampleModel = new ExampleModel codeBuffer, rangeSet, new SymbolSet(), parseTree, new ValueMap()
    exampleModel.addObserver observer
    rangeSet.getActiveRanges().push new Range [0, 0], [0, 10]
    (expect observer.propertyName).toBe ExampleModelProperty.ACTIVE_RANGES
    (expect observer.propertyValue).toEqual [ new Range [0, 0], [0, 10] ]

  it "notifies observers when the list of undefined symbols changes", ->
    symbols = new SymbolSet()
    exampleModel = new ExampleModel codeBuffer, new RangeSet(), symbols, parseTree, new ValueMap()
    exampleModel.addObserver observer
    symbols.addUndefinedUse { name: "sym", line: 1, start: 5, end: 6 }
    (expect observer.propertyName).toBe ExampleModelProperty.UNDEFINED_USES
    (expect observer.propertyValue).toEqual { name: "sym", line: 1, start: 5, end: 6 }


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
    (expect markers.length).toBe 2

    # The marked range will be different from original symbol position, due to
    # filtering to active lines and pretty-printing
    markerBufferRange = markers[0].getBufferRange()
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
      (expect buttonDecorations[0].getMarker()).toBe markers[0]
      (expect highlightDecorations[0].getMarker()).toBe markers[0]

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
    (expect view.getTextEditor().getMarkers().length).toBe 1
    model.setState ExampleModelState.IDLE
    (expect view.getTextEditor().getMarkers().length).toBe 0

  describe "when the state is set to RESOLUTION", ->

    symbolSet = new SymbolSet()
    valueMap = new ValueMap()
    _.extend valueMap, {
      'Example.java':
        1: { i: '0' }
        2: { i: '0', j: '0' }
        3: { i: '1', j: '0' }
    }
    symbolSet.setDefinition new Symbol "Example.java", "j", new Range [1, 4], [1, 5]
    model = new ExampleModel codeBuffer,
      (new RangeSet [ new Range [2, 0], [2, 10] ]),
      symbolSet, parseTree, valueMap
    view = new ExampleView model, makeEditor()

    # By setting a chosen error, a set of suggestions, and the model state
    # to RESOLUTION, a decoration should be added for resolving the symbol
    model.setErrorChoice new MissingDefinitionError \
      new Symbol TEST_FILE, "j", new Range [2, 4], [2, 5]
    model.setSuggestions [
      new SymbolSuggestion new Symbol TEST_FILE, "j", new Range [1, 4], [1, 5]
      new PrimitiveValueSuggestion "1"
      new PrimitiveValueSuggestion "0"
    ]
    model.setState ExampleModelState.RESOLUTION

    it "adds a marker for resolving the error", ->
      editor = view.getTextEditor()
      markers = editor.getMarkers()
      (expect markers.length).toBe 1
      markerBufferRange = markers[0].getBufferRange()
      (expect markerBufferRange).toEqual new Range [4, 12], [4, 13]

    describe "creates a new widget such that", ->

      editor = view.getTextEditor()
      decorations = editor.getDecorations { class: 'resolution-widget' }
      decoration = decorations[0]
      markers = editor.getMarkers()

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

      it "highlights suggested lines for symbol suggestions on mouse over", ->

        codeBlock = $ (($ domElement).find 'div.resolution-class-block')[0]
        codeHeader = codeBlock.find 'div.resolution-class-header'
        codeHeader.mouseover()
        codeSuggestion = $ (codeBlock.find 'div.suggestion')[0]

        # Simulate the mouse entering and exiting the suggestion button
        suggestedRanges = model.getRangeSet().getSuggestedRanges()
        (expect suggestedRanges.length).toBe 0
        codeSuggestion.mouseover()
        codeHeader.mouseout()
        (expect suggestedRanges.length).toBe 1
        (expect suggestedRanges[0]).toEqual new Range [1, 4], [1, 5]
        codeBlock.mouseout()
        (expect suggestedRanges.length).toBe 0

      it "chooses a resolution when the resolution is clicked", ->

        codeBlock = $ (($ domElement).find 'div.resolution-class-block')[0]
        codeHeader = codeBlock.find 'div.resolution-class-header'
        codeHeader.mouseover()
        codeSuggestion = $ (codeBlock.find 'div.suggestion')[0]
        codeSuggestion.mouseover()
        codeHeader.mouseout()

        (expect model.getResolutionChoice()).toBe null
        codeSuggestion.click()
        resolutionChoice = model.getResolutionChoice()
        (expect resolutionChoice instanceof SymbolSuggestion).toBe true

      it "previews values when the mouse enters the primitive suggestion button", ->

        valueBlock = $ (($ domElement).find 'div.resolution-class-block')[1]
        valueHeader = valueBlock.find 'div.resolution-class-header'
        valueHeader.mouseover()
        valueHeader.mouseout()
        valueSuggestion = $ (valueBlock.find 'div.suggestion')[0]
        valueSuggestion.mouseover()

        (expect model.getEdits().length).toBe 1
        edit = model.getEdits()[0]
        (expect edit instanceof Replacement)
        (expect edit.getRange(), new Range [1, 4], [1, 5])
        (expect edit.getText(), "1")

        valueSuggestion.mouseout()
        (expect model.getEdits().length).toBe 0
