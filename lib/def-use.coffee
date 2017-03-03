{ JAVA_CLASSPATH, java } = require './paths'
DataflowAnalysis = java.import "DataflowAnalysis"
SymbolAppearance = java.import "SymbolAppearance"


###
Symbols have 4 properties: name, line, start, end
###
module.exports.DefUseAnalysis = class DefUseAnalysis

  constructor: (filePath, fileName) ->
    @filePath = filePath
    @fileName = fileName

  _javaSymbolAppearanceToSymbol: (symbolAppearance) ->
    file: @fileName
    name: symbolAppearance.getSymbolNameSync()
    # Both representations have the first line at 1
    line: symbolAppearance.getLineNumberSync()
    # The existing analysis starts at column index zero, but we
    # want to refer to symbols by their visual appearnace in the text
    # editor, where the column indexes start at 1
    start: symbolAppearance.getStartPositionSync() + 1
    end: symbolAppearance.getEndPositionSync() + 1

  getUndefinedUses: (lineIndexes) ->

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
    symbolJavaObj = new SymbolAppearance(
      symbol.name, symbol.line, symbol.start, symbol.end
    )
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
