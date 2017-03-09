{ File, Symbol, SymbolSet } = require "../../lib/model/symbol-set"

describe "SymbolSet", ->

  TEST_FILE = new File "path", "filename"

  it "returns defs and uses from 'all'", ->

    # First, add uses and make sure that they're tallied
    symbolSet = new SymbolSet()
    symbolSet.setUses [
      new Symbol TEST_FILE, "i", new Range [4, 8], [4, 9], "int"
    ]
    allSymbols = symbolSet.getAllSymbols()
    (expect allSymbols.length).toBe 1

    # Second, add defs and make sure they're added to the tally
    symbolSet.setDefs [
      new Symbol TEST_FILE, "i", new Range [3, 4], [3, 5], "int"
    ]
    allSymbols = symbolSet.getAllSymbols()
    (expect allSymbols.length).toBe 2
