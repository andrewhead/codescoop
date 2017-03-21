{ Import, ImportFinder, ImportAnalysis } = require "../../lib/analysis/import-analysis"
{ Range } = require "../../lib/model/range-set"
{ File } = require "../../lib/model/symbol-set"
{ parse } = require "../../lib/analysis/parse-tree"
{ PACKAGE_PATH } = require "../../lib/config/paths"


fdescribe "ImportAnalysis", ->

  importTable = undefined
  testFile = new File \
    (PACKAGE_PATH + "/java/tests/analysis_examples/ImportSampler.java"),
    "ImportSampler.java"

  beforeEach =>
    importAnalysis = new ImportAnalysis testFile
    importAnalysis.run ((result) =>
        importTable = result
      ), console.error
    waitsFor =>
      importTable?

  it "finds the wildcard imports corresponding to a class", ->
    imports = importTable.getImports "java.util.LinkedList"
    expectedImport = new Import "java.util.*", new Range [0, 7], [0, 18]
    foundImports = imports.filter (import_) => import_.equals expectedImport
    (expect foundImports.length).toBe 1

  it "can reference imports by a class's short name", ->
    imports = importTable.getImports "LinkedList"
    (expect imports.length).not.toBe 0

  it "finds concrete imports that provide a class", ->
    imports = importTable.getImports "LinkedList"
    expectedImport = new Import "java.util.LinkedList", new Range [1, 7], [1, 27]
    foundImports = imports.filter (import_) => import_.equals expectedImport
    (expect foundImports.length).toBe 1


describe "ImportFinder", ->

  codeWithImports = [
    "import java.util.*;"
    "import java.lang.Math;"
    ""
    "public class Book {}"
  ].join "\n"
  importFinder = new ImportFinder()

  it "locates imports in a parse tree", ->
    imports = importFinder.findImports codeWithImports
    (expect imports[0] instanceof Import).toBe true
    (expect imports[0].getName()).toEqual "java.util.*"
    (expect imports[0].getRange()).toEqual new Range [0, 7], [0, 18]
    (expect imports[1].getName()).toEqual "java.lang.Math"
    (expect imports[1].getRange()).toEqual new Range [1, 7], [1, 21]
