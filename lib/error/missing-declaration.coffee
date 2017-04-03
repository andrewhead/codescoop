{ ScopeFinder } = require '../analysis/scope'
{ JavaParser } = require "../grammar/Java/JavaParser"


module.exports.getDeclarationScope = getDeclarationScope = (symbol, parseTree) ->

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


module.exports.isSymbolDeclaredInParameters = \
    isSymbolDeclaredInParameters = (symbol, parseTree) ->

  node = parseTree.getNodeForSymbol symbol

  # Search for the method that includes this symbol
  parentCtx = node.parentCtx
  while parentCtx?
    if parentCtx.ruleIndex is JavaParser.RULE_methodDeclaration

      # Once we have found the symbol, iterate through the parameters list
      # to look for the symbol's name.
      formalParametersCtx = parentCtx.children[2]
      formalParametersListCtx = formalParametersCtx.children[1]
      for childCtx in formalParametersListCtx.children
        if (childCtx.ruleIndex is JavaParser.RULE_formalParameter) or
            (childCtx.ruleIndex is JavaParser.RULE_lastFormalParameter)
          variableDeclaratorIdCtx = childCtx.children[childCtx.children.length - 1]
          identifierNode = variableDeclaratorIdCtx.children[0]

          # If the parameter has the name of the symbol, the symbol is
          # declared in the parameters list!
          if identifierNode.getText() is symbol.getName()
            return true

    parentCtx = parentCtx.parentCtx

  false


module.exports.MissingDeclarationError = class MissingDeclarationError

  constructor: (symbol) ->
    @symbol = symbol

  getSymbol: ->
    @symbol


# Detects which symbols from a set of symbols are undeclared, given the
# current code example (represented as a set of active ranges).
module.exports.MissingDeclarationDetector = class MissingDeclarationDetector

  detectErrors: (model) ->

    parseTree = model.getParseTree()
    rangeSet = model.getRangeSet()
    symbolSet = model.getSymbols()

    # First, just look for all symbols that used in the example editor
    activeSymbols = []
    for symbol in symbolSet.getAllSymbols()
      for activeRange in rangeSet.getActiveRanges()
        if activeRange.containsRange symbol.getRange()
          activeSymbols.push symbol
          break

    # Then, we collect the active symbols that are undeclared
    missingDeclarations = []
    for symbol in activeSymbols

      scopeFinder = new ScopeFinder symbol.getFile(), parseTree
      symbolScopes = scopeFinder.findSymbolScopes symbol
      foundDeclaration = false

      # We don't need to declare any temporary symbols
      continue if symbol.getName().startsWith "$"
      # ...or the symbols that Soot implicitly marked as "this"
      continue if symbol.getName() is "this"

      # Check to see if the symbol was declared in the auxiliary declarations
      for declaration in model.getAuxiliaryDeclarations()
        if (symbol.getName() is declaration.getName()) and
           (symbol.getType() is declaration.getType())
          foundDeclaration = true
          break
      continue if foundDeclaration

      # Look for a declaration in all scopes that the symbol appears in.  Only
      # report a declaration as "found" if it is in one of the active ranges.
      for scope in symbolScopes
        for declaredSymbolText in scope.getDeclarations()
          for activeRange in rangeSet.getActiveRanges()
            if (activeRange.containsRange declaredSymbolText.getRange()) and
               (declaredSymbolText.getName() is symbol.getName())
              foundDeclaration = true

      if not foundDeclaration
        missingDeclarations.push new MissingDeclarationError symbol

    missingDeclarations
