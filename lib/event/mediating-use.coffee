{ ExampleModelProperty } = require "../model/example-model"
{ getDefsForUse, getDeclarationScope } = require "../suggester/definition-suggester"


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
module.exports.MediatingUseDetector = class MediatingUseDetector

  constructor: (model) ->
    @model = model
    @model.addObserver @

  detectMediatedUses: ->

    rangeSet = @model.getRangeSet()
    symbolSet = @model.getSymbols()
    activeUses = rangeSet.getActiveSymbols symbolSet.getVariableUses()
    activeDefs = rangeSet.getActiveSymbols symbolSet.getVariableDefs()

    for endUse in activeUses

      # Only consider the def that appears closest above the use
      defs = getDefsForUse endUse, @model
      def = defs[0]

      # Consider a pair of a use and its definition, if both are
      # in the set of active symbols
      if def in activeDefs

        defScope = getDeclarationScope def, @model.getParseTree()

        # Inspect all uses to see if they are a mediating use
        for use in symbolSet.getVariableUses()

          # To be a mediating use, a use has to share the name as the def,
          # and has to occur after the def and before the final ('end') use.
          if (use.getName() is def.getName()) and
              ((def.getRange().compare use.getRange()) is -1) and
              ((use.getRange().compare endUse.getRange()) is -1)

            # It also has to refer to the same variable as the def
            useScope = getDeclarationScope use, @model.getParseTree()
            if useScope.equals defScope

              # If all of these conditions hold, it's a mediating use.
              # Add it to the list of events, but only if this mediating use
              # isn't already in the list of events.
              event = new MediatingUseEvent def, endUse, use
              eventWasQueuedBefore = false
              for pastEvent in (@model.getViewedEvents().concat @model.getEvents())
                if (pastEvent instanceof MediatingUseEvent) and
                    (pastEvent.getMediatingUse().equals event.getMediatingUse())
                  eventWasQueuedBefore = true
              (@model.getEvents().push event) if not eventWasQueuedBefore

  # As we add active ranges, some past events will be no longer be relevant,
  # as the user may have added code that defines the use.  For all of these
  # unseen, obsoleted events, just remove them from the queue.
  removeObsoleteMediatedUseEvents: ->
    activeRanges = @model.getRangeSet().getActiveRanges()
    for event in @model.getEvents()
      if event instanceof MediatingUseEvent
        for range in activeRanges
          if (range.containsRange event.getMediatingUse().getRange())
            @model.getEvents().remove event

  onPropertyChanged: (object, propertyName, oldValue, newValue) ->

    if object is @model and propertyName is ExampleModelProperty.ACTIVE_RANGES

      oldActiveRanges = oldValue
      newActiveRanges = newValue

      # Only check for a crossing when a new range was added, and when there
      # are at least two ranges (a new and an earlier range) in the set
      if (newActiveRanges.length > oldActiveRanges.length) and
          (oldActiveRanges.length >= 1)
        @detectMediatedUses()
        @removeObsoleteMediatedUseEvents()
