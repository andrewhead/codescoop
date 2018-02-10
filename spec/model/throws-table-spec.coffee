{ ThrowsTable } = require "../../lib/model/throws-table"
{ Range } = require "../../lib/model/range-set"


describe "ThrowsTable", ->

  describe "deserializes JSON to a throws table", ->

    table = undefined
    beforeEach =>
      table = ThrowsTable.deserialize {
        table: {
          "[(10, 24) - (10, 41)]": [
            {
              name: "com.path.Exception"
              superclass: {
                name: "com.path.ParentException"
                superclass: {
                  name: "com.path.GrandparentException"
                }
              }
            }
          ]
          "[(20, 24) - (20, 41)]": [
            {
              name: "com.path.OtherException"
            }
          ]
        }
      }

    it "saves exceptions for each range", ->
      (expect (table.getExceptions \
        (new Range [10, 24], [10, 41])).length).toBe 1
      (expect (table.getExceptions \
        (new Range [20, 24], [20, 41])).length).toBe 1

    it "reconstructs exception objects for each entry", ->
      exception = table.getExceptions(new Range [10, 24], [10, 41])[0]
      (expect exception.getName()).toBe "com.path.Exception"
      (expect exception.getSuperclass().getName()).toBe \
        "com.path.ParentException"
      (expect exception.getSuperclass().getSuperclass().getName()).toBe \
        "com.path.GrandparentException"
