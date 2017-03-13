{ parse } = require '../../lib/analysis/parse-tree'
{ Range } = require '../../lib/model/range-set'
{ File, Symbol } = require '../../lib/model/symbol-set'
{ JavaParser } = require '../../lib/grammar/Java/JavaParser'

describe 'control-finder', ->
  it 'can find an if statement', ->

    JAVA_CODE = [
      "public class Example {"
      "  public static void main(String[] args) {"
      "    if (true) {"
      "      int i = 1;"
      "    }"
      "  }"
      "}"
    ].join "\n"

    parseTree = parse JAVA_CODE
    console.log parseTree
    ifstatements = parseTree.getIfStatements()
    console.log ifstatements

    (expect ifstatements.length).toBe 1
    (expect ifstatements[0].start.line).toEqual 3
    (expect ifstatements[0].start.column).toEqual 4
    (expect ifstatements[0].stop.line).toEqual 7
    (expect ifstatements[0].stop.column).toEqual 4

    # codeBuffer = undefined
    # activeRanges = [new Range [],[]]
    # rangeSet = new RangeSet activeRanges
    # model = new ExampleModel codeBuffer, rangeSet, symbolSet, parseTree
    # detector = new MissingControlLogicDetector()

  fit 'can find multiple if statements', ->

    JAVA_CODE = [
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

    parseTree = parse JAVA_CODE
    console.log parseTree
    ifstatements = parseTree.getIfStatements()
    console.log ifstatements

    (expect ifstatements.length).toBe 2

    (expect ifstatements[0].start.line).toEqual 3
    (expect ifstatements[0].start.column).toEqual 4
    (expect ifstatements[0].stop.line).toEqual 7
    (expect ifstatements[0].stop.column).toEqual 4

    (expect ifstatements[1].start.line).toEqual 4
    (expect ifstatements[1].start.column).toEqual 8
    (expect ifstatements[1].stop.line).toEqual 6
    (expect ifstatements[1].stop.column).toEqual 8
