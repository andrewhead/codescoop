{ JAVA_CLASSPATH, java } = require "../config/paths"
{ StubSpec } = require "../model/stub-spec"
MemberAccessAnalysis = java.import "MemberAccessAnalysis"


# While this currently relies on a Map loaded from Java using the node-java
# connector, it's reasonable to expect that this could also read in a
# pre-written local file instead.
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
      methodCalls.push
        signature:
          name: methodIdJ.getNameSync()
          returnType: accessHistoryJ.getMethodReturnTypeSync methodIdJ
          argumentTypes: (type for type in methodIdJ.getTypeNamesSync().toArraySync())
        returnValues: returnValues

    # Create and return the stub for this instance
    new StubSpec className, { fieldAccesses, methodCalls }

  _constructStubSpecs: (accessHistoriesJ) ->

    stubSpecs = []
    for objectDefinition in accessHistoriesJ.keySetSync().toArraySync()

      objectName = objectDefinition.getNameSync()
      className = (objectName.charAt 0).toUpperCase() + (objectName.slice 1)

      instanceAccessHistoriesJ = accessHistoriesJ.getSync objectDefinition
      for accessHistoryJ in instanceAccessHistoriesJ.toArraySync()
        stubSpec = @_createStubSpecForAccessHistory className, accessHistoryJ
        stubSpecs.push stubSpec

    stubSpecs

  run: (callback, err) ->
    className = @file.getName().replace /\.java$/, ''
    pathToFile = @file.getPath().replace RegExp(@file.getName() + '$'), ''
    sootClasspath = (java.classpath.join ':') + ":" + pathToFile
    memberAccessAnalysis = new MemberAccessAnalysis()
    memberAccessAnalysis.run className, sootClasspath, (error, result) =>
      err error if error
      callback (@_constructStubSpecs result)
