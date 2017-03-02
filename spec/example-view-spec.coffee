{ ExampleView } = require '../lib/example-view'
{ ExampleModel, ExampleModelState, ExampleModelProperty } = require '../lib/example-view'
{ makeObservableArray } = require '../lib/example-view'
{ SymbolSet } = require '../lib/symbol-set'
{ LineSet } = require '../lib/line-set'
{ Range } = require 'atom'


makeEditor = -> atom.workspace.buildTextEditor()

editor = makeEditor()
editor.setText [
  "Line 1"
  "Line 2"
  "Line 3"
  "Line 4"
  ].join '\n'
codeBuffer = editor.getBuffer()


describe "ExampleModel", ->

  observer =
    onPropertyChanged: (object, name, value) ->
      @object = object
      @propertyName = name
      @propertyValue = value

  it "notifies observers when lines changed", ->
    lineSet = new LineSet()
    exampleModel = new ExampleModel codeBuffer, lineSet, new SymbolSet()
    exampleModel.addObserver observer
    lineSet.getActiveLineNumbers().push 1
    (expect observer.propertyName).toBe ExampleModelProperty.LINES_CHANGED
    (expect observer.propertyValue).toEqual [1]

  it "notifies observers when the list of undefined symbols changes", ->
    symbols = new SymbolSet()
    exampleModel = new ExampleModel codeBuffer, new LineSet(), symbols
    exampleModel.addObserver observer
    symbols.addUndefinedUse { name: "sym", line: 1, start: 5, end: 6 }
    (expect observer.propertyName).toBe ExampleModelProperty.UNDEFINED_USE_ADDED
    (expect observer.propertyValue).toEqual { name: "sym", line: 1, start: 5, end: 6 }


describe "ExampleView", ->

  it "shows text for the lines in the model's list", ->
    model = new ExampleModel codeBuffer, new LineSet([1, 2]), new SymbolSet()
    view = new ExampleView model, makeEditor(), codeBuffer
    exampleText = view.getTextEditor().getText()
    expect(exampleText.indexOf "Line 1").not.toBe -1
    expect(exampleText.indexOf "Line 2").not.toBe -1
    expect(exampleText.indexOf "Line 3").toBe -1
    expect(exampleText.indexOf "Line 4").toBe -1

  it "updates text display when the list of lines changes", ->

    lineSet = new LineSet [1, 2]
    model = new ExampleModel codeBuffer, lineSet, new SymbolSet()
    view = new ExampleView model, makeEditor()

    # Remove first line from the list
    lineSet.getActiveLineNumbers().splice 0, 1

    # Add another line index to the list
    lineSet.getActiveLineNumbers().push 3

    exampleText = view.getTextEditor().getText()
    expect(exampleText.indexOf "Line 1").toBe -1
    expect(exampleText.indexOf "Line 2").not.toBe -1
    expect(exampleText.indexOf "Line 3").not.toBe -1
    expect(exampleText.indexOf "Line 4").toBe -1

  it "focuses undefined symbols in PICK_UNDEFINED mode", ->

    symbolSet = new SymbolSet()

    model = new ExampleModel codeBuffer, new LineSet([1]), symbolSet
    view = new ExampleView model, makeEditor()
    model.setState ExampleModelState.PICK_UNDEFINED
    symbolSet.addUndefinedUse { name: "Line", line: 1, start: 1, end: 5 }

    editor = view.getTextEditor()
    markers = editor.getMarkers()
    (expect markers.length).toBe 1

    # Note that the range that's marked is going to be different from the
    # original symbol position, as its position in the new editor will
    # be different from its position in the old code buffer, due to
    # pretty-printing and modifications to the code
    markerBufferRange = markers[0].getBufferRange()
    (expect markerBufferRange).toEqual new Range [4, 8], [4, 12]

    # As a sanity check, the text at this location should be the symbol name
    (expect editor.getTextInBufferRange(markerBufferRange)).toBe "Line"

  it "skips focusing on undefined symbols not in the range of chosen lines", ->

    # This time, the undefined use appears on a line that's not within view.
    # We shouldn't add any marks for the symbol.
    symbolSet = new SymbolSet()
    symbolSet.addUndefinedUse {name: "Line", line: 2, start: 1, end: 5 }

    model = new ExampleModel codeBuffer, new LineSet([1]), symbolSet
    view = new ExampleView model, makeEditor()
    markers = view.getTextEditor().getMarkers()
    (expect markers.length).toBe 0

  it "skips focusing on undefined symbols if it's not in PICK_UNDEFINED mode", ->
    symbolSet = new SymbolSet()
    symbolSet.addUndefinedUse {name: "Line", line: 1, start: 1, end: 5 }
    model = new ExampleModel codeBuffer, new LineSet([1]), symbolSet
    view = new ExampleView model, makeEditor()

    # Only show markers when we're picking from undefined uses
    model.setState(ExampleModelState.PICK_UNDEFINED)
    expect(view.getTextEditor().getMarkers().length).toBe 1
    model.setState(ExampleModelState.VIEW)
    expect(view.getTextEditor().getMarkers().length).toBe 0
