{ ExampleView } = require "../../lib/view/example-view"
{ ExampleModel, ExampleModelState, ExampleModelProperty } = require "../../lib/model/example-model"
{ File, Symbol, SymbolSet } = require "../../lib/model/symbol-set"
{ Range, RangeSet } = require "../../lib/model/range-set"
{ ValueMap } = require "../../lib/analysis/value-analysis"
{ StubSpec } = require "../../lib/model/stub"
{ Import } = require "../../lib/model/import"
{ MissingDefinitionError } = require "../../lib/error/missing-definition"
{ SymbolSuggestion } = require "../../lib/suggester/definition-suggester"
{ PrimitiveValueSuggestion } = require "../../lib/suggester/primitive-value-suggester"
{ ControlStructureExtension } = require "../../lib/extender/control-structure-extender"
{ ControlCrossingEvent } = require "../../lib/event/control-crossing"
{ Replacement } = require "../../lib/edit/replacement"
{ Declaration } = require "../../lib/edit/declaration"
{ PACKAGE_PATH } = require "../../lib/config/paths"
$ = require "jquery"
_ = require "lodash"


codeEditor = atom.workspace.buildTextEditor()
codeEditor.setText [
    "public class FakeClass {"
    "  public static void main(String[] args) {"
    "    int i = 0;"
    "    int j = i;"
    "    i = j + 1;"
    "    j = j + i;"
    "  }"
    "}"
  ].join '\n'
CODE_BUFFER = codeEditor.getBuffer()
TEST_FILE = new File "fake/path", "FakeClass.java"
PARSE_TREE = jasmine.createSpyObj "PARSE_TREE", [ "getRoot" ]


