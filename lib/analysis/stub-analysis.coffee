{ JAVA_CLASSPATH, java } = require "../config/paths"
{ StubSpec, StubSpecTable } = require "../model/stub"
MemberAccessAnalysis = java.import "MemberAccessAnalysis"


# We only create stubs for objects that are non-printable types.
# Those that can be easily substituted by a literal string ("printable types")
# include all primitives and strings.
module.exports.PRINTABLE_TYPE = PRINTABLE_TYPES =
  [ "byte", "short", "int", "long", "float", "double", "boolean",
    "char", "String" ]


module.exports.StubAnalysis = class StubAnalysis

  constructor: (file) ->
    @file = file
    @accesses = []

  _constructStubSpecs: (accessHistoriesJ) ->

    stubSpecTable = new StubSpecTable()

    # First, create stub specs for all of the instances with definitions
    # in the source file.
    for objectDefinition in accessHistoriesJ.keySetSync().toArraySync()

      # Correct the line number from the 1-indexed line number created
      # by JDI to the 0-indexed one used in ranges in this program
      lineNumber = objectDefinition.getLineNumberSync() - 1
      className = objectDefinition.getClassNameSync()
      objectName = objectDefinition.getNameSync()
      newClassName = (objectName.charAt 0).toUpperCase() + (objectName.slice 1)

      instanceAccessHistoriesJ = accessHistoriesJ.getSync objectDefinition
      for accessHistoryJ in instanceAccessHistoriesJ.toArraySync()
        stubSpec = @_createStubSpecForAccessHistory newClassName, accessHistoryJ
        stubSpecTable.putStubSpec className, objectName, lineNumber, stubSpec

    # All accesses on fields and methods are processed on a queue.  You can
    # consider this to be a breadth-first search through the accesses and method
    # calls in the program.
    # There's a work queue (`accesses`) that stores a list of accesses
    # and the stub that they should be added to.  It's processed in FIFO order.
    # As accesses are processed, some of them might return objects.  Then we
    # add work items for each of the accesses on those objects.
    # While this is less clean to read than a purely recursive solution that
    # walks the access history tree, it was our solution to avoiding a
    # stack overflow, given the depth of access history trees.
    while @accesses.length > 0

      access = @accesses.shift()
      { type, data } = access
      { stub, accessJ } = data
      value = @_createValueForAccess accessJ

      if type is "field"
        { fieldName } = data
        stub.addFieldAccess fieldName, value
      else if type is "method"
        { methodName, argumentTypes } = data
        stub.addMethodCall methodName, argumentTypes, value

    stubSpecTable

  _createStubSpecForAccessHistory: (className, accessHistoryJ) ->

    instanceFieldAccessesJ = accessHistoryJ.getFieldAccessesSync()
    instanceMethodCallsJ = accessHistoryJ.getMethodCallsSync()

    # First, collect the names of all fields, and signatures of all methods.
    # Use this to create a stub with field names and method signatures.
    fieldAccesses = {}
    for fieldName in instanceFieldAccessesJ.keySetSync().toArraySync()
      fieldAccessesJ = accessHistoryJ.getFieldAccessesSync fieldName
      fieldAccesses[fieldName] =
        type: accessHistoryJ.getFieldTypeSync fieldName
        values: []

    methodCalls = []
    for methodIdJ in instanceMethodCallsJ.keySetSync().toArraySync()
      returnType = accessHistoryJ.getMethodReturnTypeSync methodIdJ
      console.log returnType
      methodCalls.push
        signature:
          name: methodIdJ.getNameSync()
          returnType: returnType
          argumentTypes: (type for type in methodIdJ.getTypeNamesSync().toArraySync())
        returnValues: []

    # Create a blank stub with the fields and methods.  This will be filled
    # out with the values and stubs returned by each access when we
    # process the `accesses` queue alter.
    stub = new StubSpec className, { fieldAccesses, methodCalls }

    # Fill a work queue with items for field accesses and method
    # calls we need to save the return values for.  These will get processed
    # in an outer loop, to avoid recursion.
    for fieldName in instanceFieldAccessesJ.keySetSync().toArraySync()
      fieldAccessesJ = accessHistoryJ.getFieldAccessesSync fieldName
      for accessJ in fieldAccessesJ.toArraySync()
        @accesses.push
          type: "field",
          data: { stub, fieldName, accessJ }

    for methodIdJ in instanceMethodCallsJ.keySetSync().toArraySync()
      methodName = methodIdJ.getNameSync()
      argumentTypes = (type for type in methodIdJ.getTypeNamesSync().toArraySync())
      returnValuesJ = accessHistoryJ.getReturnValuesSync methodIdJ
      for accessJ in returnValuesJ.toArraySync()
        @accesses.push
          type: "method",
          data: { stub, methodName, argumentTypes, accessJ }

    stub

  _createValueForAccess: (accessJ) ->
    value = undefined
    if not accessJ?
      value = null
    else if java.instanceOf accessJ, "PrimitiveAccess"
      value = accessJ.getValueSync()
    else if java.instanceOf accessJ, "AccessHistory"
      value = @_createStubSpecForAccessHistory undefined, accessJ
    value

  run: (callback, err) ->
    className = @file.getName().replace /\.java$/, ''
    pathToFile = @file.getPath().replace RegExp(@file.getName() + '$'), ''
    sootClasspath = (java.classpath.join ':') + ":" + pathToFile
    memberAccessAnalysis = new MemberAccessAnalysis()
    memberAccessAnalysis.run className, sootClasspath, (error, result) =>
      err error if error?
      if not error?
        table = @_constructStubSpecs result
        callback table
