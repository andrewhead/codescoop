{ ExampleModel } = require "../../lib/model/example-model"
{ MediatingUseExtension } = require "../../lib/extender/mediating-use-extender"
{ MediatingUseExtensionView } = require "../../lib/view/mediating-use-extension"
{ Range } = require "../../lib/model/range-set"
{ File, Symbol } = require "../../lib/model/symbol-set"


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
      (new Symbol testFile, "i", (new Range [2, 8], [2, 9]), "int"),
      (new Symbol testFile, "i", (new Range [5, 23], [5, 24]), "int")
    model = new ExampleModel()
    suggestedRanges = model.getRangeSet().getSuggestedRanges()
    view = new MediatingUseExtensionView extension, model
    acceptButton = view.find "#accept_button"
    rejectButton = view.find "#reject_button"

  it "adds to the suggested ranges on hovering over accept button", ->
    (expect suggestedRanges.length).toBe 0
    acceptButton.mouseover()
    (expect suggestedRanges.length).toBe 1

  it "removes from the suggested ranges when leaving the accept button", ->
    acceptButton.mouseover()
    acceptButton.mouseout()
    (expect suggestedRanges.length).toBe 0
