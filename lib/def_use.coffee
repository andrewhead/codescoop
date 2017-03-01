java = require 'java'
{ JAVA_CLASSPATH } = require './paths'


# Load up the Java objects we want to use
java.classpath = java.classpath.concat JAVA_CLASSPATH
SOOT_BASE_CLASSPATH = java.classpath.join ':'
DataflowAnalysis = java.import "DataflowAnalysis"
SymbolAppearance = java.import "SymbolAppearance"
VariableTracer = java.import "VariableTracer"


###
Symbols have 4 properties: name, line, start, end
###
module.exports.DefUseAnalysis = class DefUseAnalysis

  filePath: null
  fileName: null
  analysis: null

  constructor: (filePath, fileName) ->
    @filePath = filePath
    @fileName = fileName

  getUndefinedUses: (lineIndexes) ->

      # Convert the list of selected lines to a list that can be
      # passed to our static analysis too.
      lineList = java.newInstanceSync "java.util.ArrayList"
      for lineIndex in lineIndexes

        # Note: the line indexes from the range are zero-indexed,
        # while the indexes in Soot and in the visible editor are
        # one-indexed.  So we add one to each of the lines before
        # calling on the analysis methods.
        lineList.addSync (lineIndex + 1)

      # The rest of the calls to DataflowAnalysis are pretty much
      # just operations on lists and counting.  Can do synchronounsly
      # for now to keep this code looking nice
      usesListJavaObj = @analysis.getUndefinedUsesInLinesSync(lineList)
      usesListJavaArr = usesListJavaObj.toArraySync()

      undefinedUses = []
      for use in usesListJavaArr
        # See note above about zero-indexing vs one-indexing
        symbol =
          name: use.getSymbolNameSync()
          line: use.getLineNumberSync()
          start: use.getStartPositionSync()
          end: use.getEndPositionSync()
        undefinedUses.push symbol

      undefinedUses

  getDefBeforeUse: (symbol) ->
    symbolJavaObj = new SymbolAppearance(
      symbol.name, symbol.line, symbol.start, symbol.end
    )
    definitionJavaObj = @analysis.getLatestDefinitionBeforeUseSync symbolJavaObj
    definition =
      name: definitionJavaObj.getSymbolNameSync()
      line: definitionJavaObj.getLineNumberSync()
      start: definitionJavaObj.getStartPositionSync()
      end: definitionJavaObj.getEndPositionSync()

  run: (callback, err) ->

    className = @fileName.replace /\.java$/, ''
    pathToFile = @filePath.replace RegExp(@fileName + '$'), ''

    # Make sure that Soot will be able to find the source file
    sootClasspath = SOOT_BASE_CLASSPATH + ":" + pathToFile

    # This call is more important to do asynchronously:
    # It might take a few seconds to complete.
    console.log sootClasspath
    @analysis = new DataflowAnalysis sootClasspath
    @analysis.analyze className, (error, result) =>
      if (error)
        err error
      else
        callback(@)
        # plugin.highlightUndefined()

    # At the same time as doing dataflow analysis, we also run the program
    # through a debugger to get the values of the variables at each step.
    # callback(@)
    # plugin.refreshVariableValues()
