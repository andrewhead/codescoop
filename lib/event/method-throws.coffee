{ EventDetector } = require "./event-detector"
{ ExampleModelProperty } = require "../model/example-model"
{ JavaParser } = require "../grammar/Java/JavaParser"


module.exports.MethodThrowsEvent = class MethodThrowsEvent

  constructor: (throwableName, methodCtx, innerRange) ->
    @throwableName = throwableName
    @methodCtx = methodCtx
    @innerRange = innerRange

  getThrowableName: ->
    @throwableName

  getMethodCtx: ->
    @methodCtx

  getInnerRange: ->
    @innerRange


_getContainingMethodCtx = (parseTree, range) ->

  ctx = parseTree.getCtxForRange range
  parentCtx = ctx

  while parentCtx?

    # Check if this is a declaration in the class body.  We want to return
    # a ctx at the level of class body declaration if we can, as this will
    # give us the full range of the method declaration, including modifiers.
    if parentCtx.ruleIndex is JavaParser.RULE_classBodyDeclaration

      # Check to see if this is a method declaration.  If so, return it.
      continue if not parentCtx.children.length >= 2
      lastChildIndex = parentCtx.children.length - 1
      possibleMethodDeclarationCtx = parentCtx.children[lastChildIndex].children[0]
      if possibleMethodDeclarationCtx.ruleIndex is JavaParser.RULE_methodDeclaration
        return parentCtx

    # Otherwise, keep climbing the tree
    parentCtx = parentCtx.parentCtx

  return null


module.exports.MethodThrowsDetector = class MethodThrowsDetector extends EventDetector

  detectEvents: (propertyName, oldValue, newValue) ->

    events = []

    if propertyName is ExampleModelProperty.ACTIVE_RANGES
      parseTree = @model.getParseTree()
      for activeRange in @model.getRangeSet().getActiveRanges()

        # Find the ctx corresponding to the method signature for the method
        # containing this range, if one exists
        methodCtx = _getContainingMethodCtx parseTree, activeRange
        continue if not methodCtx?
        memberDeclarationCtx = methodCtx.children[methodCtx.children.length - 1]
        methodSignatureCtx = memberDeclarationCtx.children[0]
        throwableNames = []

        # Look for a 'throws' keyword in the signature.  Once we find it,
        # keep track of the name of all of the throwables thrown.
        throwsFound = false
        for childCtx in methodSignatureCtx.children
          if childCtx.getText() is "throws"
            throwsFound = true
            continue
          else if throwsFound
            qualifiedNameListCtx = childCtx
            for qualifiedNameListChildCtx in qualifiedNameListCtx.children
              if qualifiedNameListChildCtx.ruleIndex is JavaParser.RULE_qualifiedName
                throwableNames.push qualifiedNameListChildCtx.getText()

        # Create an event for each throwable found
        for throwableName in throwableNames
          event = new MethodThrowsEvent throwableName, methodCtx, activeRange
          events.push event

    events

  isEventQueued: (event) ->
    for pastEvent in @model.getEvents().concat @model.getViewedEvents()
      if pastEvent instanceof MethodThrowsEvent and
          pastEvent.getThrowableName() is event.getThrowableName() and
          pastEvent.getMethodCtx() is event.getMethodCtx()
        return true
    false

  isEventObsolete: (event) ->
    false
