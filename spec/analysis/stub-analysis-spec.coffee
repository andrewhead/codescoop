{ StubAnalysis } = require "../../lib/analysis/stubs"
{ StubSpec } = require "../../lib/model/stub-spec"
{ File } = require "../../lib/model/symbol-set"
{ PACKAGE_PATH } = require "../../lib/config/paths"


describe "StubAnalysis", ->

  it "creates stubs for objects defined in the file", ->
    file = new File \
      (PACKAGE_PATH + "/java/tests/analysis_examples/AccessSampler.java"),
      "AccessSampler.java"
    analysis = new StubAnalysis file

    stubSpecs = undefined
    runs =>
      analysis.run ((result) =>
        stubSpecs = result
      ), console.error

    waitsFor =>
      stubSpecs?

    # XXX: While it's sloppy to run all of the tests in a single "runs" block,
    # stub analysis is pretty expensive (it will take a couple of seconds),
    # and this is the only way I could figure out to do it once.
    runs =>

      # A spec should have been created for obj and obj2
      (expect stubSpecs.length).toBe 2
      stubSpec = stubSpecs[0]

      # First, the class name should be the object name, capitalized
      # TODO: At some point, we have to make sure we don't reuse the same
      # class name twice.  For now, we're assuming it won't come up
      (expect stubSpec.getClassName()).toEqual "Obj"

      # Check on fields, returning multiple values for them, and both
      # primitives and instances as field values
      fieldAccesses = stubSpec.getFieldAccesses()
      (expect Object.keys(fieldAccesses).length).toBe 2
      (expect fieldAccesses["primitiveField"]).toEqual \
        { type: "int", values: [1, 2] }
      objectAccess = fieldAccesses["objectField"]
      (expect objectAccess.values[0] instanceof StubSpec).toBe true

      # Expected calls are 'doPrimitiveWork', 'doObjectWork', and 'setField'
      methodCalls = stubSpec.getMethodCalls()
      methodCalls = methodCalls.filter ((call) => call.returnValues.length > 0)
      (expect methodCalls.length).toBe 3

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
