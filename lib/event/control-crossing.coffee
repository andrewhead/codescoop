{ ExampleModelProperty } = require "../model/example-model"
{ toControlStructure } = require "../analysis/parse-tree"
{ Symbol } = require "../model/symbol-set"


module.exports.ControlCrossingEvent = class ControlCrossingEvent

  constructor: (controlStructure, insideRange, outsideRange) ->
    @controlStructure = controlStructure
    @insideRange = insideRange
    @outsideRange = outsideRange

  getControlStructure: ->
    @controlStructure

  getInsideRange: ->
    @insideRange

  getOutsideRange: ->
    @outsideRange

  hasControlStructure: (controlStructure) ->
    @controlStructure.getCtx() is controlStructure.getCtx()


# Detects which contexts (another way of saying node in the parse tree)
# within the set of active ranges are contained by control logic that is
# not in the set of active ranges, given the current code example.
module.exports.ControlCrossingDetector = class ControlCrossingDetector

  constructor: (model) ->
    @model = model
    @model.addObserver @

  onPropertyChanged: (object, propertyName, oldValue, newValue) ->

    if object is @model and propertyName is ExampleModelProperty.ACTIVE_RANGES

      oldActiveRanges = oldValue
      newActiveRanges = newValue

      # Only check for a crossing when a new range was added, and when there
      # are at least two ranges (a new and an earlier range) in the set
      if (newActiveRanges.length > oldActiveRanges.length) and
          (oldActiveRanges.length >= 1)

        # Note that we assume that only one active range is added at a time.
        # If there's a situation where multiple ranges are added at once,
        # we're going to have to modify this logic.
        newRange = newActiveRanges[newActiveRanges.length - 1]
        lastRange = oldActiveRanges[oldActiveRanges.length - 1]

        crossedControlStructures = @findCrossedControlStructures \
          @model.getParseTree(), lastRange, newRange

        # Make an event for all the control structures that were
        # crossed with the most recent range addition
        for controlStructure in crossedControlStructures

          event = new ControlCrossingEvent controlStructure, lastRange, newRange

          # But only add the event if the user hasn't already seen it and if
          # it has not yet been added to the queue of events.
          eventWasQueuedBefore = false
          for pastEvent in (@model.getViewedEvents().concat @model.getEvents())
            if pastEvent.hasControlStructure event.getControlStructure()
              eventWasQueuedBefore = true
          (@model.getEvents().push event) if not eventWasQueuedBefore

  findCrossedControlStructures: (parseTree, lastRange, newRange) ->

    crossedControlStructures = []

    _getAncestors = (ctx) =>
      ancestors = []
      while ctx.parentCtx?
        ancestors.push [ctx.parentCtx]
        ctx = ctx.parentCtx

    # Find all ancestor nodes in the parse tree for both ranges
    lastRangeCtx = parseTree.getCtxForRange lastRange
    newRangeCtx = parseTree.getCtxForRange newRange
    lastRangeAncestors = _getAncestors lastRangeCtx
    newRangeAncestors = _getAncestors newRangeCtx

    # Find which ancestors of the last range are not shared with the new range
    for lastRangeAncestor in lastRangeAncestors
      if lastRangeAncestor not in newRangeAncestors
        controlStructure = toControlStructure lastRangeAncestor
        crossedControlStructures.push controlStructure if controlStructure?

    crossedControlStructures

  detectErrors: (model) ->

    parseTree = model.getParseTree()
    activeRanges = model.getRangeSet().getActiveRanges()

    missingControlLogicContexts = []

    for activeRange in activeRanges
      containingControlLogicCtx = parseTree.getContainingControlLogicCtx(activeRange)
      symbol = (new Symbol 'myfile', 'myCtrlName', activeRange, 'controllogic')
      missingControlLogicContexts.push new ControlCrossingEvent containingControlLogicCtx , symbol

    missingControlLogicContexts
