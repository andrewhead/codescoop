{ PrimitiveValueSuggester } = require "../../lib/suggester/primitive-value-suggester"
{ PrimitiveValueSuggestion } = require "../../lib/suggester/suggestion"
{ ExampleModel } = require "../../lib/model/example-model"
{ Range, RangeSet } = require "../../lib/model/range-set"
{ File, Symbol, SymbolSet } = require "../../lib/model/symbol-set"
{ MissingDefinitionError } = require "../../lib/error/missing-definition"
{ ValueMap } = require "../../lib/analysis/value-analysis"
_ = require "lodash"


describe "PrimitiveValueSuggester", ->

  valueMap = new ValueMap
  _.extend valueMap,
    "Example.java":
      2: { i: ["2", "1"] }
  rangeSet = new RangeSet()
  symbols = new SymbolSet()
  model = new ExampleModel undefined, rangeSet, symbols, undefined, valueMap
  suggester = new PrimitiveValueSuggester()

  it "suggests all primitive values known for a symbol", ->
    error = new MissingDefinitionError \
      new Symbol (new File "path", "Example.java"), "i", new Range [2, 4], [2, 5]
    suggestions = suggester.getSuggestions error, model
    (expect suggestions.length).toBe 2
    (expect suggestions[0] instanceof PrimitiveValueSuggestion).toBe true
    (expect suggestions[0].getValueString()).toEqual "2"
    (expect suggestions[1].getValueString()).toEqual "1"

  it "returns nothing when symbol couldn't be found", ->
    error = new MissingDefinitionError \
      new Symbol (new File "path", "Example.java"), "a", new Range [2, 4], [2, 5]
    suggestions = suggester.getSuggestions error, model
    (expect suggestions.length).toBe 0
