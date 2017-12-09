{ JAVA_CLASSPATH, java } = require '../config/paths'
{ Range } = require '../model/range-set'
{ Symbol } = require '../model/symbol-set'
DataflowAnalysis = java.import "DataflowAnalysis"


# The naming convention differs slightly for this file.
# Any object that represents an object in the Java
# runtime has the suffix "J".  No objects with this suffix
# should be passed out from this interface.
module.exports.VariableDefUseAnalysis = class VariableDefUseAnalysis

  constructor: (file) ->
    @file = file

  _javaSymbolAppearanceToSymbol: (symbolAppearance) ->
    name = symbolAppearance.getSymbolNameSync()
    type = symbolAppearance.getTypeSync().toStringSync()
    startRow = symbolAppearance.getStartLineSync() - 1
    endRow = symbolAppearance.getEndLineSync() - 1
    startColumn = symbolAppearance.getStartColumnSync()
    endColumn = symbolAppearance.getEndColumnSync()
    new Symbol @file, name,
      (new Range [startRow, startColumn], [endRow, endColumn]), type

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
