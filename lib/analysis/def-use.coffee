{ JAVA_CLASSPATH, java } = require '../config/paths'
{ Range } = require '../model/range-set'
{ Symbol } = require '../model/symbol-set'
DataflowAnalysis = java.import "DataflowAnalysis"
SymbolAppearance = java.import "SymbolAppearance"


# The naming convention differs slightly for this file.
# Any object that represents an object in the Java
# runtime has the suffix "J".  No objects with this suffix
# should be passed out from this interface.
module.exports.DefUseAnalysis = class DefUseAnalysis

  constructor: (file) ->
    @file = file

  _javaSymbolAppearanceToSymbol: (symbolAppearance) ->
    name = symbolAppearance.getSymbolNameSync()
    startRow = symbolAppearance.getStartLineSync() - 1
    endRow = symbolAppearance.getEndLineSync() - 1
    startColumn = symbolAppearance.getStartColumnSync()
    endColumn = symbolAppearance.getEndColumnSync()
    new Symbol @file, name,
      new Range [startRow, startColumn], [endRow, endColumn]

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

  getDefs: ->
    defsJ = @analysis.getDefinitionsSync()
    defsArrayJ = defsJ.toArraySync()
    defs = []
    for def in defsArrayJ
      defs.push @_javaSymbolAppearanceToSymbol def
    defs

  getUses: ->
    usesJ = @analysis.getUsesSync()
    usesArrayJ = usesJ.toArraySync()
    uses = []
    for use in usesArrayJ
      uses.push @_javaSymbolAppearanceToSymbol use
    uses

  getDefBeforeUse: (symbol) ->

    # XXX: See other XXX note above about eventually supporting
    # Java symbols that have ranges instead of single lines
    symbolJavaObj = new SymbolAppearance(
      symbol.name,
      symbol.getRange().start.row + 1, symbol.getRange().start.column,
      symbol.getRange().end.row + 1, symbol.getRange().end.column
    )
    definitionJavaObj = @analysis.getLatestDefinitionBeforeUseSync symbolJavaObj
    if definitionJavaObj
      definition = @_javaSymbolAppearanceToSymbol definitionJavaObj
    else
      definition = null
    definition

  run: (callback, err) ->

    className = @file.getName().replace /\.java$/, ''
    pathToFile = @file.getPath().replace RegExp(@file.getName() + '$'), ''

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
