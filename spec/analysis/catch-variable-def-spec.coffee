{ File, createSymbol } = require "../../lib/model/symbol-set"
{ ExampleModel } = require "../../lib/model/example-model"
{ ImportTable } = require "../../lib/model/import"
{ parse } = require "../../lib/analysis/parse-tree"
{ Range } = require "../../lib/model/range-set"
{ extractCatchDefs } = require "../../lib/analysis/catch-variable-def"


describe "extractCatchDefs", ->

  it "detects variable definitions in catch clauses", ->

    model = new ExampleModel()
    code = [
      "public class Example {"
      "  public static void main(String[] args) {"
      "    try {"
      "    } catch (Exception e) {}"
      "  }"
      "}"
    ].join "\n"
    parseTree = parse code

    importTable = new ImportTable()
    importTable.addImport "java.lang.Exception", undefined
    model.setImportTable importTable

    defs = extractCatchDefs (new File "path/", "filename"), parseTree, importTable
    (expect defs.length).toBe 1
    def = defs[0]
    (expect def.getFile()).toEqual new File "path/", "filename"
    (expect def.getRange()).toEqual new Range [3, 23], [3, 24]
    (expect def.getName()).toBe "e"
    (expect def.getType()).toBe "java.lang.Exception"
