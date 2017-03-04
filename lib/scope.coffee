{ JavaParser } = require './grammars/Java/JavaParser'
{ JavaListener } = require './grammars/Java/JavaListener'
ParseTreeWalker = (require 'antlr4').tree.ParseTreeWalker.DEFAULT


module.exports.ScopeType = ScopeType =
  CLASS: { value: 0, name: "class" }
  BLOCK: { value: 1, name: "block" }


module.exports.Scope = class Scope

  constructor: (ctx, type) ->
    @ctx = ctx
    @type = type

  getCtx: ->
    @ctx

  getType: ->
    @type


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


module.exports.ScopeFinder = class ScopeFinder

  constructor: (parseTree) ->
    @parseTree = parseTree

  findScopes: ->

    scopeMatchRules = [{
        type: ScopeType.CLASS,
        rule: (ctx) => ctx.ruleIndex is JavaParser.RULE_classBody
      }, {
        # This one should cover methods, loops, conditionals, and
        # other blocks of statements not attached to control
        type: ScopeType.BLOCK,
        rule: (ctx) => ctx.ruleIndex is JavaParser.RULE_block
      }
    ]

    scopes = []
    for scopeMatchRule in scopeMatchRules
      visitor = new MatchVisitor scopeMatchRule.rule
      ParseTreeWalker.walk visitor, @parseTree
      for ctx in visitor.getMatchingContexts()
        scopes.push (new Scope ctx, scopeMatchRule.type)

    scopes
