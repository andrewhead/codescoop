{ ExampleModel } = require "../lib/model/example-model"
{ Symbol, SymbolSet, File } = require "../lib/model/symbol-set"
{ Range, RangeSet } = require "../lib/model/range-set"
{ SymbolSuggestion, PrimitiveValueSuggestion } = require '../lib/suggester/suggestion'
{ Fixer } = require "../lib/fixer"


describe "Fixer", ->

  _makeModel = =>
    editor = atom.workspace.buildTextEditor()
    codeBuffer = editor.getBuffer()
    codeBuffer.setText [
      "int i = 15;"
      "int j = i + 1;"
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

  it "overwrites a symbol with a new value with a PrimitiveValueSuggestion", ->
    model = _makeModel()
    suggestion = new PrimitiveValueSuggestion \
      (new Symbol TEST_FILE, "i", new Range [1, 8], [1, 9]), "15"
    fixer.apply model, suggestion
    (expect model.getCodeBuffer().getText().indexOf "j = 15 + 1").not.toBe -1
