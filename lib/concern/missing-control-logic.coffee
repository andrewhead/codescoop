
module.exports.MissingControlLogicError = class MissingControlLogicError

  constructor: (context) ->
    @context = context

  getContext: ->
    @context

# Detects which contexts (another way of saying node in the parse tree)
# within the set of active ranges are contained by control logic that is
# not in the set of active ranges, given the current code example.
module.exports.MissingControlLogicDetector = class MissingControlLogicDetector

  detectErrors: (model, context) ->

    parseTree = model.getParseTree()
    rangeSet = model.getRangeSet()

    missingControlLogicContexts = []

    #symbol = new Symbol (new File 'fakePath', 'fakeFileName'), 'i', (new Range [3,10], [3,11]), 'int'
    #symbolNode = parseTree.getNodeForSymbol symbol
    while context.parentCtx?
      if context.ruleIndex is JavaParser.RULE_statement
        console.log context
      symbolNode = context.parentCtx

    for activeRange in rangeSet.getActiveRanges()
      console.log activeRange
      missingControlLogicContexts.push activeRange

    missingControlLogicContexts
