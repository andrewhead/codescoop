{ MissingDefinitionError } = require "../../lib/error/missing-definition"
{ DefinitionSuggester } = require "../../lib/suggester/definition-suggester"
{ SymbolSuggestion } = require "../../lib/suggester/suggestion"
{ Symbol, SymbolSet } = require "../../lib/model/symbol-set"
{ Range, RangeSet } = require "../../lib/model/range-set"
{ parse } = require "../../lib/analysis/parse-tree"
{ ExampleModel } = require "../../lib/model/example-model"

describe "DefinitionSuggester", ->

  parseTree = parse [
    "public class Example {"
    ""
    "  public doWork() {"
    "    // Even though this is a definition of k, it shouldn't be a"
    "    // suggested definition for k in the main (it's out of scope)"
    "    int k = 2;"
    "  }"
    ""
    "  public static void main(String [] args) {"
    "    int i = 1;"
    "    int j = i + 1;"
    "    int k = j + 1;  // j has one def above"
    "    i = 2;"
    "    i = 3;"
    "    System.out.println(i);  // i has two defs above"
    "    System.out.println(k);  // k has only one def"
    "  }"
    "}"
  ].join "\n"
  suggester = new DefinitionSuggester()
  symbols = new SymbolSet {
    uses: [
      (new Symbol "Example.java", "k", new Range [5, 8], [5, 9])
      (new Symbol "Example.java", "i", new Range [9, 8], [9, 9])
      (new Symbol "Example.java", "j", new Range [10, 8], [10, 9])
      (new Symbol "Example.java", "i", new Range [10, 12], [10, 13])
      (new Symbol "Example.java", "k", new Range [11, 8], [11, 9])
      (new Symbol "Example.java", "j", new Range [11, 12], [11, 13])
      (new Symbol "Example.java", "i", new Range [14, 23], [14, 24])
      (new Symbol "Example.java", "k", new Range [15, 23], [14, 24])
    ]
    defs: [
      (new Symbol "Example.java", "k", new Range [5, 8], [5, 9])
      (new Symbol "Example.java", "i", new Range [9, 8], [9, 9])
      (new Symbol "Example.java", "j", new Range [10, 8], [10, 9])
      (new Symbol "Example.java", "k", new Range [11, 8], [11, 9])
      (new Symbol "Example.java", "i", new Range [12, 4], [12, 5])
      (new Symbol "Example.java", "i", new Range [13, 4], [13, 5])
    ]
  }

  # For testing purposes, it doesn't matter what value rangeSet has,
  # as the definition suggester only looks at existing defs, and does not
  # care about what lines are in the active set.
  rangeSet = new RangeSet()

  # Make a model that can be passed to the suggester with all data
  model = new ExampleModel undefined, rangeSet, symbols, parseTree, undefined

  _indexOf = (suggestion, suggestions) =>
    i = 0
    for otherSuggestion in suggestions
      if suggestion.equals otherSuggestion
        return i
      i += 1
    false

  it "suggests a def that appears above the use", ->

    error = new MissingDefinitionError \
      new Symbol "Example.java", "j", new Range [11, 12], [11, 13]
    suggestions = suggester.getSuggestions error, model

    suggestion = suggestions[0]
    (expect suggestions.length).toBe 1
    (expect suggestion instanceof SymbolSuggestion).toBe true
    (expect suggestion.getSymbol()).toEqual \
      new Symbol "Example.java", "j", new Range [10, 8], [10, 9]

  it "prioritizes defs that are closer to the use", ->

    error = new MissingDefinitionError \
      new Symbol "Example.java", "i", new Range [14, 23], [14, 24]
    suggestions = suggester.getSuggestions error, model

    ranges = (s.getSymbol().getRange() for s in suggestions)
    (expect suggestions.length).toBe 3
    (expect ranges[0]).toEqual new Range [13, 4], [13, 5]
    (expect ranges[1]).toEqual new Range [12, 4], [12, 5]
    (expect ranges[2]).toEqual new Range [9, 8], [9, 9]

  it "only suggests a def that is in scope of the use", ->
    error = new MissingDefinitionError \
      new Symbol "Example.java", "k", new Range [15, 23], [15, 24]
    suggestions = suggester.getSuggestions error, model
    (expect suggestions.length).toBe 1

  it "suggests defs that below the use (and still sorts by proximity)", ->

    error = new MissingDefinitionError \
      new Symbol "Example.java", "i", new Range [10, 12], [10, 13]
    suggestions = suggester.getSuggestions error, model

    (expect suggestions.length).toBe 3
    ranges = (s.getSymbol().getRange() for s in suggestions)
    (expect ranges[0]).toEqual new Range [9, 8], [9, 9]
    (expect ranges[1]).toEqual new Range [12, 4], [12, 5]
    (expect ranges[2]).toEqual new Range [13, 4], [13, 5]
