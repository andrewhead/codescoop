{ JavaParser } = require './grammars/Java/JavaParser'
{ JavaListener } = require './grammars/Java/JavaListener'
ParseTreeWalker = (require 'antlr4').tree.ParseTreeWalker.DEFAULT
{ Symbol, File } = require './symbol-set'
{ Range } = require 'atom'
{ ParseTree } = require './parse-tree'


module.exports.ScopeType = ScopeType =
  CLASS: { value: 0, name: "class" }
  METHOD: { value: 1, name: "method" }
  BLOCK: { value: 2, name: "block" }


_symbolFromIdNode = (file, idNode) ->
  new Symbol file, idNode.text, (new Range \
    [idNode.line - 1, idNode.column],
    [idNode.line - 1, idNode.column + (idNode.stop - idNode.start) + 1])


class DeclarationVisitor extends JavaListener

  constructor: (file) ->
    @file = file
    @symbolsDeclared = []

  getDeclaredSymbols: ->
    @symbolsDeclared


# XXX: The algorithm we use ignores other scopes when the walker enters them,
# and then starts paying attention when it leaves those scopes.  Here we take
# advantage of the fact that it looks like the tree walk pre-order.  If the
# underlying tree-walking algorithm changes, we will have to update this.
class BlockDeclarationVisitor extends DeclarationVisitor

  constructor: (file, skippableScopes) ->
    super file
    @skippableScopeCtxs = (scope.getCtx() for scope in skippableScopes)
    @skip = false
    @skippedCtx = null

  enterEveryRule: (ctx) ->
    if ctx in @skippableScopeCtxs
      @skippedCtx = ctx
      @skip = true

  exitEveryRule: (ctx) ->
    if @skip and (ctx is @skippedCtx)
      @skippedCtx = null
      @skip = false

  enterVariableDeclarator: (ctx) ->
    return if @skip
    idNode = ctx.children[0].children[0].symbol
    symbol = _symbolFromIdNode @file, idNode
    @symbolsDeclared.push symbol

  enterMethodDeclaration: (ctx) ->
    return if @skip
    idNode = ctx.children[1].symbol
    symbol = _symbolFromIdNode @file, idNode
    @symbolsDeclared.push symbol


# It is assumed that this will only be called to walk starting on
# a methodDeclaration node.  The validity of results will vary if it is
# called on a different rule.
class ParameterVisitor extends DeclarationVisitor

  enterFormalParameter: (ctx) ->
    idNode = ctx.children[ctx.children.length - 1].children[0].symbol
    symbol = _symbolFromIdNode @file, idNode
    @symbolsDeclared.push symbol


class MatchVisitor extends JavaListener

  # The constructor takes in a single argument:
  # a function that takes in an ANTLR parse tree context (node) and returns
  # true if the context matches a pattern, and false otherwise
  constructor: (matchFunc) ->
    @matchFunc = matchFunc
    @matchingContexts = []

  enterEveryRule: (ctx) ->
    if @matchFunc ctx
      @matchingContexts.push ctx

  getMatchingContexts: ->
    @matchingContexts


module.exports.Scope = class Scope

  constructor: (file, ctx, type) ->
    @file = file
    @ctx = ctx
    @type = type

  getCtx: ->
    @ctx

  getType: ->
    @type

  getDeclaredSymbols: ->

    declaredSymbols = []

    # Find all nested scopes.  We want to ignore any
    # declarations from within these scopes.
    scopeFinder = new ScopeFinder @file, new ParseTree @ctx
    allScopes = scopeFinder.findAllScopes()
    nestedScopes = []
    for scope in allScopes
      (nestedScopes.push scope) if (not scope.equals @)

    blockVisitor = new BlockDeclarationVisitor @file, nestedScopes
    ParseTreeWalker.walk blockVisitor, @ctx
    declaredSymbols = blockVisitor.getDeclaredSymbols()

    # If this is a method, we also have to check the parameters
    if @type is ScopeType.METHOD
      methodDeclarationCtx = @ctx.parentCtx.parentCtx
      parameterVisitor = new ParameterVisitor @file
      ParseTreeWalker.walk parameterVisitor, methodDeclarationCtx
      declaredSymbols = declaredSymbols.concat parameterVisitor.getDeclaredSymbols()

    # If this is a class, then we declared the class name right above
    if @type is ScopeType.CLASS
      symbol = _symbolFromIdNode @file, @ctx.parentCtx.children[1].symbol
      declaredSymbols.push symbol

    declaredSymbols

  equals: (other) ->
    (@ctx is other.ctx) and (@type is other.type)


module.exports.ScopeFinder = class ScopeFinder

  constructor: (file, parseTree) ->
    @file = file
    @parseTree = parseTree

    # Matching rules are in order of decreasing specificity:
    # scopes cannot match more than one rule, and will match earlier rules first.
    @scopeMatchRules = [{
        type: ScopeType.CLASS,
        rule: (ctx) => ctx.ruleIndex is JavaParser.RULE_classBody
      }, {
        type: ScopeType.METHOD,
        rule: (ctx) =>
          if ctx.ruleIndex is JavaParser.RULE_block and ctx.parentCtx?
            return ctx.parentCtx.ruleIndex in
              [JavaParser.RULE_methodBody, JavaParser.RULE_constructorBody]
          return false
      }, {
        # This one should cover loops, conditionals, and
        # other blocks of statements not attached to control
        type: ScopeType.BLOCK,
        rule: (ctx) => ctx.ruleIndex is JavaParser.RULE_block
      }
    ]

  findAllScopes: ->

    scopes = []
    matchedCtxs = []

    for scopeMatchRule in @scopeMatchRules

      visitor = new MatchVisitor scopeMatchRule.rule
      ParseTreeWalker.walk visitor, @parseTree.getRoot()
      for ctx in visitor.getMatchingContexts()
        if ctx not in matchedCtxs
          scopes.push (new Scope @file, ctx, scopeMatchRule.type)
          matchedCtxs.push ctx

    scopes

  findSymbolScopes: (symbol) ->

    symbolScopes = []

    # First, get all possible scopes in the program
    allScopes = @findAllScopes()

    # Then, find the node in the tree corresponding to the symbol.
    # Start climbing the tree, checking to see if we arrive at
    # any of the contexts that represent a scope.  For each
    # context that we find, save a reference to that scope.
    node = @parseTree.getNodeForSymbol symbol
    if node?
      parentCtx = node.parentCtx
      while parentCtx?
        for scope in allScopes
          if parentCtx is scope.getCtx()
            symbolScopes.push scope
        parentCtx = parentCtx.parentCtx

    symbolScopes
