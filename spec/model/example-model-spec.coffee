{ ExampleModel, ExampleModelProperty } = require '../../lib/model/example-model'
{ Range, RangeSet } = require "../../lib/model/range-set"
{ SymbolSet } = require "../../lib/model/symbol-set"
{ ValueMap } = require "../../lib/analysis/value-analysis"


makeEditor = -> atom.workspace.buildTextEditor()
editor = makeEditor()
editor.setText [
  "int i = 0;"
  "int j = i;"
  "i = j + 1;"
  "j = j + 1;"
  ].join '\n'
codeBuffer = editor.getBuffer()


describe "ExampleModel", ->

  observer =
    onPropertyChanged: (object, name, oldValue, newValue) ->
      @object = object
      @propertyName = name
      @propertyValue = newValue

  parseTree = jasmine.createSpyObj "parseTree", [ "getRoot" ]

  it "notifies observers when lines changed", ->
    rangeSet = new RangeSet()
    exampleModel = new ExampleModel codeBuffer, rangeSet, new SymbolSet(), parseTree, new ValueMap()
    exampleModel.addObserver observer
    rangeSet.getSnippetRanges().push new Range [0, 0], [0, 10]
    (expect observer.propertyName).toBe ExampleModelProperty.ACTIVE_RANGES
    (expect observer.propertyValue).toEqual [ new Range [0, 0], [0, 10] ]
