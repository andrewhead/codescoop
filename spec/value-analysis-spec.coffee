{ ValueAnalysis } = require '../lib/analysis/value-analysis'
{ PACKAGE_PATH } = require '../lib/config/paths'
{ File } = require '../lib/model/symbol-set'


describe "ValueAnalysis", ->

  describe "creates a map of values for a program runtime", ->

    testFilePath = PACKAGE_PATH + "/java/tests/analysis_examples/Example.java"
    testFileName = "Example.java"
    valueAnalysis = new ValueAnalysis new File testFilePath, testFileName

    it "includes the runtime data from executing the code", ->

      ranAnalysis = false
      map = undefined
      valueAnalysis.run ((resultMap) =>
          ranAnalysis = true
          map = resultMap
        ), console.error

      waitsFor =>
        ranAnalysis

      runs =>

        # look for the highest-level key: the source file name
        (expect "Example.java" of map).toBe true

        # includes keys for each of the executed lines
        (expect 4 of map["Example.java"]).toBe true
        (expect 5 of map["Example.java"]).toBe true
        (expect 6 of map["Example.java"]).toBe true
        (expect 8 of map["Example.java"]).toBe true

        # includes keys for variables on the executed lines
        (expect "i" of map["Example.java"][5]).toBe true
        (expect "j" of map["Example.java"][6]).toBe true

        # "includes printable values for variable by line"
        (expect map["Example.java"][5]["i"]).toBe "1"
        (expect map["Example.java"][8]["i"]).toBe "3"
