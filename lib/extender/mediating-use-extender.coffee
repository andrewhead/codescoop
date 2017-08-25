{ MediatingUseEvent } = require "../event/mediating-use"


module.exports.MediatingUseExtension = class MediatingUseExtension

  constructor: (use, mediatingUses, events) ->
    @use = use
    @mediatingUses = mediatingUses
    @events = events

  getUse: ->
    @use

  getMediatingUses: ->
    @mediatingUses

  getEvents: ->
    @events


module.exports.MediatingUseExtender = class MediatingUseExtender

  getExtension: (event, events) ->
    return null if not (event instanceof MediatingUseEvent)

    # If only one event was passed in, return an extension for that event.
    if not events?
      return new MediatingUseExtension event.getUse(),
        [event.getMediatingUse()], [event]

    # If the full list of events was passed in, look for other events that
    # share this use and def, and group them all together
    mediatingUses = [event.getMediatingUse()]
    relatedEvents = [event]
    for otherEvent in events
      if ((otherEvent instanceof MediatingUseEvent) and
          (otherEvent.getUse().equals event.getUse()) and
          (otherEvent.getDef().equals event.getDef()) and
          (otherEvent != event))

        mediatingUses.push otherEvent.getMediatingUse()
        relatedEvents.push otherEvent

    new MediatingUseExtension event.getUse(), mediatingUses, relatedEvents
