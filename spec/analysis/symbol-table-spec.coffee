{ parse } = require "../../lib/analysis/parse-tree"
{ buildSymbolTable, SymbolTable } = require "../../lib/analysis/symbol-table"
{ MethodScope, ClassScope } = require "../../lib/analysis/scope"
{ createSymbol, File } = require "../../lib/model/symbol-set"
{ Range } = require "../../lib/model/range-set"


fdescribe "buildSymbolTable", ->

  CODE = [
    "public class Example {"
    "  int i = 0;"
    "  public static void main(String[] args) {"
    "    int i = 0;"
    "    i = i + 1;"
    "  }"
    "}"
  ].join "\n"
  parseTree = parse CODE
  symbolTable = buildSymbolTable \
    [createSymbol "path/", "File.java", "i", [4, 8], [4, 9], "int"],
    (new File "path/", "File.java"), parseTree

  it "creates a table that maps a symbol to its declaration", ->
    declarationSymbol = symbolTable.getDeclaration \
      createSymbol "path/", "File.java",  "i", [4, 8], [4, 9]
    # (expect declarationSymbol).toEqual new File "path/", "File.java"
    (expect declarationSymbol.getRange()).toEqual new Range [3, 8], [3, 9]


fdescribe "SymbolTable", ->

  it "disambiguates symbols based on file and range", ->
    symbolTable = new SymbolTable()
    declaration = createSymbol "path/", "File.java",  "i", [3, 8], [3, 9]
    differentFileDeclaration = createSymbol "path/", "File.java", "i", [3, 8], [3, 9]
    symbol = createSymbol "path/", "File.java",  "i", [4, 8], [4, 9]
    differentFileSymbol = createSymbol "path/", "File2.java",  "i", [4, 8], [4, 9]
    differentRangeSymbol = createSymbol "path/", "File.java",  "i", [5, 8], [5, 9]

    symbolTable.putDeclaration(symbol, declaration)
    symbolTable.putDeclaration(differentFileSymbol, differentFileDeclaration)
    symbolTable.putDeclaration(differentRangeSymbol, declaration)

    (expect symbolTable.getSymbolCount()).toBe 3
