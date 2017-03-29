{ MediatingUseEvent } = require "../event/mediating-use"


module.exports.MediatingUseExtension = class MediatingUseExtension

  constructor: (use, mediatingUse, event) ->
    @use = use
    @mediatingUse = mediatingUse
    @event = event

  getUse: ->
    @use

  getMediatingUse: ->
    @mediatingUse

  getEvent: ->
    @event


module.exports.MediatingUseExtender = class MediatingUseExtender

  getExtension: (event) ->
    return null if not (event instanceof MediatingUseEvent)
    new MediatingUseExtension event.getUse(), event.getMediatingUse(), event
