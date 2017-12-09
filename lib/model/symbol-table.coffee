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

  areTheSameVariable: (symbol1, symbol2) ->
    (symbol1.getFile().equals symbol2.getFile()) and
      ((@getDeclaration symbol1).equals (@getDeclaration symbol2))
