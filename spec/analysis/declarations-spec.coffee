{ parse } = require "../../lib/analysis/parse-tree"
{ DeclarationsAnalysis } = require "../../lib/analysis/declarations"
{ createSymbol, SymbolSet, File } = require "../../lib/model/symbol-set"
{ Range } = require "../../lib/model/range-set"


describe "DeclarationsAnalysis", ->

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

  symbolTable = undefined

  beforeEach =>
    declarationsAnalysis = new DeclarationsAnalysis \
      (new SymbolSet {
        uses: [createSymbol "path/", "File.java", "i", [4, 8], [4, 9], "int"]
      }),
      (new File "path/", "File.java"), parseTree
    declarationsAnalysis.run ((result) =>
        symbolTable = result
      ), console.error
    waitsFor =>
      symbolTable?

  it "creates a symbol table that maps a symbol to its declaration", ->
    declarationSymbol = symbolTable.getDeclaration \
      createSymbol "path/", "File.java",  "i", [4, 8], [4, 9]
    # (expect declarationSymbol).toEqual new File "path/", "File.java"
    (expect declarationSymbol.getRange()).toEqual new Range [3, 8], [3, 9]
