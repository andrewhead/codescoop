{ MediatingUseEvent } = require "../../lib/event/mediating-use"
{ ControlCrossingEvent } = require "../../lib/event/control-crossing"
{ MediatingUseExtender } = require "../../lib/extender/mediating-use-extender"
{ File, createSymbol } = require "../../lib/model/symbol-set"
{ Range } = require "../../lib/model/range-set"


describe "MediatingUseExtender", ->

  extender = undefined
  testFile = undefined
  beforeEach =>
    extender = new MediatingUseExtender()

  it "returns an extension for an event with the event's mediating use", ->
    event = new MediatingUseEvent \
      (createSymbol "path", "filename", "i", [2, 8], [2, 9], "int"),
      (createSymbol "path", "filename", "i", [7, 4], [7, 5], "int"),
      (createSymbol "path", "filename", "i", [5, 23], [5, 24], "int")
    extension = extender.getExtension event
    (expect extension.getMediatingUses()[0].getRange()).toEqual \
      new Range [5, 23], [5, 24]
    (expect extension.getEvents()[0]).toBe event

  it "returns an extension with all mediating uses that share the first " +
     "event's def and use", ->

    # Make a list of mediating use events, some of which should be grouped
    # together, and some of which shouldn't.
    def = (createSymbol "path", "filename", "i", [2, 8], [2, 9], "int")
    use = (createSymbol "path", "filename", "i", [7, 4], [7, 5], "int")
    _makeUse = (startPoint, endPoint) =>
      createSymbol "path", "filename", "i", startPoint, endPoint, "int"
    event = new MediatingUseEvent def, use, (_makeUse [5, 23], [5, 24])
    event2 = new MediatingUseEvent def, use, (_makeUse [4, 23], [4, 24])
    # This one shouldn't be grouped in---it doesn't share a def
    event3 = new MediatingUseEvent \
      (createSymbol "path", "filename", "i", [1, 8], [1, 9], "int"), use,
      (_makeUse [4, 23], [4, 24])
    # Neither should this one---it doesn't share a use
    event4 = new MediatingUseEvent def,
      (createSymbol "path", "filename", "i", [8, 4], [8, 5], "int"),
      (_makeUse [4, 23], [4, 24])

    extension = extender.getExtension event, [event, event2, event3, event4]
    (expect extension.getMediatingUses().length).toBe 2
    (expect extension.getMediatingUses()[0].getRange()).toEqual \
      new Range [5, 23], [5, 24]
    (expect extension.getMediatingUses()[1].getRange()).toEqual \
      new Range [4, 23], [4, 24]

  it "returns nothing for an event that's not a MediatingUseEvent", ->
    event = new ControlCrossingEvent()
    extension = extender.getExtension event
    (expect extension).toBe null
