{ JAVA_CLASSPATH, java } = require '../config/paths'
VariableTracer = java.import "VariableTracer"


# In it's simplest form, this is just a JavaScript object, with data
# accessible by indexing on source file name, line number, and variable name
# Line numbers are 0-indexes (to correspond to GitHub atom rows)
module.exports.ValueMap = class ValueMap


# While this currently relies on a Map loaded from Java using the node-java
# connector, it's reasonable to expect that this could also read in a
# pre-written local file instead.
module.exports.ValueAnalysis = class ValueAnalysis

  variableTracer: null
  values: null

  constructor: (file) ->
    @file = file

  _constructValueMap: (javaMap) ->

    valueMap = new ValueMap()

    # This is a tedious and brute force of transfer from the Java object
    # into a JavaScript object.
    for sourceFileName in javaMap.keySetSync().toArraySync()
      valueMap[sourceFileName] = {}
      sourceFileLinesJ = javaMap.getSync sourceFileName
      for lineNumber in sourceFileLinesJ.keySetSync().toArraySync()
        # Remember: in the data structure we return, we want to
        # let values be accessed by zero-indexed row number.
        correctedLineNumber = lineNumber - 1
        valueMap[sourceFileName][correctedLineNumber] = {}
        variablesJ = sourceFileLinesJ.getSync lineNumber
        for variableName in variablesJ.keySetSync().toArraySync()
          variableValuesJ = variablesJ.getSync variableName
          values = (@_getPrintableValue value \
              for value in variableValuesJ.toArraySync())
          valueMap[sourceFileName][correctedLineNumber][variableName] = values

    valueMap

  run: (callback, err) ->
    className = @file.getName().replace /\.java$/, ''
    pathToFile = @file.getPath().replace RegExp(@file.getName() + '$'), ''
    variableTracer = new VariableTracer()
    variableTracer.run className, pathToFile, (error, result) =>
      err error if error
      callback (@_constructValueMap result)
      @values = result

  _getPrintableValue: (value) ->
    if value is null
      return "null"
    if java.instanceOf value, "com.sun.jdi.StringReference"
      return "\"" + value.valueSync() + "\""
    else if java.instanceOf value, "com.sun.jdi.CharValue"
      return "'" + value.valueSync() + "'"
    # I expect all of the following values can be casted to literals,
    # though there are some I'm skeptical of (e.g., ByteValue, BooleanValue)
    else if (java.instanceOf value, "com.sun.jdi.BooleanValue") or
        (java.instanceOf value, "com.sun.jdi.ByteValue") or
        (java.instanceOf value, "com.sun.jdi.ShortValue") or
        (java.instanceOf value, "com.sun.jdi.IntegerValue") or
        (java.instanceOf value, "com.sun.jdi.LongValue")
      return String value.valueSync()
    else if java.instanceOf value, "com.sun.jdi.ObjectReference"
      # I need to come up with something really clever here...
      return "new Object()"

    return "unknown!"
