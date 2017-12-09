/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
require("coffee-script/register");
const { JAVA_CLASSPATH, java } = require("../config/paths");
const PrimitiveValueAnalysis = java.import("PrimitiveValueAnalysis");


function _getPrintableValue(value) {
  if (value === null) {
    return "null";
  }
  if (java.instanceOf(value, "com.sun.jdi.StringReference")) {
    return '"' + (value.valueSync().replace(/"/, '\\"')) + '"';
  } else if (java.instanceOf(value, "com.sun.jdi.CharValue")) {
    return "'" + value.valueSync() + "'";
  // I expect all of the following values can be casted to literals,
  // though there are some I'm skeptical of (e.g., ByteValue, BooleanValue)
  } else if ((java.instanceOf(value, "com.sun.jdi.BooleanValue")) ||
      (java.instanceOf(value, "com.sun.jdi.ByteValue")) ||
      (java.instanceOf(value, "com.sun.jdi.ShortValue")) ||
      (java.instanceOf(value, "com.sun.jdi.IntegerValue")) ||
      (java.instanceOf(value, "com.sun.jdi.LongValue"))) {
    return String(value.valueSync());
  }
  return "unknown!";
}


function _constructValueMap(javaMap) {

  // In it's simplest form, this is just a JavaScript object, with data
  // accessible by indexing on source file name, line number, and variable name
  // Line numbers are 0-indexes (to correspond to GitHub atom rows)
  var valueMap = {};

  // This is a tedious and brute force of transfer from the Java object
  // into a JavaScript object.
  for (let sourceFileName of Array.from(javaMap.keySetSync().toArraySync())) {
    valueMap[sourceFileName] = {};
    const sourceFileLinesJ = javaMap.getSync(sourceFileName);
    for (let lineNumber of Array.from(sourceFileLinesJ.keySetSync().toArraySync())) {
      // Remember: in the data structure we return, we want to
      // let values be accessed by zero-indexed row number.
      const correctedLineNumber = lineNumber - 1;
      valueMap[sourceFileName][correctedLineNumber] = {};
      const variablesJ = sourceFileLinesJ.getSync(lineNumber);
      for (let variableName of Array.from(variablesJ.keySetSync().toArraySync())) {
        const variableValuesJ = variablesJ.getSync(variableName);
        const values = (Array.from(variableValuesJ.toArraySync()).map((value) => _getPrintableValue(value)));
        valueMap[sourceFileName][correctedLineNumber][variableName] = values;
      }
    }
  }
  return valueMap;
}


if (process.send) {
  const filename = process.argv[2];
  const filePath = process.argv[3];
  var returnValue = {};
  const className = filename.replace(/\.java$/, '');
  const pathToFile = filePath.replace(RegExp(filename + '$'), '');
  const classPath = (java.classpath.join(':')) + ":" + pathToFile;
  const variableTracer = new PrimitiveValueAnalysis();
  variableTracer.run(className, classPath, (error, result) => {
    if (error != null) {
      returnValue.status = "error";
      returnValue.error = error;
      process.send(returnValue);
    } else {
      returnValue.status = "ok";
      returnValue.valueMap = _constructValueMap(result);
      process.send(returnValue);
    }
  });
}
