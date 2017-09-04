ParseTreeWalker = (require "antlr4").tree.ParseTreeWalker.DEFAULT
{ JavaListener } = require "../grammar/Java/JavaListener"
{ JavaParser, CatchTypeContext } = require "../grammar/Java/JavaParser"
{ Symbol } = require "../model/symbol-set"
{ symbolFromIdNode } = require "../analysis/parse-tree"


class CatchDefinitionVisitor extends JavaListener

  constructor: (file, importTable) ->
    @file = file
    @importTable = importTable
    @defs = []

  enterCatchClause: (ctx) ->
    exceptionName = ctx.catchType().getText()
    qualifiedName = @importTable.getFullyQualifiedName exceptionName
    symbol = symbolFromIdNode @file, ctx.Identifier().symbol, qualifiedName
    @defs.push symbol

  getDefs: ->
    @defs


# Extracts symbols for all variables defined in for loop initialization.
module.exports.extractCatchDefs = extractCatchDefs = \
    (file, parseTree, importTable) ->
  visitor = new CatchDefinitionVisitor file, importTable
  ParseTreeWalker.walk visitor, parseTree.getRoot()
  visitor.getDefs()


module.exports.CatchVariableDefAnalysis = class CatchVariableDefAnalysis

  constructor: (file, parseTree, model) ->
    @file = file
    @parseTree = parseTree
    @model = model

  run: (callback, err) ->
    callback extractCatchDefs @file, @parseTree, @model.getImportTable()
