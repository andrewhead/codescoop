module.exports.MissingControlLogicConcern = class MissingControlLogicConcern

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

    for activeRange in activeRangeSet
      console.log 'activeRange', activeRange.toString()
      containingControlLogicCtx = parseTree.getContainingControlLogicCtx(activeRange)
      console.log 'containingControlLogic', containingControlLogicCtx
      #resultingIFcontextRange = getContextRange(containingControlLogic)
      missingControlLogicContexts.push new MissingControlLogicConcern containingControlLogicCtx

    missingControlLogicContexts
