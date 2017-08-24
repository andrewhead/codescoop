{ ScopeFinder, ClassScope } = require './scope'


# For var-args, pass in alternating file specifications and parse trees for
# the file's code.  You can provide as many files and parse trees as you want.
module.exports.buildSymbolTable = buildSymbolTable = (symbolList, args...) ->

  symbolTable = new SymbolTable()

  # Find all pairs of files and parse trees in the arguments
  for arg, argIndex in args
    file = undefined
    if (argIndex % 2) == 0
      file = arg
    else
      parseTree = arg

      scopeFinder = new ScopeFinder file, parseTree

      # For each symbol in the program, map it to its declaration:
      # 1. Find all symbols in the program (can pass in)
      for symbol in symbolList

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

  symbolTable


# A symbol table that maps from a symbol's occurrence to its declaration.
module.exports.SymbolTable = class SymbolTable

  constructor: ->
    @table = {}

  _getKeyForSymbol: (symbol) ->
    symbol.getFile().getPath() + symbol.getFile().getName() +
      symbol.getName() + symbol.getRange().toString()

  putDeclaration: (symbol, declarationSymbol) ->
    @table[@_getKeyForSymbol(symbol)] = declarationSymbol

  getDeclaration: (symbol) ->
    @table[@_getKeyForSymbol(symbol)]

  getSymbolCount: () ->
    (Object.keys @table).length
