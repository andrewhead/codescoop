module.exports.MissingControlLogicError = class MissingControlLogicError

  constructor: (controlCtx) ->
    @controlCtx = controlCtx

  getControlCtx: ->
    @controlCtx

# Detects which contexts (another way of saying node in the parse tree)
# within the set of active ranges are contained by control logic that is
# not in the set of active ranges, given the current code example.
module.exports.MissingControlLogicDetector = class MissingControlLogicDetector

  detectErrors: (model) ->

    parseTree = model.getParseTree()
    activeRangeSet = model.getRangeSet().getActiveRanges()

    missingControlLogicContexts = []

    #console.log 'parseTree', parseTree
    #symbol = new Symbol (new File 'fakePath', 'fakeFileName'), 'i', (new Range [3,10], [3,11]), 'int'
    #symbolNode = parseTree.getNodeForSymbol symbol
    # while context.parentCtx?
    #   if context.ruleIndex is JavaParser.RULE_statement
    #     console.log context
    #   symbolNode = context.parentCtx

    for activeRange in activeRangeSet
      console.log 'active', activeRange

    #missingControlLogicContexts.push new MissingControlLogicError

    missingControlLogicContexts
