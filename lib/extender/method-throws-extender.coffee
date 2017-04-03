{ MethodThrowsEvent } = require "../event/method-throws"
{ extractCtxRange } = require "../analysis/parse-tree"


module.exports.MethodThrowsExtension = class MethodThrowsExtension

  constructor: (throwableName, throwsRange, throwableRange, methodHeaderRange,
      innerRange, event) ->
    @throwableName = throwableName
    @throwsRange = throwsRange
    @throwableRange = throwableRange
    @methodHeaderRange = methodHeaderRange
    @innerRange = innerRange
    @event = event

  getThrowableName: ->
    @throwableName

  getThrowsRange: ->
    @throwsRange

  getThrowableRange: ->
    @throwableRange

  getMethodHeaderRange: ->
    @methodHeaderRange

  getInnerRange: ->
    @innerRange

  getEvent: ->
    @evetn


module.exports.MethodThrowsExtender = class MethodThrowsExtender

  getExtension: (event) ->

    return null if event not instanceof MethodThrowsEvent

    methodCtx = event.getMethodCtx()
    methodCtxRange = extractCtxRange methodCtx
    methodLastChildCtx = methodCtx.children[methodCtx.children.length - 1]
    methodDeclarationCtx = methodLastChildCtx.children[0]

    # Compute the method header range as the range that goes from the
    # beginning of the method declaration to the end of the last symbol
    # that's a part of the header (in this case, the last throwable)
    firstMethodHeaderCtx = methodDeclarationCtx.children[0]
    lastMethodHeaderCtx = methodDeclarationCtx.children[ \
      methodDeclarationCtx.children.length - 2]
    lastHeaderCtxRange = extractCtxRange lastMethodHeaderCtx
    methodHeaderRange = [ methodCtxRange.start, lastHeaderCtxRange.end ]

    throwsFound = false
    throwsRange = undefined
    throwableRange = undefined
    for childCtx in methodDeclarationCtx.children
      if childCtx.getText() is "throws"
        throwsRange = extractCtxRange childCtx
        throwsFound = true
        continue
      else if throwsFound
        qualifiedNameListCtx = childCtx
        for qualifiedNameListChildCtx in qualifiedNameListCtx.children
          if qualifiedNameListChildCtx.getText() is event.getThrowableName()
            throwableRange = extractCtxRange qualifiedNameListChildCtx
            break
        break if throwableRange?

    return new MethodThrowsExtension event.getThrowableName(), throwsRange,
      throwableRange, methodHeaderRange, event.getInnerRange(), event
