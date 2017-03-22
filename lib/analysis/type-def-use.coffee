{ JavaParser } = require "../grammar/Java/JavaParser"
{ JavaListener } = require "../grammar/Java/JavaListener"
{ Symbol } = require "../model/symbol-set"
{ Range } = require "../model/range-set"
ParseTreeWalker = (require "antlr4").tree.ParseTreeWalker.DEFAULT


module.exports.TypeDefUseAnalysis = class TypeDefUseAnalysis

  constructor: (file, parseTree) ->
    @file = file
    @parseTree = parseTree

  run: (callback, err) ->
    typeUseFinder = new TypeUseFinder @file
    typeUses = typeUseFinder.findTypeUses @parseTree
    typeDefFinder = new TypeDefFinder @file
    typeDefs = typeDefFinder.findTypeDefs @parseTree
    callback { typeDefs, typeUses }


_symbolFromIdNode = (file, idNode) ->
  new Symbol file, idNode.text, (new Range \
    [idNode.line - 1, idNode.column],
    [idNode.line - 1, idNode.column + (idNode.stop - idNode.start) + 1]),
    "Class"


class TypeUseVisitor extends JavaListener

  IGNORED_CLASS_NAMES: ["String", "Object"]

  constructor: (file) ->
    @file = file
    @typeUses = []

  enterTypeType: (ctx) ->
    if ctx.children[0].ruleIndex is JavaParser.RULE_classOrInterfaceType
      classOrInterfaceTypeCtx = ctx.children[0]
      classNode = classOrInterfaceTypeCtx.children[0].symbol
      symbol = _symbolFromIdNode @file, classNode
      if symbol.getName() not in @IGNORED_CLASS_NAMES
        @typeUses.push symbol

  enterCreatedName: (ctx) ->
    if "symbol" of ctx.children[0]
      symbol = _symbolFromIdNode @file, ctx.children[0].symbol
      if symbol.getName() not in @IGNORED_CLASS_NAMES
        @typeUses.push symbol

  getTypeUses: ->
    @typeUses


class TypeDefVisitor extends JavaListener

  constructor: (file) ->
    @file = file
    @typeDefs = []

  enterEnumDeclaration: (ctx) ->
    symbol = _symbolFromIdNode @file, ctx.children[1].symbol
    @typeDefs.push symbol

  enterInterfaceDeclaration: (ctx) ->
    symbol = _symbolFromIdNode @file, ctx.children[1].symbol
    @typeDefs.push symbol

  enterClassDeclaration: (ctx) ->
    symbol = _symbolFromIdNode @file, ctx.children[1].symbol
    @typeDefs.push symbol

  getTypeDefs: ->
    @typeDefs


module.exports.TypeUseFinder = class TypeUseFinder

  constructor: (file) ->
    @file = file

  findTypeUses: (parseTree) ->
    typeUseVisitor = new TypeUseVisitor @file
    ParseTreeWalker.walk typeUseVisitor, parseTree.getRoot()
    typeUses = typeUseVisitor.getTypeUses()
    typeUses


module.exports.TypeDefFinder = class TypeDefFinder

  constructor: (file) ->
    @file = file

  findTypeDefs: (parseTree) ->
    typeDefVisitor = new TypeDefVisitor @file
    ParseTreeWalker.walk typeDefVisitor, parseTree.getRoot()
    typeDefs = typeDefVisitor.getTypeDefs()
    typeDefs
