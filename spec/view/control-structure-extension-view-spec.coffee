{ ExampleModel } = require "../../lib/model/example-model"
{ ControlStructureExtension } = require "../../lib/extender/control-structure-extender"
{ ControlStructureExtensionView } = require "../../lib/view/control-structure-extension"
{ Range } = require "../../lib/model/range-set"
{ IfControlStructure } = require "../../lib/analysis/parse-tree"


describe "ControlStructureExtensionView", ->

  model = undefined
  view = undefined
  acceptButton = undefined
  rejectButton = undefined
  extension = undefined
  suggestedRanges = undefined

  beforeEach =>
    extension = new ControlStructureExtension \
      (new IfControlStructure null),
      [(new Range [0, 1], [0, 2]), new Range [1, 2], [2, 3]]
    model = new ExampleModel()
    suggestedRanges = model.getRangeSet().getSuggestedRanges()
    view = new ControlStructureExtensionView extension, model
    acceptButton = view.find "#accept_button"
    rejectButton = view.find "#reject_button"

  it "adds to the suggested ranges on hovering over accept button", ->
    (expect suggestedRanges.length).toBe 0
    acceptButton.mouseover()
    (expect suggestedRanges.length).toBe 2

  it "removes from the suggested ranges when leaving the accept button", ->
    acceptButton.mouseover()
    acceptButton.mouseout()
    (expect suggestedRanges.length).toBe 0

  it "sets the decision to false when the reject button is clicked", ->
    (expect model.getExtensionDecision()).toBe null
    rejectButton.click()
    (expect model.getExtensionDecision()).toBe false

  it "sets the decision to true when the accept button is clicked", ->
    acceptButton.click()
    (expect model.getExtensionDecision()).toBe true
