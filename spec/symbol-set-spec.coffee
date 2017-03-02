{ SymbolSet, SymbolSetProperty } = require '../lib/symbol-set'

describe "SymbolSet", ->

  observer =
    propertyName: undefined
    propertyValue: undefined
    onPropertyChanged: (object, name, value) ->
      @object = object
      @propertyName = name
      @propertyValue = value

  it "notifies observers when an undefined use is added", ->
    symbolSet = new SymbolSet()
    symbolSet.addObserver observer
    symbolSet.addUndefinedUse { name: "sym", line: 1, start: 2, end: 3 }
    (expect observer.object).toEqual symbolSet
    (expect observer.propertyName).toBe SymbolSetProperty.UNDEFINED_USE_ADDED
    (expect observer.propertyValue).toEqual { name: "sym", line: 1, start: 2, end: 3 }
