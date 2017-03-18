{ JAVA_CLASSPATH, java } = require "../config/paths"
{ StubSpec, StubSpecTable } = require "../model/stub-spec"
MemberAccessAnalysis = java.import "MemberAccessAnalysis"


module.exports.StubAnalysis = class StubAnalysis

  constructor: (file) ->
    @file = file

  _createValueForAccess: (accessJ) ->
    value = null
    if java.instanceOf accessJ, "PrimitiveAccess"
      value = accessJ.getValueSync()
    else if java.instanceOf accessJ, "AccessHistory"
      value = @_createStubSpecForAccessHistory undefined, accessJ
    value

  _createStubSpecForAccessHistory: (className, accessHistoryJ) ->

    instanceFieldAccessesJ = accessHistoryJ.getFieldAccessesSync()
    instanceMethodCallsJ = accessHistoryJ.getMethodCallsSync()

    # Convert the results of all accesses to fields
    fieldAccesses = {}
    for fieldName in instanceFieldAccessesJ.keySetSync().toArraySync()
      fieldAccessesJ = accessHistoryJ.getFieldAccessesSync fieldName
      values = []
      for accessJ in fieldAccessesJ.toArraySync()
        values.push @_createValueForAccess accessJ
      fieldAccesses[fieldName] =
        type: accessHistoryJ.getFieldTypeSync fieldName
        values: values

    # Convert the return values of all method calls
    methodCalls = []
    for methodIdJ in instanceMethodCallsJ.keySetSync().toArraySync()
      returnValuesJ = accessHistoryJ.getReturnValuesSync methodIdJ
      returnValues = []
      for accessJ in returnValuesJ.toArraySync()
        returnValues.push @_createValueForAccess accessJ
      returnType = undefined
      if returnValues.length > 0 and java.instanceOf accessJ, "AccessHistory"
        returnType = "instance"
      else
        returnType = accessHistoryJ.getMethodReturnTypeSync methodIdJ
      methodCalls.push
        signature:
          name: methodIdJ.getNameSync()
          returnType: returnType
          argumentTypes: (type for type in methodIdJ.getTypeNamesSync().toArraySync())
        returnValues: returnValues

    # Create and return the stub for this instance
    new StubSpec className, { fieldAccesses, methodCalls }

  _constructStubSpecs: (accessHistoriesJ) ->

    stubSpecTable = new StubSpecTable()
    for objectDefinition in accessHistoriesJ.keySetSync().toArraySync()

      # We correct the line number from the 1-indexed line number created
      # by JDI to the 0-indexed one used in ranges in this program
      lineNumber = objectDefinition.getLineNumberSync() - 1
      className = objectDefinition.getClassNameSync()
      objectName = objectDefinition.getNameSync()
      newClassName = (objectName.charAt 0).toUpperCase() + (objectName.slice 1)

      instanceAccessHistoriesJ = accessHistoriesJ.getSync objectDefinition
      for accessHistoryJ in instanceAccessHistoriesJ.toArraySync()
        stubSpec = @_createStubSpecForAccessHistory newClassName, accessHistoryJ
        stubSpecTable.putStubSpec className, objectName, lineNumber, stubSpec

    stubSpecTable

  run: (callback, err) ->
    className = @file.getName().replace /\.java$/, ''
    pathToFile = @file.getPath().replace RegExp(@file.getName() + '$'), ''
    sootClasspath = (java.classpath.join ':') + ":" + pathToFile
    memberAccessAnalysis = new MemberAccessAnalysis()
    memberAccessAnalysis.run className, sootClasspath, (error, result) =>
      err error if error?
      callback (@_constructStubSpecs result) if not error?
