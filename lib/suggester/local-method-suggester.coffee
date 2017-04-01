{ extractCtxRange } = require "../analysis/parse-tree"
{ JavaParser } = require "../grammar/Java/JavaParser"


module.exports.LocalMethodSuggestion = class LocalMethodSuggestion

  constructor: (symbol, range, static_) ->
    @symbol = symbol
    @range = range
    @static = static_

  getSymbol: ->
    @symbol

  getRange: ->
    @range

  isStatic: ->
    @static


module.exports.LocalMethodSuggester = class LocalMethodSuggester

  getSuggestions: (error, model) ->

    methodUse = error.getSymbol()
    methodDefs = model.getSymbols().getMethodDefs().filter (methodDef) =>
      (methodDef.getName() is methodUse.getName()) and
        (methodDef.getFile().equals methodUse.getFile())

    suggestions = []
    methodDefs.forEach (methodDef) =>

      parseTree = model.getParseTree()
      symbolCtx = parseTree.getCtxForRange methodDef.getRange()
      parentCtx = symbolCtx

      while parentCtx?

        if parentCtx.ruleIndex is JavaParser.RULE_methodDeclaration
          classBodyDeclarationCtx = parentCtx.parentCtx.parentCtx
          methodRange = extractCtxRange classBodyDeclarationCtx

          methodIsStatic = false
          for modifierIndex in [0..classBodyDeclarationCtx.children.length - 1]
            modifierCtx = classBodyDeclarationCtx.children[modifierIndex]
            if modifierCtx.getText() is "static"
              methodIsStatic = true
              break

          suggestion = new LocalMethodSuggestion methodUse,
            methodRange, methodIsStatic
          suggestions.push suggestion

        parentCtx = parentCtx.parentCtx

    suggestions
