ParseTreeWalker = (require "antlr4").tree.ParseTreeWalker.DEFAULT
{ JavaListener } = require "../grammar/Java/JavaListener"
{ JavaParser } = require "../grammar/Java/JavaParser"
{ Symbol } = require "../model/symbol-set"
{ symbolFromIdNode } = require "../analysis/parse-tree"


class ForDefinitionVisitor extends JavaListener

  constructor: (file) ->
    @file = file
    @defs = []

  enterForInit: (ctx) ->

    # Only consider this for loop if there's a variable declaration
    localVariableDeclaration = ctx.children[0]
    if localVariableDeclaration.ruleIndex is JavaParser.RULE_localVariableDeclaration

      # Get the name of the type of the variable.
      typeType = localVariableDeclaration.children\
        [localVariableDeclaration.children.length - 2]
      typeName = typeType.getText()

      # Consider each of the declarators.
      variableDeclarators = localVariableDeclaration.children\
        [localVariableDeclaration.children.length - 1]
      for variableDeclaratorsChild in variableDeclarators.children

        if variableDeclaratorsChild.ruleIndex is JavaParser.RULE_variableDeclarator
          variableDeclarator = variableDeclaratorsChild

          # A declarator defines a variable if it's more than just a variable
          # name, i.e. if it has more than one child node.
          if variableDeclarator.children.length > 1
            variableId = variableDeclarator.children[0].children[0].symbol
            @defs.push symbolFromIdNode @file, variableId, typeType.getText()

  getDefs: ->
    @defs


# Extracts symbols for all variables defined in for loop initialization.
module.exports.extractForLoopDefs = extractForLoopDefs = (file, parseTree) ->
  visitor = new ForDefinitionVisitor file
  ParseTreeWalker.walk visitor, parseTree.getRoot()
  visitor.getDefs()


module.exports.ForLoopVariableDefAnalysis = class ForLoopVariableDefAnalysis

  constructor: (file, parseTree) ->
    @file = file
    @parseTree = parseTree

  run: (callback, err) ->
    callback extractForLoopDefs @file, @parseTree
