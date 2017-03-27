module.exports.ArchiveEvent = class ArchiveEvent

  constructor: (event) ->
    @event = event

  apply: (model) ->
    pastEvents = model.getEvents()
    for pastEvent, index in pastEvents
      if pastEvent is @event
        pastEvents.splice index, 1
        break
    model.getViewedEvents().push @event

  revert: (model) ->
    model.getViewedEvents().remove @event
    model.getEvents().unshift @event

  getEvent: ->
    @event
