{ SymbolTable } = require "../../lib/model/symbol-table"
{ createSymbol, createSymbolText } = require "../../lib/model/symbol-set"


describe "SymbolTable", ->

  it "disambiguates symbols based on file and range", ->
    symbolTable = new SymbolTable()
    declaration = createSymbol "path/", "File.java",  "i", [3, 8], [3, 9]
    differentFileDeclaration = createSymbol "path/", "File.java", "i", [3, 8], [3, 9]
    symbol = createSymbol "path/", "File.java",  "i", [4, 8], [4, 9]
    differentFileSymbol = createSymbol "path/", "File2.java",  "i", [4, 8], [4, 9]
    differentRangeSymbol = createSymbol "path/", "File.java",  "i", [5, 8], [5, 9]

    symbolTable.putDeclaration symbol, declaration
    symbolTable.putDeclaration differentFileSymbol, differentFileDeclaration
    symbolTable.putDeclaration differentRangeSymbol, declaration

    (expect symbolTable.getSymbolCount()).toBe 3

  it "reports when two symbols refer to the same variable", ->
    symbolTable = new SymbolTable()
    symbol1 = createSymbol "path/", "File.java",  "i", [4, 8], [4, 9]
    symbol2 = createSymbol "path/", "File.java",  "i", [5, 8], [5, 9]
    symbolTable.putDeclaration symbol1,
      (createSymbolText  "i", [3, 4], [3, 5])
    symbolTable.putDeclaration symbol2,
      (createSymbolText  "i", [3, 4], [3, 5])
    (expect symbolTable.areTheSameVariable symbol1, symbol2).toBe true

  it "reports symbols as different variables when in different files", ->
    symbolTable = new SymbolTable()
    symbol1 = createSymbol "path/", "File.java",  "i", [4, 8], [4, 9]
    symbol2 = createSymbol "path/", "File2.java",  "i", [5, 8], [5, 9]
    symbolTable.putDeclaration symbol1,
      (createSymbolText  "i", [3, 4], [3, 5])
    symbolTable.putDeclaration symbol2,
      (createSymbolText "path/", "File2.java",  "i", [3, 4], [3, 5])
    (expect symbolTable.areTheSameVariable symbol1, symbol2).toBe false

  it "reports symbols with different declarations as different variables", ->
    symbolTable = new SymbolTable()
    symbol1 = createSymbol "path/", "File.java",  "i", [4, 8], [4, 9]
    symbol2 = createSymbol "path/", "File.java",  "i", [10, 8], [10, 9]
    symbolTable.putDeclaration symbol1,
      (createSymbolText  "i", [3, 4], [3, 5])
    symbolTable.putDeclaration symbol2,
      (createSymbolText  "i", [8, 4], [8, 5])
    (expect symbolTable.areTheSameVariable symbol1, symbol2).toBe false
