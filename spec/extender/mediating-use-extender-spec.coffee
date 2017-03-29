{ MediatingUseEvent } = require "../../lib/event/mediating-use"
{ ControlCrossingEvent } = require "../../lib/event/control-crossing"
{ MediatingUseExtender } = require "../../lib/extender/mediating-use-extender"
{ File, Symbol } = require "../../lib/model/symbol-set"
{ Range } = require "../../lib/model/range-set"


describe "MediatingUseExtender", ->

  extender = undefined
  testFile = undefined
  beforeEach =>
    extender = new MediatingUseExtender()

  it "returns an extension for an event with the event's mediating use", ->
    event = new MediatingUseEvent \
      (new Symbol testFile, "i", (new Range [2, 8], [2, 9]), "int"),
      (new Symbol testFile, "i", (new Range [7, 4], [7, 5]), "int"),
      (new Symbol testFile, "i", (new Range [5, 23], [5, 24]), "int")
    extension = extender.getExtension event
    (expect extension.getMediatingUse().getRange()).toEqual new Range [5, 23], [5, 24]
    (expect extension.getEvent()).toBe event

  it "returns nothing for an event that's not a MediatingUseEvent", ->
    event = new ControlCrossingEvent()
    extension = extender.getExtension event
    (expect extension).toBe null
