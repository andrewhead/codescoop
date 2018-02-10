{ ImportTable } = require "../../lib/model/import"
{ Range } = require "../../lib/model/range-set"


describe "ImportTable", ->

  describe "deserializes JSON into an import table", ->

    table = undefined
    beforeEach =>
      table = ImportTable.deserialize {
        table: {
          "com.path.Klazz": [
            {
              name: "com.path.Klazz"
              range: {
                start: { row: 0, column: 7 }
                end: { row: 0, column: 21 }
              }
            }
          ],
          "Klazz": [
            {
              name: "com.path.Klazz"
              range: {
                start: { row: 0, column: 7 }
                end: { row: 0, column: 21 }
              }
            }
          ]
        }
      }

    it "includes all classes from the JSON file", ->
      (expect (table.getImports "Klazz").length).toBeGreaterThan 0
      (expect (table.getImports "com.path.Klazz").length).toBeGreaterThan 0

    it "saves the name of a class's import", ->
      import_ = (table.getImports "Klazz")[0]
      (expect import_.getName()).toBe "com.path.Klazz"

    it "saves the range for the import", ->
      import_ = (table.getImports "Klazz")[0]
      (expect import_.getRange()).toEqual new Range [0, 7], [0, 21]
