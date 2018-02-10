{ File, Symbol, SymbolSet } = require "../../lib/model/symbol-set"
{ Range } = require "../../lib/model/range-set"

TEST_FILE = new File "path", "filename"


describe "Symbol", ->

  it "deserializes JSON into a symbol", ->

    symbol = Symbol.deserialize {
      file: {
        path: "/path/to/Klazz.java"
        fileName: "Klazz.java"
      }
      name: "var"
      range: {
        start: {
          row: 10
          column: 8
        }
        end: {
          row: 10
          column: 11
        }
      }
      type: "int"
    }

    (expect symbol.getRange()).toEqual new Range [10, 8], [10, 11]
    (expect symbol.getName()).toBe "var"
    (expect symbol.getType()).toBe "int"
    (expect symbol.getFile().getPath()).toBe "/path/to/Klazz.java"
    (expect symbol.getFile().getName()).toBe "Klazz.java"


describe "SymbolSet", ->

  it "returns defs and uses from 'all'", ->

    # First, add uses and make sure that they're tallied
    symbolSet = new SymbolSet()
    symbolSet.setVariableUses [
      new Symbol TEST_FILE, "i", new Range [4, 8], [4, 9], "int"
    ]
    allSymbols = symbolSet.getAllSymbols()
    (expect allSymbols.length).toBe 1

    # Second, add defs and make sure they're added to the tally
    symbolSet.setVariableDefs [
      new Symbol TEST_FILE, "i", new Range [3, 4], [3, 5], "int"
    ]
    allSymbols = symbolSet.getAllSymbols()
    (expect allSymbols.length).toBe 2
