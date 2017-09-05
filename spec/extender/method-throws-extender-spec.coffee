{ MissingThrowsEvent } = require "../../lib/event/missing-throws"
{ Exception } = require "../../lib/model/throws-table"
{ ImportTable } = require "../../lib/model/import"
{ ExampleModel } = require "../../lib/model/example-model"
{ MethodThrowsExtender } = require "../../lib/extender/method-throws-extender"
{ File, Symbol } = require "../../lib/model/symbol-set"
{ Range } = require "../../lib/model/range-set"
{ partialParse } = require "../../lib/analysis/parse-tree"


describe "MethodThrowsExtender", ->

  extender = undefined
  testFile = undefined
  beforeEach =>
    importTable = new ImportTable()
    importTable.addImport "java.io.IOException", "java.io.*"
    model = new ExampleModel()
    model.setImportTable importTable
    extender = new MethodThrowsExtender model

  it "suggests an exception to throw", ->
    event = new MissingThrowsEvent \
      (new Range [5, 4], [5, 31]),
      (new Exception "java.io.IOException")
    extension = extender.getExtension event
    (expect extension.getEvent()).toBe event
    (expect extension.getThrowingRange()).toEqual new Range [5, 4], [5, 31]
    (expect extension.getSuggestedThrows()).toEqual "IOException"

  it "suggests an superclass exception if that's all that's available", ->
    event = new MissingThrowsEvent \
      (new Range [5, 4], [5, 31]),
      (new Exception "java.io.SubclassOfIOException",
        new Exception "java.io.IOException")
    extension = extender.getExtension event
    (expect extension.getSuggestedThrows()).toBe "IOException"

  it "suggests the fully-qualified name if there's no relevant import", ->
    event = new MissingThrowsEvent \
      (new Range [5, 4], [5, 31]),
      (new Exception "random.pkg.UnknownException")
    extension = extender.getExtension event
    (expect extension.getSuggestedThrows()).toBe "random.pkg.UnknownException"
