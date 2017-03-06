{ JAVA_CLASSPATH, java } = require './paths'
DataflowAnalysis = java.import "DataflowAnalysis"
SymbolAppearance = java.import "SymbolAppearance"
{ Range } = require './range-set'
{ Symbol } = require './model/symbol-set'


###
Symbols have 4 properties: name, line, start, end
###
module.exports.DefUseAnalysis = class DefUseAnalysis

  constructor: (filePath, fileName) ->
    @filePath = filePath
    @fileName = fileName

  _javaSymbolAppearanceToSymbol: (symbolAppearance) ->
    row = symbolAppearance.getLineNumberSync() - 1
    start = symbolAppearance.getStartPositionSync()
    end = symbolAppearance.getEndPositionSync()
    name = symbolAppearance.getSymbolNameSync()
    new Symbol @fileName, name,
      new Range [row, start], [row, end]

  getUndefinedUses: (ranges) ->

    # XXX: For now, this analysis just looks in the lines of Java
    # corresponding to the ranges.  We should fix this later.  In the
    # meantime, we have to convert range rows back into 1-indexed line
    # numbers for our dataflow analysis
    lineIndexes = []
    for range in ranges
      for row in range.getRows()
        if (row + 1) not in lineIndexes
          lineIndexes.push (row + 1)

    # Convert the list of selected lines to a list that can be
    # passed to our static analysis too.
    lineList = java.newInstanceSync "java.util.ArrayList"
    for lineIndex in lineIndexes

      # Note: the line indexes from the range are zero-indexed,
      # while the indexes in Soot and in the visible editor are
      # one-indexed.  So we add one to each of the lines before
      # calling on the analysis methods.
      lineList.addSync lineIndex

    # The rest of the calls to DataflowAnalysis are pretty much
    # just operations on lists and counting.  Can do synchronounsly
    # for now to keep this code looking nice
    usesListJavaObj = @analysis.getUndefinedUsesInLinesSync(lineList)
    usesListJavaArr = usesListJavaObj.toArraySync()

    undefinedUses = []
    for use in usesListJavaArr
      # See note above about zero-indexing vs one-indexing
      symbol = @_javaSymbolAppearanceToSymbol use
      undefinedUses.push symbol

    undefinedUses

  getDefBeforeUse: (symbol) ->

    # XXX: See other XXX note above about eventually supporting
    # Java symbols that have ranges instead of single lines
    symbolJavaObj = new SymbolAppearance(
      symbol.name, symbol.getRange().start.row + 1,
      symbol.getRange().start.column, symbol.getRange().end.column
    )
    console.log symbolJavaObj
    definitionJavaObj = @analysis.getLatestDefinitionBeforeUseSync symbolJavaObj
    if definitionJavaObj
      definition = @_javaSymbolAppearanceToSymbol definitionJavaObj
    else
      definition = null
    definition

  run: (callback, err) ->

    className = @fileName.replace /\.java$/, ''
    pathToFile = @filePath.replace RegExp(@fileName + '$'), ''

    # Make sure that Soot will be able to find the source file
    sootClasspath = (java.classpath.join ':') + ":" + pathToFile

    # This call is more important to do asynchronously:
    # It might take a few seconds to complete.
    @analysis = new DataflowAnalysis sootClasspath
    @analysis.analyze className, (error, result) =>
      if (error)
        err error
      else
        callback @
