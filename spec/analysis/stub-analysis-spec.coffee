{ StubAnalysis } = require "../../lib/analysis/stub-analysis"
{ StubSpec } = require "../../lib/model/stub"
{ File } = require "../../lib/model/symbol-set"
{ PACKAGE_PATH } = require "../../lib/config/paths"


describe "StubAnalysis", ->

  it "creates stubs for objects defined in the file", ->
    file = new File \
      (PACKAGE_PATH + "/java/tests/analysis_examples/AccessSampler.java"),
      "AccessSampler.java"
    analysis = new StubAnalysis file

    stubSpecTable = undefined
    runs =>
      analysis.run ((result) =>
        stubSpecTable = result
      ), console.error

    waitsFor =>
      stubSpecTable?

    # XXX: While it's sloppy to run all of the tests in a single "runs" block,
    # stub analysis is pretty expensive (it will take a couple of seconds),
    # and this is the only way I could figure out to do it once.
    runs =>

      # A spec should have been created for obj and obj2
      (expect stubSpecTable.getSize()).toBe 2
      stubSpec = (stubSpecTable.getStubSpecs "AccessSampler", "obj", 32)[0]

      # First, the class name should be the object name, capitalized
      # TODO: At some point, we have to make sure we don't reuse the same
      # class name twice.  For now, we're assuming it won't come up
      (expect stubSpec.getClassName()).toEqual "Obj"

      # Check on fields, returning multiple values for them, and both
      # primitives, instances, strings, and nulls as field values
      fieldAccesses = stubSpec.getFieldAccesses()
      (expect Object.keys(fieldAccesses).length).toBe 4
      (expect fieldAccesses["primitiveField"]).toEqual \
        { type: "int", values: [1, 2] }
      objectAccess = fieldAccesses["objectField"]
      (expect objectAccess.values[0] instanceof StubSpec).toBe true
      (expect fieldAccesses["nullField"].values).toEqual [ null ]
      (expect fieldAccesses["stringField"]).toEqual \
        { type: "String", values: ["Hello world"] }

      # Expected calls: 'doPrimitiveWork', 'doObjectWork', 'setField', 'getNull'
      methodCalls = stubSpec.getMethodCalls()
      methodCalls = methodCalls.filter ((call) => call.returnValues.length > 0)
      (expect methodCalls.length).toBe 4

      # Check on the signature of a function that returns a primitive value
      doPrimitiveWorkCalls = methodCalls.filter (call) =>
        call.signature.name is "doPrimitiveWork"
      (expect doPrimitiveWorkCalls[0]).toEqual {
        signature:
          name: "doPrimitiveWork"
          returnType: "int"
          argumentTypes: ["int"]
        returnValues: [42, 42]
      }

      # Check on the calls to an object returned by a method
      doObjectWorkCalls = methodCalls.filter (call) =>
        call.signature.name is "doObjectWork"
      objectReturn = doObjectWorkCalls[0].returnValues[0]
      (expect objectReturn instanceof StubSpec)
      objectCalls = objectReturn.getMethodCalls()
      objectCalls = objectCalls.filter ((call) => call.returnValues.length > 0)
      (expect objectCalls[0].signature.name).toEqual "size"
      (expect objectCalls[0].returnValues.length).toBe 1

      # Methods that return an object should be marked as returning "instance"
      (expect doObjectWorkCalls[0].signature.returnType).toEqual "instance"

      # Our stub analysis should be able to find null values, too
      # But the method should still be marked as returning an instance
      getNullCalls = methodCalls.filter (call) =>
        call.signature.name is "getNull"
      (expect getNullCalls[0].signature.returnType).toEqual "instance"
      (expect getNullCalls[0].returnValues).toEqual [null]