describe "ExampleView", ->

  editor = undefined
  model = undefined
  view = undefined

  beforeEach =>

    editor = atom.workspace.buildTextEditor()
    editor.setGrammar atom.grammars.loadGrammarSync \
      PACKAGE_PATH + "/spec/view/java.json"

    model = new ExampleModel CODE_BUFFER,
      (new RangeSet [ (new Range [2, 4], [2, 14]), new Range [3, 4], [3, 14] ]),
      new SymbolSet(), PARSE_TREE
    view = new ExampleView model, editor

    waitsForPromise =>
      # Package needed for auto-indenting Java code
      atom.packages.activatePackage('language-java')

  it "shows text for the lines in the model's list", ->
    exampleText = view.getTextEditor().getText()
    expect(exampleText.indexOf "int i = 0;").not.toBe -1
    expect(exampleText.indexOf "int j = i;").not.toBe -1
    expect(exampleText.indexOf "i = j + 1;").toBe -1
    expect(exampleText.indexOf "j = j + 1;").toBe -1

  it "updates text display when the list of lines changes", ->

    # Remove first line from the list
    rangeSet = model.getRangeSet()
    rangeSet.getActiveRanges().splice 0, 1

    # Add another line index to the list
    rangeSet.getActiveRanges().push new Range [4, 4], [4, 14]

    exampleText = view.getTextEditor().getText()
    expect(exampleText.indexOf "int i = 0;").toBe -1
    expect(exampleText.indexOf "int j = i;").not.toBe -1
    expect(exampleText.indexOf "i = j + 1;").not.toBe -1
    expect(exampleText.indexOf "j = j + 1;").toBe -1

  it "updates text when declarations added", ->
    model.getAuxiliaryDeclarations().push new Declaration "k", "int"
    exampleText = view.getTextEditor().getText()
    (expect exampleText.indexOf "int k;").not.toBe -1
    (expect (exampleText.indexOf "int k;") < (exampleText.indexOf "int i = 0;")).toBe true

  it "adds stubs when rendering the text", ->
    model.getStubSpecs().push new StubSpec "Book"
    view = new ExampleView model, editor
    exampleText = view.getTextEditor().getText()
    (expect exampleText.indexOf [
        "  private static class Book {"
        "  }"
      ].join "\n").not.toBe -1

  it "adds imports when rendering the text", ->
    model.getImports().push new Import "org.Book", new Range [0, 7], [0, 15]
    view = new ExampleView model, editor
    exampleText = view.getTextEditor().getText()
    (expect exampleText.startsWith "import org.Book;\n").toBe true

  it "marks up symbols with errors in ERROR_CHOICE mode", ->
    model.getRangeSet().getActiveRanges().reset [ new Range [4, 4], [5, 14] ]
    model.setErrors [
      (new MissingDefinitionError new Symbol TEST_FILE, "j", new Range [4, 8], [4, 9])
      (new MissingDefinitionError new Symbol TEST_FILE, "j", new Range [5, 8], [5, 9])
    ]
    model.setState ExampleModelState.ERROR_CHOICE

    # The marked range will be different from original symbol position, due to
    # filtering to active lines and pretty-printing.  (The first marker is
    # to keep track of the active ranges; the second and third are markers
    # on each of the error choices.)
    markers = editor.getMarkers()
    (expect markers.length).toBe 3
    markerBufferRange = markers[1].getBufferRange()
    (expect markerBufferRange).toEqual new Range [4, 8], [4, 9]
    (expect editor.getTextInBufferRange(markerBufferRange)).toBe "j"

  it "supports replacements on symbols marked with errors", ->
    model.getRangeSet().getActiveRanges().reset [ new Range [4, 0], [5, 14] ]
    undefinedSymbol = new Symbol TEST_FILE, "i", new Range [5, 12], [5, 13]
    model.setErrors [ new MissingDefinitionError undefinedSymbol ]
    model.setState ExampleModelState.ERROR_CHOICE
    model.getEdits().push new Replacement undefinedSymbol, "42"
    exampleText = view.getTextEditor().getText()
    expect(exampleText.indexOf "j = j + 42;").not.toBe -1

  describe "after marking up a symbol", ->

    editor = undefined
    model = undefined
    view = undefined
    buttonDecorations = undefined
    highlightDecorations = undefined
    markers = undefined

    beforeEach =>

      editor = atom.workspace.buildTextEditor()
      editor.setGrammar atom.grammars.loadGrammarSync \
        PACKAGE_PATH + "/spec/view/java.json"

      model = new ExampleModel CODE_BUFFER,
        (new RangeSet [ (new Range [4, 4], [4, 14]) ]),
        new SymbolSet(), PARSE_TREE
      view = new ExampleView model, editor
      model.setErrors [
        (new MissingDefinitionError new Symbol TEST_FILE, "j", new Range [4, 8], [4, 9])
      ]
      model.setState ExampleModelState.ERROR_CHOICE

      buttonDecorations = editor.getDecorations { class: 'error-choice-button' }
      highlightDecorations = editor.getDecorations { class: 'error-choice-highlight' }
      markers = editor.getMarkers()

      waitsForPromise =>
        # Package needed for auto-indenting Java code
        atom.packages.activatePackage('language-java')

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
        new Symbol TEST_FILE, "j", new Range [4, 8], [4, 9]

    it "doesn't highlight symbols with errors when it's in IDLE mode", ->
      # Only show markers when we're picking from undefined uses
      (expect view.getTextEditor().getDecorations(
        { class: 'error-choice-highlight' }).length).toBe 1
      model.setState ExampleModelState.IDLE
      (expect view.getTextEditor().getDecorations(
        { class: 'error-choice-highlight' }).length).toBe 0

  describe "when the state is set to RESOLUTION, there's a widget such that", ->

    editor = undefined
    model = undefined
    view = undefined
    decorations = undefined
    markers = undefined
    decoration = undefined
    domElement = undefined

    beforeEach =>

      waitsForPromise => atom.packages.activatePackage('language-java')

      editor = atom.workspace.buildTextEditor()
      editor.setGrammar atom.grammars.loadGrammarSync \
        PACKAGE_PATH + "/spec/view/java.json"

      model = new ExampleModel CODE_BUFFER,
        (new RangeSet [ (new Range [4, 4], [4, 14]) ]),
        new SymbolSet(), PARSE_TREE
      valueMap = new ValueMap()
      _.extend valueMap, {
        'Example.java':
          3: { i: '0' }
          4: { i: '0', j: '0' }
          5: { i: '1', j: '0' }
      }
      model.setValueMap valueMap

      view = new ExampleView model, editor

      # By setting a chosen error, a set of suggestions, and the model state
      # to RESOLUTION, a decoration should be added for resolving the symbol
      useSymbol = new Symbol TEST_FILE, "j", new Range [4, 8], [4, 9]
      defSymbol = new Symbol TEST_FILE, "j", new Range [5, 8], [5, 9]
      model.setErrorChoice new MissingDefinitionError \
        new Symbol TEST_FILE, "j", new Range [4, 8], [4, 9]
      model.setSuggestions [
        new SymbolSuggestion defSymbol
        new PrimitiveValueSuggestion useSymbol, "1"
        new PrimitiveValueSuggestion useSymbol, "0"
      ]
      model.setState ExampleModelState.RESOLUTION

      # Make a bunch of helper variables that we can easily test
      decorations = editor.getDecorations { class: 'resolution-widget' }
      decoration = decorations[0]
      markers = view.getExtraRangeMarkers()
      domElement = $ decoration.getProperties().item

    it "has a marker for resolving the error", ->

      markers = view.getExtraRangeMarkers()
      (expect markers.length).toBe 1
      markerBufferRange = markers[0].getBufferRange()
      (expect markerBufferRange).toEqual new Range [4, 8], [4, 9]

    it "corresponds to the new marker", ->
      (expect decorations.length).toBe 1
      (expect decoration.getMarker()).toBe markers[0]

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
      (expect suggestedRanges[0]).toEqual new Range [5, 8], [5, 9]
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
      (expect edit.getSymbol().getRange(), new Range [3, 8], [3, 9])
      (expect edit.getText(), "1")

      valueSuggestion.mouseout()
      (expect model.getEdits()[0].getText(), "i")
      valueBlock.mouseleave()

  describe "when in the EXTENSION state", ->

    decorations = undefined

    beforeEach =>

      editor = atom.workspace.buildTextEditor()
      editor.setGrammar atom.grammars.loadGrammarSync \
        PACKAGE_PATH + "/spec/view/java.json"

      model = new ExampleModel CODE_BUFFER,
        (new RangeSet [ (new Range [4, 4], [4, 14]) ]),
        new SymbolSet(), PARSE_TREE
      view = new ExampleView model, editor

      # This is a convoluted, non-existent control structure given the
      # example code for this test (in this case, it just correspondes to the
      # lines right above and below).  But it's good enough to test the
      # logic of the example view.  We leave all of the variables undefined
      # that shouldn't be needed by the example view, for brevity
      extension = new ControlStructureExtension undefined,
        [(new Range [3, 4], [3, 14]), new Range [5, 4], [5, 14]],
        new ControlCrossingEvent undefined, new Range [4, 4], [4, 14], undefined
      model.setProposedExtension extension
      model.setState ExampleModelState.EXTENSION
      decorations = editor.getDecorations { class: 'extension-highlight' }

      waitsForPromise =>
        # Package needed for auto-indenting Java code
        atom.packages.activatePackage('language-java')

    it "highlights the line contained in the control structure", ->
      (expect decorations.length).toBe 1
      (expect decorations[0].getMarker().getBufferRange()).toEqual \
        new Range [4, 4], [4, 14]
