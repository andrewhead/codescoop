{ EventDetector } = require "./event-detector"
{ ExampleModelProperty } = require "../model/example-model"


module.exports.MissingThrowsEvent = class MissingThrowsEvent

  constructor: (range, exception) ->
    @range = range
    @exception = exception

  getException: ->
    @exception

  getRange: ->
    @range

  equals: (other) ->
    ((other instanceof MissingThrowsEvent) and
     (other.getRange().isEqual @range) and
     (other.getException().equals @exception))


# The input exception can have a superclass.  The list of exceptions can
# either be fully-qualified names or not.
module.exports.isExceptionInList = isExceptionInList = \
    (exception, exceptionNameList) =>

  # Recursively look through the names of the supertypes of the exception
  superclass = exception
  while superclass?

    # Compare to every exception in the input list
    for exceptionName in exceptionNameList

      # If the name from the list is qualified, compare the full name
      isQualified = exception.getName().indexOf '.' != -1
      if isQualified and superclass.getName() == exceptionName
        return true
      # Otherwise, just check to see that the exceptionbasename is defined
      else
        baseSuperclassName = superclass.getName().replace /.*\./, ""
        if baseSuperclassName == exceptionName
          return true

    # If there wasn't a match, check the exception's super-type
    superclass = superclass.getSuperclass()


module.exports.MissingThrowsDetector = class MissingThrowsDetector extends EventDetector

  _isExceptionAlreadyThrown: (exception, model) ->
    return isExceptionInList exception, model.getThrows()

  _isExceptionAlreadyCaught: (exception, throwsRange, activeRanges, catchTable) ->
    catchRanges = catchTable.getCatchRanges throwsRange
    for catchRange in catchRanges
      for activeRange in activeRanges
        if catchRange.intersectsWith activeRange
          return true
    false

  detectEvents: (propertyName, oldValue, newValue) ->

    events = []

    if ((propertyName is ExampleModelProperty.ACTIVE_RANGES) and
        newValue.length > oldValue.length)

      throwsTable = @model.getThrowsTable()
      catchTable = @model.getCatchTable()
      return events if (not throwsTable?) or (not catchTable?)
      activeRanges = @model.getRangeSet().getActiveRanges()

      # Search for ranges that throw exceptions in the set of active ranges
      for activeRange in activeRanges

        rangesWithExceptions = throwsTable.getRangesWithThrows()

        for range in rangesWithExceptions
          if activeRange.containsRange range

            # For each exception thrown, see if it is already thrown or handled.
            # If it isn't, we should create an event.
            for exception in throwsTable.getExceptions range

              # It's can be costly to check if an exception is already
              # thrown.  Before computing whether to add this event, see if
              # it's already queued.
              potentialEvent = new MissingThrowsEvent range, exception

              # If the example is already throwing this exception of the
              # superclass of the exception, we don't need to add it in.
              continue if @_isExceptionAlreadyThrown exception, @model
              continue if @_isExceptionAlreadyCaught exception, range, activeRanges, catchTable

              # If it's not already handled, make an event
              events.push potentialEvent

    events

  isEventQueued: (event) ->
    for pastEvent in @model.getEvents().concat @model.getViewedEvents()
      if (pastEvent instanceof MissingThrowsEvent and
         (pastEvent.equals event))
        return true
    false

  isEventObsolete: (event) ->

    return false if event not instanceof MissingThrowsEvent

    exception = event.getException()
    range = event.getRange()
    activeRanges = @model.getRangeSet().getActiveRanges()
    catchTable = @model.getCatchTable()
    return true if (
      (@_isExceptionAlreadyThrown exception, @model) or
      (@_isExceptionAlreadyCaught exception, range, activeRanges, catchTable))

    isRangeInactive = true
    for activeRange in activeRanges
      if activeRange.containsRange range
        isRangeInactive = false

    return isRangeInactive
