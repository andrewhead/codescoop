{ JAVA_CLASSPATH, java } = require './paths'
VariableTracer = java.import "VariableTracer"

# While this currently relies on a Map loaded from Java using the node-java
# connector, it's reasonable to expect that this could also read in a
# pre-written local file instead.
module.exports.ValueAnalysis = class ValueAnalysis

  fileName: null
  filePath: null
  variableTracer: null
  values: null

  constructor: (filePath, fileName) ->
    @fileName = fileName
    @filePath = filePath

  run: (callback, err) ->
    classname = @fileName.replace /\.java$/, ''
    pathToFile = @filePath.replace RegExp(@fileName + '$'), ''
    variableTracer = new VariableTracer()
    variableTracer.run classname, pathToFile, (error, result) ->
      err error if error
      callback(result)
      @values = result

  # Given a variable name and a line number, get a value that it was
  # defined to have when the code was run.
  getValue: (fileName, variableName, lineNumber) ->
    # Any one of the nested maps might return null if there's no value
    # for the key, so we do a null check for each layer of lookup.
    if values?
      lineToVariableMap = values.getSync fileName
      if lineToVariableMap?
        variableToValueMap = lineToVariableMap.getSync lineNumber
        if variableToValueMap?
          value = variableToValueMap.getSync variableName

    # For the time being, we reutnr a string that could be put in a program
    @_getPrintableValue(value)

  _getPrintableValue: (value) ->
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
