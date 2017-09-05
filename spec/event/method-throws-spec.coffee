{ ExampleModel } = require "../../lib/model/example-model"
{ MethodThrowsEvent, MethodThrowsDetector } = require "../../lib/event/method-throws"
{ JavaParser } = require "../../lib/grammar/Java/JavaParser"
{ parse, partialParse } = require "../../lib/analysis/parse-tree"
{ Range } = require "../../lib/model/range-set"


describe "MethodThrowsDetector", ->

  model = undefined
  detector = undefined
  parseTree = undefined
  beforeEach =>
    parseTree = parse [
      "public class Example {"
      ""
      "  public void errorProne() throws UnsupportedOperationException {"
      "    int i = 1;"
      "    int j = 1;"
      "  }"
      ""
      "  public void notErrorProne() {"
      "    int i = 1;"
      "  }"
      ""
      "  public void throwsTwoExceptions() throws IOException, ParseException {"
      "    int i = 1;"
      "  }"
      ""
      "}"
    ].join "\n"
    model = new ExampleModel()
    model.setParseTree parseTree
    detector = new MethodThrowsDetector model

  it "enqueues an event when a snippet has been added in a method " +
      "that throws an exception", ->
    (expect model.getEvents().length).toBe 0
    model.getRangeSet().getSnippetRanges().push new Range [3, 4], [3, 14]
    (expect model.getEvents().length).toBe 1
    event = model.getEvents()[0]
    (expect event instanceof MethodThrowsEvent).toBe true
    (expect event.getThrowableName()).toBe "UnsupportedOperationException"
    (expect event.getMethodCtx().ruleIndex).toBe JavaParser.RULE_classBodyDeclaration
    (expect event.getInnerRange()).toEqual new Range [3, 4], [3, 14]

  it "adds one event for every exception thrown", ->
    model.getRangeSet().getSnippetRanges().push new Range [12, 4], [12, 14]
    (expect model.getEvents().length).toBe 2

  it "does not enqueue an event when a line has been added to a method " +
      "that does not throw and exception", ->
    model.getRangeSet().getSnippetRanges().push new Range [8, 4], [8, 14]
    (expect model.getEvents().length).toBe 0

  describe "when past events exist", ->

    model = undefined
    detector = undefined
    pastEvent = undefined
    beforeEach =>
      # Like in the control crossing tests, we include whitespace here
      # to make sure that the range of the partially parsed method declaration
      # lines up with the original code example.
      methodCtx = partialParse ([
        ""
        ""
        "  public void errorProne() throws UnsupportedOperationException {"
        "    int i = 1;"
        "    int j = 1;"
        "  }"
        ""
      ].join "\n"), "classBodyDeclaration"
      model = new ExampleModel()
      model.setParseTree parseTree
      detector = new MethodThrowsDetector model
      pastEvent = new MethodThrowsEvent "UnsupportedOperationException",
        methodCtx, new Range [3, 4], [3, 14]

    it "doesn't detect an event as obsolete, even if the range including " +
        "the exception has been added", ->
      # This is because the view may choose to add the exception in a place
      # that's different than the one where the range is included, so we still
      # have to know when a
      model.getRangeSet().getSnippetRanges().push new Range [2, 0], [2, 65]
      (expect detector.isEventObsolete pastEvent).toBe false

    it "doesn't add the event to the list of events if another line belongs " +
        "to the same method that throws the same throwable", ->
      model.getEvents().push pastEvent
      (expect detector.isEventQueued pastEvent).toBe true
