{ ExampleModel } = require "../../lib/model/example-model"
{ ArchiveEvent } = require "../../lib/command/archive-event"


describe "ArchiveEvent", ->

  model = undefined
  beforeEach =>
    model = new ExampleModel()

  it "moves the archived event to the front of events when reverted", ->
    event = { eventId: 42 }
    model.getViewedEvents().push event
    model.getEvents().push { eventId: 43 }
    command = new ArchiveEvent event
    command.revert model
    (expect model.getViewedEvents().length).toBe 0
    (expect model.getEvents()).toEqual [ { eventId: 42 }, { eventId: 43 }]
