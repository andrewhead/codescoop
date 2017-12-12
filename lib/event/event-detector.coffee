# Abstract class to be extended with your own event detection routines. You
# need to implement:
#
#   [events] = detectEvents propertyName, oldValue, newValue
#     * given a change to the model, returns array of events that occurred
#   isQueued = isEventQueued event
#     * check whether an event has already been added to the list of
#       events that have or haven't been handled
#   isObsolete = isEventObsolete event
#     * check to see if an event is obsolete given the state of the model.
#       For example, if a for-loop has been added that includes the range
#       noticed by a control-crossing detector
#
# Calls a `detectEvent` method, that returns an event.
# Events that have already been viewed or enqueued in the list of events
# will not be added a second time.  This base class takes care of that logic
# to make sure that events aren't added twice.
module.exports.EventDetector = class EventDetector

  constructor: (model) ->
    @model = model
    @model.addObserver @

  onPropertyChanged: (object, propertyName, oldValue, newValue) ->

    if object is @model

      # Detect events and add all new ones to the queue
      # But only add the event if the user hasn't already seen it and if
      # it has not yet been added to the queue of events.
      events = @detectEvents propertyName, oldValue, newValue
      for event in events
        if not @isEventQueued event
          @model.getEvents().push event

      # Remove events that have been made obsolete by model changes
      for event in @model.getEvents()
        if @isEventObsolete event
          @model.getEvents().remove event
