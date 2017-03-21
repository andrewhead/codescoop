{ ControlLogicSuggester } = require "../../lib/suggester/control-logic-suggester"
{ ExampleModel } = require "../../lib/model/example-model"
{ MissingControlLogicConcern } = require "../../lib/concern/missing-control-logic"
{ File, Symbol, SymbolSet } = require "../../lib/model/symbol-set"
{ Range, RangeSet } = require "../../lib/model/range-set"
{ parse } = require "../../lib/analysis/parse-tree"

describe "ControlLogicSuggester", ->
  JAVA_CODE_1 = [
    "public class Example {"
    "  public static void main(String[] args) {"
    "    if (true) {"
    "      int i = 1;"
    "    }"
    "  }"
    "}"
  ].join "\n"

  JAVA_CODE_2 = [
    "public class Example {"
    "  public static void main(String[] args) {"
    "    if (true) {"
    "        if (true) {"
    "            int i = 1;"
    "        }"
    "    }"
    "  }"
    "}"
  ].join "\n"

  it "test suggester.getSuggestions", ->

    parseTree = parse JAVA_CODE_2
    console.log parseTree
    activeRange = new Range [4,8],[6,8]
    controlLogicCtx = parseTree.getContainingControlLogicCtx(activeRange)
    concern = new MissingControlLogicConcern controlLogicCtx

    suggester = new ControlLogicSuggester()
    suggestions = suggester.getSuggestions concern
    (expect suggestions.length).toBe 1

    suggestion = suggestions[0]
    (expect suggestion.getType()).toEqual "if"
    (expect suggestion.getRanges().length).toEqual 2
