
module.exports.MissingControlLogicError = class MissingControlLogicError

  constructor: (context) ->
    @context = context

  getContext: ->
    @context

# Detects which contexts (another way of saying node in the parse tree)
# within the set of active ranges are contained by control logic that is
# not in the set of active ranges, given the current code example.
module.exports.MissingControlLogicDetector = class MissingControlLogicDetector

  detectErrors: (model) ->

    parseTree = model.getParseTree()
    rangeSet = model.getRangeSet()

    missingDeclarations
