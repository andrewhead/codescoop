{ MissingControlLogicDetector } = require '../../lib/concern/missing-control-logic'
{ parse, getContextRange } = require '../../lib/analysis/parse-tree'
{ Range, RangeSet } = require '../../lib/model/range-set'
{ File, Symbol, SymbolSet } = require '../../lib/model/symbol-set'
{ ExampleModel } = require "../../lib/model/example-model"
{ JavaParser } = require '../../lib/grammar/Java/JavaParser'

describe 'control-finder', ->
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

  it 'can find an if statement', ->

    parseTree = parse JAVA_CODE_1
    console.log parseTree
    ifstatements = parseTree.getIfStatements()
    console.log ifstatements

    (expect ifstatements.length).toBe 1
    (expect ifstatements[0].start.line).toEqual 3
    (expect ifstatements[0].start.column).toEqual 4
    (expect ifstatements[0].stop.line).toEqual 7
    (expect ifstatements[0].stop.column).toEqual 4

  it 'can find multiple if statements', ->

    parseTree = parse JAVA_CODE_2
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

  it 'can find the ranges of all statements', ->

    parseTree = parse JAVA_CODE_2
    console.log parseTree
    ctxRanges = parseTree.getCtxRanges()
    for ctxRange in ctxRanges
      #console.log ctxRange
      console.log ctxRange.toString()
      #console.log ctxRange.getRows()
      #console.log range.start(), range.end()

  it 'can find the enclosed control logic context', ->

    parseTree = parse JAVA_CODE_2
    console.log parseTree
    activeRange = new Range [4,8],[6,8]
    containingControlLogic = parseTree.getContainingControlLogicCtx(activeRange)
    console.log 'containingControlLogic', containingControlLogic
    resultingIFcontextRange = getContextRange(containingControlLogic)

    (expect resultingIFcontextRange).toEqual new Range [3, 4], [7, 4]

  fit 'can detect enclosing control logic that is not part of the active range', ->
    codeBuffer = undefined
    activeRanges = [new Range [4,8],[6,8]]
    console.log 'activeRanges', activeRanges
    rangeSet = new RangeSet activeRanges
    console.log 'rangeSet', rangeSet
    symbolSet = new SymbolSet()
    console.log 'symbolSet', symbolSet
    parseTree = parse JAVA_CODE_2
    console.log 'parseTree', parseTree
    model = new ExampleModel codeBuffer, rangeSet, symbolSet, parseTree
    console.log 'model', model
    detector = new MissingControlLogicDetector()
    console.log 'detector', detector
    errors = detector.detectErrors model
    console.log 'errors', errors
    console.log getContextRange(errors[0].controlCtx).toString()

    (expect errors.length).toBe 1
    (expect getContextRange(errors[0].controlCtx).toString()).toBe '[(3, 4) - (7, 4)]'
