module.exports.ExtensionDecision = class ExtensionDecision

  constructor: (event, extension, decision) ->
    @event = event
    @extension = extension
    @decision = decision

  getEvent: ->
    @event

  getExtension: ->
    @extension

  getDecision: ->
    @decision
