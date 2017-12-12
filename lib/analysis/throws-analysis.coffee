{ JAVA_CLASSPATH, java } = require "../config/paths"
{ Range } = require "../model/range-set"
{ ThrowsTable, Exception } = require "../model/throws-table"


# See DataflowAnalysis for note about naming convention with "J" suffix
module.exports.ThrowsAnalysis = class ThrowsAnalysis

  constructor: (file) ->
    @file = file

  _constructThrowsTable: (result) ->

    # Create a table to which we'll save all records of thrown exceptions
    throwsTable = new ThrowsTable()

    # Fetch all exceptions thrown from the analysis results
    exceptionsJ = @analysis.getThrowableExceptionsSync()

    # For each entry, save the character range of the method call and the
    # exceptions that call might emit.
    for entry in exceptionsJ.entrySetSync().toArraySync()
      rangeJ = entry.getKeySync()
      range = new Range \
        [ rangeJ.getStartLineSync() - 1, rangeJ.getStartColumnSync() ],
        [ rangeJ.getEndLineSync() - 1, rangeJ.getEndColumnSync() ]
      exceptionListJ = entry.getValueSync()

      # Each entry in the exceptions list is a list of an exception type and all
      # of its superclass types.  Create an entry to the exception type, with
      # pointers to its parents.
      for exceptionHierarchyJ in exceptionListJ.toArraySync()
        superclass = undefined
        exception = undefined

        for i in [(exceptionHierarchyJ.sizeSync() - 1)..0]
          typeName = exceptionHierarchyJ.getSync i
          exception = new Exception typeName, superclass
          superclass = exception

        throwsTable.addException range, exception

    throwsTable

  run: (callback, err) ->

    className = @file.getName().replace /\.java$/, ''
    pathToFile = @file.getPath().replace RegExp(@file.getName() + '$'), ''

    # Make sure that Soot will be able to find the source file
    sootClasspath = java.classpath.join ':'

    # This call is more important to do asynchronously:
    # It might take a few seconds to complete.
    ThrowsAnalysisJ = java.import "ThrowsAnalysis"
    @analysis = new ThrowsAnalysisJ sootClasspath
    @analysis.analyze className, (error, result) =>
      if (error)
        err error
        return
      throwsTable = @_constructThrowsTable result
      callback throwsTable
