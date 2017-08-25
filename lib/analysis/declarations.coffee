{ SymbolTable } = require "../model/symbol-table"
{ ClassScope, ScopeFinder } = require "./scope"


module.exports.DeclarationsAnalysis = class DeclarationsAnalysis

  # `symbols` is a the set of symbols for the program.  This should be populated
  # during an earlier stage of analysis.
  constructor: (symbolSet, file, parseTree) ->
    @symbolSet = symbolSet
    @file = file
    @parseTree = parseTree

  run: (callback, err) ->
    symbolTable = new SymbolTable()
    scopeFinder = new ScopeFinder @file, @parseTree

    # For each symbol in the program, map it to its declaration:
    # 1. Find all symbols in the program (can pass in:
    for symbol in @symbolSet.getAllSymbols()

      # 2. Find the scope and all parent scopes for the symbol
      scopes = scopeFinder.findSymbolScopes symbol

      # 3. Go up through each of the scopes it belongs to:
      foundDeclaration = false
      for scope, parentIndex in scopes

        # 4. In each of these scopes, compare the symbol to all declarations.
        for declaration in scope.getDeclarations()

          # The declaration is correct if the symbol names match
          if symbol.getName() is declaration.getName()

             # And the declaration appears before the symbol (unless this is
             # the scope of the class, with member declarations)
            if ((scope instanceof ClassScope) and parentIndex != 0) or
                ((declaration.getRange().compare symbol.getRange()) <= 0)
              symbolTable.putDeclaration symbol, declaration
              foundDeclaration = true
              break

        if foundDeclaration
          break

    callback symbolTable
