{ ExampleModel } = require "../../lib/model/example-model"
{ MethodThrowsExtension } = require "../../lib/extender/method-throws-extender"
{ MethodThrowsExtensionView } = require "../../lib/view/method-throws-extension"
{ Range } = require "../../lib/model/range-set"


describe "MethodThrowsExtensionView", ->

  model = undefined
  view = undefined
  acceptButton = undefined
  rejectButton = undefined
  extension = undefined
  suggestedRanges = undefined

  beforeEach =>
    extension = new MethodThrowsExtension \
      "IOException", (new Range [2, 25], [2, 31])
    model = new ExampleModel()
    suggestedRanges = model.getRangeSet().getSuggestedRanges()
    view = new MethodThrowsExtensionView extension, model
    acceptButton = view.find "#accept_button"
    rejectButton = view.find "#reject_button"

  it "adds the throws and throwable ranges to the suggested ranges on " +
      "hovering over accept button", ->
    (expect suggestedRanges.length).toBe 0
    acceptButton.mouseover()
    (expect suggestedRanges.length).toBe 1
    (expect suggestedRanges[0]).toEqual new Range [2, 25], [2, 31]

  it "removes from the suggested ranges when leaving the accept button", ->
    acceptButton.mouseover()
    acceptButton.mouseout()
    (expect suggestedRanges.length).toBe 0
