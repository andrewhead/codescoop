{ ExampleModel } = require "../../lib/model/example-model"
{ MediatingUseExtension } = require "../../lib/extender/mediating-use-extender"
{ MediatingUseExtensionView } = require "../../lib/view/mediating-use-extension"
{ Range } = require "../../lib/model/range-set"
{ File, Symbol, createSymbol } = require "../../lib/model/symbol-set"


describe "MediatingUseExtensionView", ->

  model = undefined
  view = undefined
  acceptButton = undefined
  rejectButton = undefined
  extension = undefined
  suggestedRanges = undefined
  testFile = undefined

  beforeEach =>
    testFile = new File "path", "fine_name"
    extension = new MediatingUseExtension \
      (createSymbol "path", "filename", "i", [5, 23], [5, 24], "int"),
      [
        (createSymbol "path", "filename", "i", [4, 12], [4, 13], "int")
        (createSymbol "path", "filename", "i", [3, 12], [3, 13], "int")
      ]
    model = new ExampleModel()
    suggestedRanges = model.getRangeSet().getSuggestedRanges()
    view = new MediatingUseExtensionView extension, model
    rejectButton = view.find "#reject_button"

  it "adds to the suggested ranges automatically when initialized", ->
    (expect suggestedRanges.length).toBe 2

  it "removes from the suggested ranges when rejected", ->
    rejectButton.click()
    (expect suggestedRanges.length).toBe 0
