{ StubSpec, StubSpecTable } = require "../../lib/model/stub"


JSON_SPEC = {
  className: "Klazz"
  fieldAccesses: {
    unused_field: {
      type: "int"
      values: []
    }
    used_field: {
      type: "String"
      values: [ "message1", "message2" ]
    }
  }
  methodCalls: [
    {
      signature: {
        name: "method1"
        returnType: "int"
        argumentTypes: [ "int" ]
      }
      returnValues: [ 1, 2 ]
    }
    {
      signature: {
        name: "method2"
        returnType: "void"
        argumentTypes: []
      }
      returnValues: []
    }
  ]
}


describe "StubSpec", ->

  describe "deserializes JSON to a spec", ->

    stubSpec = undefined
    beforeEach =>
      stubSpec = StubSpec.deserialize JSON_SPEC

    it "deserializes the class name", ->
      (expect stubSpec.className).toBe "Klazz"

    it "deserializes field accesses", ->
      (expect stubSpec.getFieldAccesses()).toEqual {
          unused_field:
            type: "int"
            values: []
          used_field:
            type: "String"
            values: [ "message1", "message2" ]
        }

    it "deserializes method calls", ->
      (expect stubSpec.getMethodCalls()).toEqual [
          {
            signature:
              name: "method1"
              returnType: "int"
              argumentTypes: [ "int" ]
            returnValues: [ 1, 2 ]
          }
          {
            signature:
              name: "method2"
              returnType: "void"
              argumentTypes: []
            returnValues: []
          }
        ]


describe "StubSpecTable", ->

  describe "deserializes JSON to a spec table", ->

    stubSpecTable = undefined
    beforeEach =>
      stubSpecTable = StubSpecTable.deserialize {
        table: {
          Klazz: {
            object: {
              "42": [
                JSON_SPEC
                JSON_SPEC
              ]
              "43": [
                JSON_SPEC
              ]
            }
            object2: {
              "42": [
                JSON_SPEC
              ]
            }
          }
          Klazz2: {
            object3: {
              "42": [
                JSON_SPEC
              ]
            }
          }
        }
      }

    it "includes a stub spec for each record", ->
      (expect (stubSpecTable.getStubSpecs "Klazz", "object", 42).length).toBe 2
      (expect (stubSpecTable.getStubSpecs "Klazz", "object", 43).length).toBe 1
      (expect (stubSpecTable.getStubSpecs "Klazz", "object2", 42).length).toBe 1
      (expect (stubSpecTable.getStubSpecs "Klazz2", "object3", 42).length).toBe 1
