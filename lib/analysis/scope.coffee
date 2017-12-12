{ JavaParser } = require '../grammar/Java/JavaParser'
{ JavaListener } = require '../grammar/Java/JavaListener'
{ SymbolText, File } = require '../model/symbol-set'
{ Range } = require '../model/range-set'
{ ParseTree } = require './parse-tree'
ParseTreeWalker = (require 'antlr4').tree.ParseTreeWalker.DEFAULT


_symbolTextFromIdNode = (idNode) ->
  new SymbolText idNode.text, (new Range \
    [idNode.line - 1, idNode.column],
    [idNode.line - 1, idNode.column + (idNode.stop - idNode.start) + 1])


class DeclarationVisitor extends JavaListener

  constructor: (file) ->
    @file = file
    @symbolsDeclared = []

  getDeclarations: ->
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
    symbol = _symbolTextFromIdNode idNode
    @symbolsDeclared.push symbol

  enterMethodDeclaration: (ctx) ->
    return if @skip
    idNode = ctx.children[1].symbol
    symbol = _symbolTextFromIdNode idNode
    @symbolsDeclared.push symbol


# It is assumed that this will only be called to walk starting on
# a methodDeclaration node.  The validity of results will vary if it is
# called on a different rule.
class ParameterVisitor extends DeclarationVisitor

  enterFormalParameter: (ctx) ->
    idNode = ctx.children[ctx.children.length - 1].children[0].symbol
    symbol = _symbolTextFromIdNode idNode
    @symbolsDeclared.push symbol


# It is assumed that this will only be called on the context for the
# enhancedForControl rule; otherwise, results may be unpredictable.
class EnhancedForVisitor extends DeclarationVisitor

  enterVariableDeclaratorId: (ctx) ->
    idNode = ctx.children[0].symbol
    symbol = _symbolTextFromIdNode idNode
    @symbolsDeclared.push symbol


class CatchClauseVisitor extends DeclarationVisitor

  enterCatchClause: (ctx) ->
    symbol = _symbolTextFromIdNode ctx.Identifier().symbol
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

  constructor: (file, ctx) ->
    @file = file
    @ctx = ctx

  getCtx: ->
    @ctx

  getType: ->
    @type

  getDeclarations: ->

    declarations = []

    # Find all nested scopes.  We want to ignore any
    # declarations from within these scopes.
    # TODO(andrew): find a better solution to this that doesn't require a
    # ScopeFinder.  One option is to skip nested blocks based on ctx type.
    scopeFinder = new ScopeFinder @file, new ParseTree @ctx
    allScopes = scopeFinder.findAllScopes()
    nestedScopes = []
    for scope in allScopes
      (nestedScopes.push scope) if (not scope.equals @)

    blockVisitor = new BlockDeclarationVisitor @file, nestedScopes
    ParseTreeWalker.walk blockVisitor, @ctx
    declarations = blockVisitor.getDeclarations()

  equals: (other) ->
    (@ctx is other.ctx) and (@type is other.type)


module.exports.BlockScope = class BlockScope extends Scope

  getDeclarations: ->
    super()


module.exports.CatchClauseScope = class CatchClauseScope extends Scope

  getDeclarations: ->
    declarations = super()
    catchClauseVisitor = new CatchClauseVisitor @file, []
    ParseTreeWalker.walk catchClauseVisitor, @ctx.parentCtx
    declarations = declarations.concat catchClauseVisitor.getDeclarations()
    declarations


module.exports.ForLoopScope = class ForLoopScope extends Scope

  getDeclarations: ->

    declarations = super()

    forControlCtx = @ctx.parentCtx.parentCtx.children[2]
    forControlChildCtx = forControlCtx.children[0]

    # If this is a typical for loop, look for declarations in the init section
    if forControlChildCtx.ruleIndex is JavaParser.RULE_forInit
      forInitVisitor = new BlockDeclarationVisitor @file, []
      ParseTreeWalker.walk forInitVisitor, forControlChildCtx
      declarations = declarations.concat forInitVisitor.getDeclarations()

    # If this is an 'enhanced' for loop, use a custom visitor to find declarations.
    else if forControlChildCtx.ruleIndex is JavaParser.RULE_enhancedForControl
      enhancedForVisitor = new EnhancedForVisitor @file
      ParseTreeWalker.walk enhancedForVisitor, forControlChildCtx
      declarations = declarations.concat enhancedForVisitor.getDeclarations()

    declarations


module.exports.ClassScope = class ClassScope extends Scope

  getDeclarations: ->

    declarations = super()

    # If this is a class, then we declared the class name right above
    symbol = _symbolTextFromIdNode @ctx.parentCtx.children[1].symbol
    declarations.push symbol

    declarations


module.exports.MethodScope = class MethodScope extends Scope

  getDeclarations: ->

    declarations = super()

    # If this is a method, we also have to check the parameters
    methodDeclarationCtx = @ctx.parentCtx.parentCtx
    parameterVisitor = new ParameterVisitor @file
    ParseTreeWalker.walk parameterVisitor, methodDeclarationCtx
    declarations = declarations.concat parameterVisitor.getDeclarations()

    declarations


module.exports.ScopeFinder = class ScopeFinder

  constructor: (file, parseTree) ->
    @file = file
    @parseTree = parseTree

    # Matching rules are in order of decreasing specificity:
    # scopes cannot match more than one rule, and will match earlier rules first.
    @scopeMatchRules = [{
        type: ClassScope,
        rule: (ctx) => ctx.ruleIndex is JavaParser.RULE_classBody
      }, {
        type: MethodScope,
        rule: (ctx) =>
          if ctx.ruleIndex is JavaParser.RULE_block and ctx.parentCtx?
            return ctx.parentCtx.ruleIndex in
              [JavaParser.RULE_methodBody, JavaParser.RULE_constructorBody]
          return false
      }, {
        type: ForLoopScope,
        rule: (ctx) =>
          if ctx.ruleIndex is JavaParser.RULE_block
            try
              forText = ctx.parentCtx.parentCtx.children[0].symbol.text
          forText? and (forText is "for")
      }, {
        type: CatchClauseScope,
        rule: (ctx) =>
          ctx.ruleIndex is JavaParser.RULE_catchClause
      }, {
        # This one should cover loops, conditionals, and
        # other blocks of statements not attached to control
        type: BlockScope,
        # Don't double-list blocks as both independent and belonging to a catch.
        rule: (ctx) => ((ctx.ruleIndex is JavaParser.RULE_block) and
          ((not ctx.parentCtx?) or
            ctx.parentCtx.ruleIndex != JavaParser.RULE_catchClause))
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
          scopes.push (new scopeMatchRule.type @file, ctx)
          matchedCtxs.push ctx

    scopes

  # Returns scopes from leaves of the tree to the base
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
