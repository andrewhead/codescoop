{ EventDetector } = require "./event-detector"
{ ExampleModelProperty } = require "../model/example-model"
{ toControlStructure, TryCatchControlStructure, extractCtxRange, getControlStructureRanges } = require "../analysis/parse-tree"
{ JavaParser } = require "../../lib/grammar/Java/JavaParser"


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
_isExceptionInList = (exception, exceptionNameList) =>

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
    return _isExceptionInList exception, model.getThrows()

  _isExceptionAlreadyCaught: (exception, throwsRange, activeRanges, parseTree) ->

    statementCtx = parseTree.getCtxForRange throwsRange
    parentCtx = statementCtx
    alreadyHandled = false

    # Starting at this range, look to see if a try-catch block has been
    # included that already handles the exception.
    while parentCtx?

      # Check to see if this node is actually a try-catch block
      tryCatch = toControlStructure parentCtx
      if tryCatch instanceof TryCatchControlStructure

        # Check to see if this try-catch block is active
        tryCatchRanges = getControlStructureRanges tryCatch
        tryCatchActive = false
        for tryCatchRange in tryCatchRanges
          for activeRange in activeRanges
            if tryCatchRange.intersectsWith activeRange
              tryCatchActive = true

        if tryCatchActive

          # Traverse down to the exception names...
          catchClauseCtx = tryCatch.getCtx().children[2]
          for catchClauseChildCtx in catchClauseCtx.children

            if catchClauseChildCtx.ruleIndex == JavaParser.RULE_catchType
              catchTypeCtx = catchClauseChildCtx
              exceptionsCaught = []
              # Save all of the names of the exceptions thrown
              for catchTypeChildCtx in catchTypeCtx.children
                if (catchTypeChildCtx.ruleIndex == JavaParser.RULE_qualifiedName)
                  exceptionsCaught.push catchTypeChildCtx.getText()

              # Consider this handled if the method is in the 'try'
              # block and the catch lists that exception.
              catchTypeRange = extractCtxRange catchTypeCtx
              if (((throwsRange.compare catchTypeRange) < 0) and
                  (_isExceptionInList exception, exceptionsCaught))
                return true

      parentCtx = parentCtx.parentCtx

    false


  detectEvents: (propertyName, oldValue, newValue) ->

    events = []

    if propertyName is ExampleModelProperty.ACTIVE_RANGES

      throwsTable = @model.getThrowsTable()
      return events if not throwsTable?
      parseTree = @model.getParseTree()
      activeRanges = @model.getRangeSet().getActiveRanges()

      # Search for ranges that throw exceptions in the set of active ranges
      for activeRange in activeRanges

        rangesWithExceptions = throwsTable.getRangesWithThrows()

        for range in rangesWithExceptions
          if activeRange.containsRange range

            # For each exception thrown, see if it is already thrown or handled.
            # If it isn't, we should create an event.
            for exception in throwsTable.getExceptions range

              # It's can be really costly to check if an exception is already
              # thrown by traversing the parse tree.  Before even computing
              # whether to add this event, see if we've already created and
              # queued it.  If so, don't bother adding it!
              potentialEvent = new MissingThrowsEvent range, exception
              continue if @isEventQueued potentialEvent

              # If the example is already throwing this exception of the
              # superclass of the exception, we don't need to add it in.
              continue if @_isExceptionAlreadyThrown exception, @model
              continue if @_isExceptionAlreadyCaught exception, range, activeRanges, parseTree

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
    parseTree = @model.getParseTree()
    return true if (
      (@_isExceptionAlreadyThrown exception, @model) or
      (@_isExceptionAlreadyCaught exception, range, activeRanges, parseTree))
