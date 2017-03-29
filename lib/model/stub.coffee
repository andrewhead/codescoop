module.exports.StubSpec = class StubSpec

  constructor: (className, extraSpec) ->
    extraSpec or= []
    @className = className
    @fieldAccesses = extraSpec.fieldAccesses or {}
    @methodCalls = extraSpec.methodCalls or []
    @superclassName = extraSpec.superclassName

  getClassName: ->
    @className

  setClassName: (className) ->
    @className = className

  # Assumes stub spec has already been initialized with a list of fields
  # that can be accessed and their types in the `extraSpec`.  If the stub
  # hasn't been initialized with this field, no access will be saved.
  addFieldAccess: (fieldName, value) ->
    if fieldName of @fieldAccesses
      @fieldAccesses[fieldName].values.push value

  # Assumes stub spec has already been initialized with a list of methods
  # available for the stub in the `extraSpec`.  If the stub hasn't been
  # initialized with this method signature, no return value will be saved.
  addMethodCall: (methodName, argumentTypes, returnValue) ->
    for otherMethod in @methodCalls
      otherMethodName = otherMethod.signature.name
      otherMethodArgumentTypes = otherMethod.signature.argumentTypes
      namesMatch = otherMethodName is methodName
      argumentsMatch = otherMethodArgumentTypes.every (element, i) =>
        element is argumentTypes[i]
      argumentLengthsMatch = otherMethodArgumentTypes.length is argumentTypes.length
      if namesMatch and argumentsMatch and argumentLengthsMatch
        otherMethod.returnValues.push returnValue
        break

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


module.exports.StubSpecTable = class StubSpecTable

  constructor: ->
    @table = {}
    @size = 0

  putStubSpec: (className, symbolName, lineNumber, stubSpec) ->
    if className not of @table
      @table[className] = {}
    if symbolName not of @table[className]
      @table[className][symbolName] = {}
    if lineNumber not of @table[className][symbolName]
      @table[className][symbolName][lineNumber] = []
    @table[className][symbolName][lineNumber].push stubSpec
    @size += 1

  getStubSpecs: (className, symbolName, lineNumber) ->
    if (className of @table) and
        (symbolName of @table[className]) and
        (lineNumber of @table[className][symbolName])
      return @table[className][symbolName][lineNumber]
    else
      return []

  getSize: ->
    @size
