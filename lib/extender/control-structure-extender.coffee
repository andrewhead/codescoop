{ IfControlStructure, ForControlStructure, WhileControlStructure, DoWhileControlStructure, TryCatchControlStructure } = require "../../lib/analysis/parse-tree"
{ ControlCrossingEvent } = require "../event/control-crossing"
{ extractCtxRange } = require "../analysis/parse-tree"
{ JavaParser } = require "../grammar/Java/JavaParser"
{ Range } = require "../model/range-set"


module.exports.ControlStructureExtension = class ControlStructureExtension

  constructor: (controlStructure, ranges, event) ->
    @controlStructure = controlStructure
    @ranges = ranges
    @event = event

  getControlStructure: ->
    @controlStructure

  getRanges: ->
    @ranges

  getEvent: ->
    @event


_getBlockBraceRanges = (statementCtx) =>

  leftBraceRange = undefined
  rightBraceRange = undefined

  if (statementCtx.children[0].ruleIndex is JavaParser.RULE_block)
    blockCtx = statementCtx.children[0]
    leftBraceNode = blockCtx.children[0]
    rightBraceNode = blockCtx.children[blockCtx.children.length - 1]
    leftBraceRange = extractCtxRange leftBraceNode
    rightBraceRange = extractCtxRange rightBraceNode

  return { leftBraceRange, rightBraceRange }


module.exports.ControlStructureExtender = class ControlStructureExtender

  getExtension: (event) ->

    return null if not (event instanceof ControlCrossingEvent)

    controlStructure = event.getControlStructure()
    ctx = controlStructure.getCtx()
    ranges = []

    # Manually extract the ranges corresponding to the control structure
    # for each different type of control structure.
    # For thiis first condition: Right now, this only captures the body of the
    # If.  It doesn't capture an "else".  We'll have to do that eventually.
    if controlStructure instanceof IfControlStructure

      ifRange = extractCtxRange ctx.children[0]
      parExpressionRange = extractCtxRange ctx.children[1]
      { leftBraceRange, rightBraceRange } = _getBlockBraceRanges ctx.children[2]

      # Manually coalesce the ranges.  Note that there might be omitted
      # whitespace between the ranges, meaning that we can't rely on
      # automatic coalescing based on overlap
      firstRange = new Range [ifRange.start.row, ifRange.start.column],
        [parExpressionRange.end.row, parExpressionRange.end.column]
      if leftBraceRange?
        firstRange.end.row = leftBraceRange.end.row
        firstRange.end.column = leftBraceRange.end.column
      ranges.push firstRange

      # Not all if statements will have a right brace
      (ranges.push rightBraceRange) if rightBraceRange?

    else if controlStructure instanceof ForControlStructure

      forRange = extractCtxRange ctx.children[0]
      endControlParenRange = extractCtxRange ctx.children[3]
      { leftBraceRange, rightBraceRange } = _getBlockBraceRanges ctx.children[4]

      firstRange = new Range [forRange.start.row, forRange.start.column],
        [endControlParenRange.end.row, endControlParenRange.end.column]
      if leftBraceRange?
        firstRange.end.row = leftBraceRange.end.row
        firstRange.end.column = leftBraceRange.end.column
      ranges.push firstRange
      (ranges.push rightBraceRange) if rightBraceRange?

    else if controlStructure instanceof WhileControlStructure

      whileRange = extractCtxRange ctx.children[0]
      parExpressionRange = extractCtxRange ctx.children[1]
      { leftBraceRange, rightBraceRange } = _getBlockBraceRanges ctx.children[2]

      firstRange = new Range [whileRange.start.row, whileRange.start.column],
        [parExpressionRange.end.row, parExpressionRange.end.column]
      if leftBraceRange?
        firstRange.end.row = leftBraceRange.end.row
        firstRange.end.column = leftBraceRange.end.column
      ranges.push firstRange
      (ranges.push rightBraceRange) if rightBraceRange?

    else if controlStructure instanceof DoWhileControlStructure

      doRange = extractCtxRange ctx.children[0]
      { leftBraceRange, rightBraceRange } = _getBlockBraceRanges ctx.children[1]
      whileRange = extractCtxRange ctx.children[2]
      semicolonRange = extractCtxRange ctx.children[4]

      firstRange = new Range [doRange.start.row, doRange.start.column],
        [doRange.end.row, doRange.end.column]
      if leftBraceRange?
        firstRange.end.row = leftBraceRange.end.row
        firstRange.end.column = leftBraceRange.end.column
      ranges.push firstRange

      secondRange = new Range [whileRange.start.row, whileRange.start.column],
        [semicolonRange.end.row, semicolonRange.end.column]
      if rightBraceRange?
        secondRange.start.row = rightBraceRange.start.row
        secondRange.start.column = rightBraceRange.start.column
      ranges.push secondRange

    # Eventually, this should be capable of capturing more than just
    # one catch.  We'll get there.
    else if controlStructure instanceof TryCatchControlStructure

      tryRange = extractCtxRange ctx.children[0]
      tryBlockChildren = ctx.children[1].children
      tryBlockLeftBraceRange = extractCtxRange tryBlockChildren[0]
      tryBlockRightBraceRange = extractCtxRange tryBlockChildren[tryBlockChildren.length - 1]

      catchClauseCtx = ctx.children[2]
      catchRange = extractCtxRange catchClauseCtx.children[0]
      catchBlockChildren = catchClauseCtx.children[catchClauseCtx.children.length - 1].children
      catchBlockLeftBraceRange = extractCtxRange catchBlockChildren[0]
      catchBlockRightBraceRange = extractCtxRange catchBlockChildren[catchBlockChildren.length - 1]

      firstRange = new Range [tryRange.start.row, tryRange.start.column],
        [tryBlockLeftBraceRange.end.row, tryBlockLeftBraceRange.end.column]
      secondRange = new Range \
        [tryBlockRightBraceRange.start.row, tryBlockRightBraceRange.start.column],
        [catchBlockLeftBraceRange.end.row, catchBlockLeftBraceRange.end.column]
      thirdRange = catchBlockRightBraceRange
      ranges.push firstRange
      ranges.push secondRange
      ranges.push thirdRange

    extension = new ControlStructureExtension controlStructure, ranges, event
