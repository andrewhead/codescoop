{ ExampleModel } = require "../lib/model/example-model"
{ Symbol, SymbolSet, File } = require "../lib/model/symbol-set"
{ Range, RangeSet } = require "../lib/model/range-set"
{ SymbolSuggestion, PrimitiveValueSuggestion } = require '../lib/suggester/suggestion'
{ Fixer } = require "../lib/fixer"
{ Replacement } = require "../lib/edit/replacement"


describe "Fixer", ->

  _makeModel = =>
    editor = atom.workspace.buildTextEditor()
    codeBuffer = editor.getBuffer()
    codeBuffer.setText [
      "int i = 15;"
      "int j = i + i + 1;"
    ].join "\n"
    rangeSet = new RangeSet()
    symbols = new SymbolSet()
    new ExampleModel codeBuffer, rangeSet, symbols

  TEST_FILE = new File '.', 'test-file.java'
  fixer = new Fixer()

  it "adds a range that includes a symbol of a SymbolSuggestion", ->
    model = _makeModel()
    suggestion = new SymbolSuggestion \
      new Symbol TEST_FILE, "i", new Range [0, 4], [0, 5]
    fixer.apply model, suggestion

    activeRanges = model.getRangeSet().getActiveRanges()
    activeRangeFound = false
    for range in activeRanges
      if range.containsRange suggestion.getSymbol().getRange()
        activeRangeFound = true
    (expect activeRangeFound).toBe true

  describe "when handling a PrimitiveValueSuggestion", ->

    model = _makeModel()
    model.getSymbols().setUses [
      new Symbol TEST_FILE, "i", new Range [1, 8], [1, 9]
      new Symbol TEST_FILE, "i", new Range [1, 12], [1, 13]
    ]
    suggestion = new PrimitiveValueSuggestion \
      (new Symbol TEST_FILE, "i", new Range [1, 8], [1, 9]), "15"
    fixer.apply model, suggestion

    it "registers a new 'replacement' edit", ->
      edits = model.getEdits()
      (expect edits.length).toBe 1
      edit = edits[0]
      (expect edit instanceof Replacement).toBe true
      (expect edit.getSymbol().getRange()).toEqual new Range [1, 8], [1, 9]
      (expect edit.getText()).toEqual "15"

    it "updates the model to reflect that the symbol is no longer being used", ->
      uses = model.getSymbols().getUses()
      (expect uses.length).toBe 1
      (expect uses[0].getRange()).toEqual new Range [1, 12], [1, 13]
