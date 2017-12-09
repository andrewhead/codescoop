{ JavaParser } = require "../grammar/Java/JavaParser"
{ JavaListener } = require "../grammar/Java/JavaListener"
{ symbolFromIdNode } = require "./parse-tree"
ParseTreeWalker = (require "antlr4").tree.ParseTreeWalker.DEFAULT


class MethodDefVisitor extends JavaListener

  constructor: (file) ->
    @file = file
    @methodDefs = []

  enterMethodDeclaration: (ctx) ->
    methodNameNode = ctx.children[1].symbol
    symbol = symbolFromIdNode @file, methodNameNode, "Method"
    @methodDefs.push symbol

  getMethodDefs: ->
    @methodDefs


class MethodUseVisitor extends JavaListener

  constructor: (file) ->
    @file = file
    @methodUses = []

  enterExpression: (ctx) ->

    # One way to tell if an expression is a method call is to look for opening
    # and closing parentehses that will contain arguments
    return if ctx.children.length < 3
    if (ctx.children[1].getText() is "(") and
        (ctx.children[ctx.children.length - 1].getText() is ")")

      # Currently, we only check for calls to other local, named methods.
      # So we need to do a few checks.  By checking that the first child
      # ctx is a primary, we know this isn't a method call on some other
      # object, but it's a standalone method call.  If the leaf node of the
      # first child is an identifier, then this isn't a call to `this` or `super`
      expressionCtx = ctx.children[0]
      firstChildCtx = expressionCtx.children[0]
      if (firstChildCtx.ruleIndex is JavaParser.RULE_primary)

        idNode = firstChildCtx.children[0]
        return if not "symbol" of idNode
        return if not (idNode.symbol.type is JavaParser.Identifier)

        symbol = symbolFromIdNode @file, idNode.symbol, "Method"
        @methodUses.push symbol

  getMethodUses: ->
    @methodUses


module.exports.MethodDefFinder = class MethodDefFinder

  constructor: (file) ->
    @file = file

  findMethodDefs: (parseTree) ->
    methodDefVisitor = new MethodDefVisitor @file
    ParseTreeWalker.walk methodDefVisitor, parseTree.getRoot()
    methodDefs = methodDefVisitor.getMethodDefs()
    methodDefs


module.exports.MethodUseFinder = class MethodUseFinder

  constructor: (file) ->
    @file = file

  findMethodUses: (parseTree) ->
    methodUseVisitor = new MethodUseVisitor @file
    ParseTreeWalker.walk methodUseVisitor, parseTree.getRoot()
    methodUses = methodUseVisitor.getMethodUses()
    methodUses


module.exports.MethodDefUseAnalysis = class MethodDefUseAnalysis

  constructor: (file, parseTree) ->
    @file = file
    @parseTree = parseTree

  run: (callback, err) ->
    methodUseFinder = new MethodUseFinder @file
    methodUses = methodUseFinder.findMethodUses @parseTree
    methodDefFinder = new MethodDefFinder @file
    methodDefs = methodDefFinder.findMethodDefs @parseTree
    callback { methodDefs, methodUses }
