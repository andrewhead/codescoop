{ JavaParser } = require "../grammar/Java/JavaParser"
{ JavaListener } = require "../grammar/Java/JavaListener"
{ Symbol } = require "../model/symbol-set"
{ Range } = require "../model/range-set"
{ extractCtxRange, symbolFromIdNode } = require "./parse-tree"
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


class TypeUseVisitor extends JavaListener

  IGNORED_CLASS_NAMES: ["String", "Object"]

  constructor: (file) ->
    @file = file
    @typeUses = []

  _saveSymbolIfTypeIsntIgnored: (symbol) ->
    if symbol.getName() not in @IGNORED_CLASS_NAMES
      @typeUses.push symbol

  enterTypeType: (ctx) ->
    if ctx.children[0].ruleIndex is JavaParser.RULE_classOrInterfaceType
      classOrInterfaceTypeCtx = ctx.children[0]
      classNode = classOrInterfaceTypeCtx.children[0].symbol
      symbol = symbolFromIdNode @file, classNode, "Class"
      @_saveSymbolIfTypeIsntIgnored symbol

  enterCreatedName: (ctx) ->
    if "symbol" of ctx.children[0]
      symbol = symbolFromIdNode @file, ctx.children[0].symbol, "Class"
      @_saveSymbolIfTypeIsntIgnored symbol

  enterQualifiedNameList: (ctx) ->
    for child in ctx.children
      if child.ruleIndex is JavaParser.RULE_qualifiedName
        qualifiedNameCtx = child
        range = extractCtxRange qualifiedNameCtx
        text = qualifiedNameCtx.getText()
        symbol = new Symbol @file, text, range, "Class"
        @_saveSymbolIfTypeIsntIgnored symbol

  getTypeUses: ->
    @typeUses


class TypeDefVisitor extends JavaListener

  constructor: (file) ->
    @file = file
    @typeDefs = []

  enterEnumDeclaration: (ctx) ->
    symbol = symbolFromIdNode @file, ctx.children[1].symbol, "Class"
    @typeDefs.push symbol

  enterInterfaceDeclaration: (ctx) ->
    symbol = symbolFromIdNode @file, ctx.children[1].symbol, "Class"
    @typeDefs.push symbol

  enterClassDeclaration: (ctx) ->
    symbol = symbolFromIdNode @file, ctx.children[1].symbol, "Class"
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
