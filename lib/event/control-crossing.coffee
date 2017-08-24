{ EventDetector } = require "./event-detector"
{ ExampleModelProperty } = require "../model/example-model"
{ toControlStructure, getControlStructureRanges } = require "../analysis/parse-tree"
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
module.exports.ControlCrossingDetector = class ControlCrossingDetector extends EventDetector

  detectEvents: (propertyName, oldValue, newValue) ->

    events = []

    if propertyName is ExampleModelProperty.ACTIVE_RANGES

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
          events.push event

    events

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

  isEventQueued: (event) ->
    for pastEvent in (@model.getViewedEvents().concat @model.getEvents())
      continue if not (pastEvent instanceof ControlCrossingEvent)
      if pastEvent.hasControlStructure event.getControlStructure()
        return true
    false

  isEventObsolete: (event) ->

    return false if event not instanceof ControlCrossingEvent

    # Find the first range for the control structure (the one that
    # is likely to include a user selection if they wanted to include the
    # control structure).
    controlStructureRanges = getControlStructureRanges event.getControlStructure()
    firstControlStructureRange = controlStructureRanges[0]
    activeRanges = @model.getRangeSet().getActiveRanges()

    # Search for a range that intersects with the start of the control
    # structure.  We do an intersection instead of containment in case
    # the user has made an incomplete selection and is going to go back
    # to improve it.
    for activeRange in activeRanges
      if activeRange.intersectsWith firstControlStructureRange
        return true

    # The inner range for the event still needs to be in the active ranges.
    # If it's removed through an undo, this event is obsolete.
    for activeRange in activeRanges
      if activeRange.isEqual event.getInsideRange()
        return false

    true
