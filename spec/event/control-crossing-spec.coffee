{ ControlCrossingDetector, ControlCrossingEvent } = require "../../lib/event/control-crossing"
{ parse, partialParse, extractCtxRange } = require "../../lib/analysis/parse-tree"
{ IfControlStructure } = require "../../lib/analysis/parse-tree"
{ Range, RangeSet } = require "../../lib/model/range-set"
{ File, Symbol, SymbolSet } = require "../../lib/model/symbol-set"
{ ExampleModel } = require "../../lib/model/example-model"
{ JavaParser } = require "../../lib/grammar/Java/JavaParser"


_makeCodeExample = (body) =>
  [
    "public class Example {"
    "  public static void main(String[] args) {"
    body
    "  }"
    "}"
  ].join "\n"


describe "ControlCrossingDetector", ->

  detector = undefined

  beforeEach =>
    detector = new ControlCrossingDetector new ExampleModel()

  it "finds control structures the last range is in and the new one isn't", ->
    parseTree = parse _makeCodeExample [
      "    int i;"
      "    if (true) {"
      "        i = i + 1;"
      "    }"
    ].join "\n"
    lastRange = new Range [4, 8], [4, 14]
    newRange = new Range [2, 4], [2, 10]
    structures = detector.findCrossedControlStructures parseTree, lastRange, newRange
    (expect structures.length).toBe 1
    (expect structures[0] instanceof IfControlStructure).toBe true

  it "doesn't find control structures that the new range is in and the last " +
      "one isn't (in other words, isn't commutatative)", ->
    parseTree = parse _makeCodeExample [
      "    int i;"
      "    if (true) {"
      "        i = i + 1;"
      "    }"
    ].join "\n"
    lastRange = new Range [2, 4], [2, 10]
    newRange = new Range [4, 8], [4, 14]
    structures = detector.findCrossedControlStructures parseTree, lastRange, newRange
    (expect structures.length).toBe 0

  it "can find multiple crossed control structures", ->
    parseTree = parse _makeCodeExample [
      "    int i;"
      "    if (true) {"
      "        if (true) {"
      "            i = i + 1;"
      "        }"
      "    }"
    ].join "\n"
    lastRange = new Range [5, 12], [5, 16]
    newRange = new Range [2, 4], [2, 10]
    structures = detector.findCrossedControlStructures parseTree, lastRange, newRange
    (expect structures.length).toBe 2
    (expect structures[0] instanceof IfControlStructure).toBe true
    (expect structures[1] instanceof IfControlStructure).toBe true

  it "finds no crossed structures if ranges are inside the same structures", ->
    parseTree = parse _makeCodeExample [
      "    if (true) {"
      "        int i;"
      "        int j;"
      "    }"
    ].join "\n"
    lastRange = new Range [3, 8], [3, 12]
    newRange = new Range [4, 8], [4, 12]
    structures = detector.findCrossedControlStructures parseTree, lastRange, newRange
    (expect structures.length).toBe 0

  describe "when given a model", ->

    model = undefined
    detector = undefined

    beforeEach =>

      parseTree = parse _makeCodeExample [
        "    int i;"
        "    if (true) {"
        "        i = i + 1;"
        "    }"
      ].join "\n"

      model = new ExampleModel()
      model.setParseTree parseTree
      detector = new ControlCrossingDetector model

    it "suggests control structures when a new range added causes a control " +
        "crossing", ->
      model.getRangeSet().getSnippetRanges().push new Range [4, 8], [4, 14]
      model.getRangeSet().getSnippetRanges().push new Range [2, 4], [2, 10]
      events = model.getEvents()
      (expect events.length).toBe 1
      (expect events[0] instanceof ControlCrossingEvent)
      (expect events[0].getControlStructure() instanceof IfControlStructure).toBe true
      (expect events[0].getInsideRange()).toEqual new Range [4, 8], [4, 14]
      (expect events[0].getOutsideRange()).toEqual new Range [2, 4], [2, 10]

    it "does not suggest anything when active ranges are removed", ->

      # Load the model with a set of active ranges
      snippetRanges = model.getRangeSet().getSnippetRanges()
      snippetRanges.reset [
        new Range [4, 8], [4, 14]
        new Range [2, 4], [2, 10]
        new Range [3, 3], [3, 4]  # irrelevant range that will be removed
      ]
      # Clear all events that have happened up to this point
      model.getEvents().splice 0, model.getEvents().length

      # At this point, removing an active range should not cause a
      # control crossing event
      snippetRanges.splice 2, 1
      (expect model.getEvents().length).toBe 0

    it "does not suggest anything when no control structure was crossed", ->
      # (In this case, the outside range is added first, and then the one
      # inside the control structure.  This shouldn't result in a crossing).
      model.getRangeSet().getSnippetRanges().push new Range [2, 4], [2, 10]
      model.getRangeSet().getSnippetRanges().push new Range [4, 8], [4, 14]
      (expect model.getEvents().length).toBe 0

    it "does not suggest a control structure that was crossed before and " +
        "has already enqueued an event", ->

      # Mock a past event with the same control structure as the one that
      # will be triggered by added active ranges
      pastCrossingEvent = new ControlCrossingEvent \
        (new IfControlStructure undefined), undefined, undefined
      (spyOn pastCrossingEvent, "hasControlStructure").andReturn true
      model.getEvents().push pastCrossingEvent

      # No new events should be added now when we cross the structure again
      snippetRanges = model.getRangeSet().getSnippetRanges()
      snippetRanges.push new Range [4, 8], [4, 14]
      snippetRanges.push new Range [2, 4], [2, 10]
      (expect model.getEvents().length).toBe 1

    it "does not suggest a control structure that was crossed before and " +
        "which the user has already decided to accept or reject", ->

      # Mock a past event with the same control structure as the one that
      # will be triggered by added active ranges
      pastCrossingEvent = new ControlCrossingEvent \
        (new IfControlStructure undefined), undefined, undefined
      (spyOn pastCrossingEvent, "hasControlStructure").andReturn true
      model.getViewedEvents().push pastCrossingEvent

      # No new events should be added now when we cross the structure again
      snippetRanges = model.getRangeSet().getSnippetRanges()
      snippetRanges.push new Range [4, 8], [4, 14]
      snippetRanges.push new Range [2, 4], [2, 10]
      (expect model.getEvents().length).toBe 0
