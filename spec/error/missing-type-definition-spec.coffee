{ MissingTypeDefinitionDetector } = require "../../lib/error/missing-type-definition"
{ MissingTypeDefinitionError } = require "../../lib/error/missing-type-definition"
{ parse } = require "../../lib/analysis/parse-tree"
{ Range, ClassRange } = require "../../lib/model/range-set"
{ File, Symbol } = require "../../lib/model/symbol-set"
{ ExampleModel } = require "../../lib/model/example-model"
{ Import, ImportTable } = require "../../lib/model/import"


describe "MissingTypeDefinitionDetector", ->

  ### The error detection below is based on this fictional code snippet:
  code = [
    "import com.ImportedClass;"
    ""
    "public class Book {"
    ""
    "  private class InnerClass {}"
    ""
    "  private ImportedClass myImportedClass;"
    "  private Book myBook;"
    "  private InnerClass innerClass;"
    "  private UnsupportedOperationException exception;"
    "  private java.lang.UnsupportedOperationException exception;"
    ""
    "}"
  ].join "\n"
  ###

  testFile = new File "path", "filename"
  model = undefined
  detector = undefined
  importTable = undefined

  beforeEach =>

    model = new ExampleModel()

    # Add the results of a mock def-use analysis to the model
    model.getSymbols().setTypeUses [
      new Symbol testFile, "ImportedClass", (new Range [6, 10], [6, 23]), "Class"
      new Symbol testFile, "Book", (new Range [7, 10], [7, 14]), "Class"
      new Symbol testFile, "InnerClass", (new Range [8, 10], [8, 20]), "Class"
      new Symbol testFile, "UnsupportedOperationException", (new Range [9, 10], [9, 39]), "Class"
      new Symbol testFile, "java.lang.UnsupportedOperationException", (new Range [9, 10], [9, 49]), "Class"
    ]
    model.getSymbols().setTypeDefs [
      new Symbol testFile, "InnerClass", (new Range [4, 16], [4, 26]), "Class"
      new Symbol testFile, "Book", (new Range [2, 13], [2, 17]), "Class"
    ]

    # Add a table of classes and the packages they are imported from
    importTable = new ImportTable
    importTable.addImport "ImportedClass", \
      new Import "com.ImportedClass", new Range [0, 7], [0, 24]
    model.setImportTable importTable

    detector = new MissingTypeDefinitionDetector()

  it "reports a missing definition if a relevant import is not in the import set", ->
    model.getRangeSet().getSnippetRanges().push new Range [6, 0], [6, 40]
    errors = detector.detectErrors model
    (expect errors.length).toBe 1
    (expect errors[0] instanceof MissingTypeDefinitionError).toBe true
    (expect errors[0].getSymbol().getName()).toBe "ImportedClass"
    (expect errors[0].getSymbol().getRange()).toEqual new Range [6, 10], [6, 23]

  it "reports a missing definition if the corresponding declaration is not " +
     "in the active ranges", ->
    model.getRangeSet().getSnippetRanges().push new Range [7, 0], [7, 22]
    errors = detector.detectErrors model
    (expect errors.length).toBe 1
    (expect errors[0].getSymbol().getName()).toBe "Book"
    (expect errors[0].getSymbol().getRange()).toEqual new Range [7, 10], [7, 14]

  it "doesn't report missing definitions when imports are active", ->
    model.getImports().push new Import "com.ImportedClass", Range [0, 7], [0, 24]
    model.getRangeSet().getSnippetRanges().push new Range [6, 0], [6, 40]
    errors = detector.detectErrors model
    (expect errors.length).toBe 0

  it "doesn't report missing definitions when a declaration is active", ->
    model.getRangeSet().getSnippetRanges().push new Range [3, 0], [0, 29]
    model.getRangeSet().getSnippetRanges().push new Range [7, 0], [7, 22]
    errors = detector.detectErrors model
    (expect errors.length).toBe 0

  it "doesn't report missing definitions when a class has been defined " +
      "in one of the model's class ranges", ->
    model.getRangeSet().getSnippetRanges().push new Range [8, 0], [8, 32]
    typeDef = new Symbol testFile, "InnerClass", (new Range [8, 10], [8, 20]), "Class"
    model.getRangeSet().getClassRanges().push new ClassRange \
      (new Range [4, 0], [4, 29]), typeDef, false
    errors = detector.detectErrors model
    (expect errors.length).toBe 0

  it "doesn't report missing definitions for types imported by default", ->
    # These two uses include with and without a 'java.lang prefix'
    model.getRangeSet().getSnippetRanges().push new Range [9, 0], [9, 50]
    model.getRangeSet().getSnippetRanges().push new Range [10, 0], [10, 60]
    errors = detector.detectErrors model
    (expect errors.length).toBe 0
