{ MissingThrowsEvent } = require "../event/missing-throws"
{ extractCtxRange } = require "../analysis/parse-tree"
{ Extender } = require "./extender"


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

    return null if event not instanceof MissingThrowsEvent

    # The default suggested throw message is the fully-qualified exception name
    suggestedThrows = event.getException().getName()

    # However, if the exception or one of its super-classes has been imported,
    # suggest the short name for one of those exceptions.
    exception = event.getException()
    while exception?
      if (@model.getImportTable().getImports exception.getName()).length > 0
        suggestedThrows = exception.getName().replace /.*\./, ""
      exception = exception.getSuperclass()

    new MethodThrowsExtension suggestedThrows, event.getRange(), event
