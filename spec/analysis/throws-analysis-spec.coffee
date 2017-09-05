{ ThrowsAnalysis } = require "../../lib/analysis/throws-analysis"
{ PACKAGE_PATH } = require "../../lib/config/paths"
{ File } = require "../../lib/model/symbol-set"
{ Range } = require "../../lib/model/range-set"


describe "ThrowsAnalysis", ->

  it "creates a throws table with all of the exception-throwing information", ->

    testFilePath = PACKAGE_PATH + "/java/tests/analysis_examples/Throws.java"
    testFileName = "Throws.java"
    throwsAnalysis = new ThrowsAnalysis new File testFilePath, testFileName
    throwsTable = undefined

    throwsAnalysis.run ((result) =>
        throwsTable = result
      ), console.error

    waitsFor =>
      throwsTable

    runs =>

      # Check that all of the ranges have been loaded into the table
      (expect throwsTable.getRangesWithThrows().length).toBe 8

      # Check for a few of the cases of detecting throws:
      # 1. Find a single throw on one line, with its exception hierarchy
      exceptions = throwsTable.getExceptions new Range [25, 8], [25, 31]
      (expect exceptions.length).toBe 1
      exception = exceptions[0]
      (expect exception.getName()).toBe "Throws$CustomException1"
      (expect exception.getSuperclass().getName()).toBe "java.lang.Exception"

      # 2. Find multiple exceptions on one line
      exceptions = throwsTable.getExceptions new Range [26, 8], [26, 31]
      (expect exceptions.length).toBe 2
