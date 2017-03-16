module.exports.StubSpec = class StubSpec

  constructor: (className, extraSpec) ->
    extraSpec or= []
    @className = className
    @fieldAccesses = extraSpec.fieldAccesses or []
    @methodCalls = extraSpec.methodCalls or []
    @superclassName = extraSpec.superclassName

  getClassName: ->
    @className

  setClassName: (className) ->
    @className = className

  getFieldAccesses: ->
    @fieldAccesses

  getMethodCalls: ->
    @methodCalls

  getSuperclassName: ->
    @superclassName

  setSuperclassName: (superclassName) ->
    @superclassName = superclassName

  # Shallow copy (edits to field accesses or method calls will affect all stubs)
  copy: ->
    new StubSpec @className,
      fieldAccesses: @fieldAccesses
      methodCalls: @methodCalls
      superclassName: @superclassName
