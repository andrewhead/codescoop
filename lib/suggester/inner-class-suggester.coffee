{ extractCtxRange } = require "../analysis/parse-tree"
{ JavaParser } = require "../grammar/Java/JavaParser"


module.exports.InnerClassSuggestion = class InnerClassSuggestion

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


module.exports.InnerClassSuggester = class InnerClassSuggester

  getSuggestions: (error, model) ->

    typeUse = error.getSymbol()
    typeDefsForType = model.getSymbols().getTypeDefs().filter (typeDef) =>
      (typeDef.getName() is typeUse.getName()) and
        (typeDef.getFile().equals typeUse.getFile())

    suggestions = []

    typeDefsForType.forEach (typeDef) =>

      parseTree = model.getParseTree()
      symbolCtx = parseTree.getCtxForRange typeDef.getRange()
      parentCtx = symbolCtx

      while parentCtx?

        if parentCtx.ruleIndex is JavaParser.RULE_classBodyDeclaration
          memberDeclarationCtx = parentCtx.children[parentCtx.children.length - 1]
          memberDeclarationChildCtx = memberDeclarationCtx.children[0]

          if memberDeclarationChildCtx.ruleIndex is JavaParser.RULE_classDeclaration
            classDeclarationCtx = memberDeclarationChildCtx
            className = classDeclarationCtx.children[1].symbol.text

            # At this point, we know the ctx is a class declaration for
            # this class.  Now create the suggestion.
            if className is typeDef.getName()

              classIsStatic = false
              for modifierIndex in [0..parentCtx.children.length - 1]
                modifierCtx = parentCtx.children[modifierIndex]
                if modifierCtx.getText() is "static"
                  classIsStatic = true
                  break

              suggestion = new InnerClassSuggestion typeUse,
                (extractCtxRange parentCtx), classIsStatic
              suggestions.push suggestion

        parentCtx = parentCtx.parentCtx

    suggestions
