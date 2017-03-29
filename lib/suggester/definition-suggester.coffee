{ ScopeFinder } = require '../analysis/scope'


module.exports.DefinitionSuggestion = class DefinitionSuggestion

  constructor: (symbol) ->
    @symbol = symbol

  getSymbol: ->
    @symbol


module.exports.DefinitionSuggester = class DefinitionSuggester

  _getDeclarationScope: (symbol, parseTree) ->

    scopeFinder = new ScopeFinder symbol.getFile(), parseTree
    scopes = scopeFinder.findSymbolScopes symbol

    # Look for scopes that contain the declaration of this symbol,
    # from the most specific to the most broad scope the symbol appears in.
    # We have found the declaration when the symbol was declared in the scope
    # *and* the symbol appeared after the declaration.
    for scope in scopes
      declarations = scope.getDeclarations()
      for declaration in declarations
        # By checking for the "compare" result 0 and -1 we get both
        # ranges that coincide (definition *is* a declaration) and declarations
        # that appear before the definition.
        if (declaration.getName() is symbol.getName()) and
            ((declaration.getRange().compare symbol.getRange()) in [-1, 0])
          return scope

  getSuggestions: (error, model) ->

    use = error.getSymbol()

    parseTree = model.getParseTree()
    rangeSet = model.getRangeSet()
    symbolSet = model.getSymbols()

    # Make a copy of the defs, as sort mutates the array, and we don't want to
    # observe each of the sorting events elsewhere
    defs = symbolSet.getVariableDefs().copy()

    # Find the scope that the use was declared in
    declarationScope = @_getDeclarationScope use, parseTree

    # Consider only the definitions for the symbol that modify the same
    # variable that the use uses.  Check on this to make sure that the def
    # relates to the same declaration that the use relates to.
    defs = defs.filter (def) =>

      # If these don't have the same symbol name, skip it!
      return false if not (def.getName() is use.getName())

      defDeclarationScope = @_getDeclarationScope def, parseTree
      if defDeclarationScope is undefined
        console.log "Undefined for", def
      if defDeclarationScope.equals declarationScope
        return true

      false

    # We sort definitions such that:
    # 1. All definitions above the use appear before those below the use
    # 2. All definitions closer to the use appear before those farther
    defs.sort (def1, def2) =>

      def1BeforeUse = ((def1.getRange().compare use.getRange()) is -1)
      def2BeforeUse = ((def2.getRange().compare use.getRange()) is -1)

      # If the defs are on opposite sides of the use, sort the one
      # above the use to a lower index
      if def1BeforeUse and not def2BeforeUse
        return -1
      else if def2BeforeUse and not def1BeforeUse
        return 1

      # Otherwise, return the one closest to the use
      if def1BeforeUse and def2BeforeUse
        return def2.getRange().compare def1.getRange()
      else if not (def1BeforeUse or def2BeforeUse)
        return def1.getRange().compare def2.getRange()

    # Package the sorted defs as a list of suggestions
    ((new DefinitionSuggestion def) for def in defs)
