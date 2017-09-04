{ EventDetector } = require "./event-detector"
{ ExampleModelProperty } = require "../model/example-model"
{ getDefsForUse } = require "../suggester/definition-suggester"


module.exports.MediatingUseEvent = class MediatingUseEvent

  constructor: (def, use, mediatingUse) ->
    @def = def
    @use = use
    @mediatingUse = mediatingUse

  getDef: ->
    @def

  getUse: ->
    @use

  getMediatingUse: ->
    @mediatingUse


# Detects when there's a "use" of a symbol between its def and use
# in the current example, to recommend its inclusion in the example.
module.exports.MediatingUseDetector = class MediatingUseDetector extends EventDetector

  detectEvents: (propertyName, oldValue, newValue) ->

    events = []

    if propertyName is ExampleModelProperty.ACTIVE_RANGES

      oldActiveRanges = oldValue
      newActiveRanges = newValue

      if newActiveRanges.length > oldActiveRanges.length
        events = @detectMediatedUses()

    events

  detectMediatedUses: ->

    events = []
    rangeSet = @model.getRangeSet()
    symbolSet = @model.getSymbols()
    activeUses = rangeSet.getActiveSymbols symbolSet.getVariableUses()
    activeDefs = rangeSet.getActiveSymbols symbolSet.getVariableDefs()
    symbolTable = @model.getSymbolTable()

    for endUse in activeUses

      # Only consider the def that appears closest above the use
      defs = getDefsForUse endUse, @model
      def = defs[0]

      # Consider a pair of a use and its definition, if both are
      # in the set of active symbols
      if def in activeDefs

        # Inspect all uses to see if they are a mediating use
        for use in symbolSet.getVariableUses()

          # To be a mediating use, a use has to share the name as the def,
          # and has to occur after the def and before the final ('end') use.
          if (use.getName() is def.getName()) and
              ((def.getRange().compare use.getRange()) is -1) and
              ((use.getRange().compare endUse.getRange()) is -1)

            # It also has to refer to the same variable as the def
            if symbolTable.areTheSameVariable use, def

              # If all of these conditions hold, it's a mediating use.
              # Add it to the list of events, but only if this mediating use
              # isn't already in the list of events.
              event = new MediatingUseEvent def, endUse, use
              events.push event

    events

  isEventQueued: (event) ->
    for pastEvent in (@model.getViewedEvents().concat @model.getEvents())
      if (pastEvent instanceof MediatingUseEvent) and
          (pastEvent.getMediatingUse().equals event.getMediatingUse())
        return true
    false

  # As we add active ranges, some past events will be no longer be relevant,
  # as the user may have added code that defines the use.  For all of these
  # unseen, obsoleted events, just remove them from the queue.
  isEventObsolete: (event) ->

    activeRanges = @model.getRangeSet().getActiveRanges()
    if event instanceof MediatingUseEvent

      mediatingUseActive = false
      defActive = false
      useActive = false

      for range in activeRanges
        if (range.containsRange event.getMediatingUse().getRange())
          mediatingUseActive = true
        if (range.containsRange event.getUse().getRange())
          useActive = true
        if (range.containsRange event.getDef().getRange())
          defActive = true

      # A mediating use is no longer relevant if a user has added the use.
      # It's also no longer relevant if the definition and use are no longer
      # included in the active ranges of the program (e.g., from undo)
      return mediatingUseActive or (!defActive or !useActive)

    false
