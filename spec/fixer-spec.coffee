{ ExampleModel } = require "../lib/model/example-model"
{ Symbol, SymbolSet, File } = require "../lib/model/symbol-set"
{ Range, RangeSet } = require "../lib/model/range-set"
{ SymbolSuggestion, PrimitiveValueSuggestion } = require '../lib/suggestor/suggestion'
{ Fixer } = require "../lib/fixer"

describe "Fixer", ->

  rangeSet = new RangeSet()
  symbols = new SymbolSet()

  TEST_FILE = new File '.', 'test-file.java'

  editor = atom.workspace.buildTextEditor()
  codeBuffer = editor.getBuffer()
  codeBuffer.setText "int i = 1;"

  symbolSug = new SymbolSuggestion new Symbol TEST_FILE, "i", new Range [0, 4], [0, 5]

  model = new ExampleModel codeBuffer, rangeSet, symbols, undefined, undefined

  it "applies a suggestion to a model", ->
    fixer = new Fixer()
    fixer.apply model, symbolSug
    activeRanges = model.getRangeSet().getActiveRanges()
    activeRangeFound = false
    for range in activeRanges
      if range.containsRange symbolSug.getSymbol().getRange()
        activeRangeFound = true
    (expect activeRangeFound).toBe true
