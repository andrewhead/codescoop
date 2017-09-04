{ MissingThrowsEvent } = require "../event/missing-throws"
{ extractCtxRange } = require "../analysis/parse-tree"
{ Extender } = require "./extender"
{ resolveExceptionClass } = require "../event/missing-throws"


module.exports.MethodThrowsExtension = class MethodThrowsExtension

  constructor: (suggestedThrows, throwingRange, event) ->
    @suggestedThrows = suggestedThrows
    @throwingRange = throwingRange
    @event = event

  getSuggestedThrows: ->
    @suggestedThrows

  getThrowingRange: ->
    @throwingRange

  getEvent: ->
    @event


module.exports.MethodThrowsExtender = class MethodThrowsExtender extends Extender

  getExtension: (event) ->
    return null if (event not instanceof MissingThrowsEvent)
    suggestedThrows = resolveExceptionClass \
      @model.getImportTable(), event.getException()
    new MethodThrowsExtension suggestedThrows, event.getRange(), event
