{ ExampleModel } = require "../../lib/model/example-model"
{ MissingThrowsEvent, MissingThrowsDetector } = require "../../lib/event/missing-throws"
{ ThrowsTable, Exception } = require "../../lib/model/throws-table"
{ CatchTable } = require "../../lib/model/catch-table"
{ parse } = require "../../lib/analysis/parse-tree"
{ Range } = require "../../lib/model/range-set"


describe "MissingThrowsDetector", ->

  model = undefined
  detector = undefined
  parseTree = undefined
  throwsTable = undefined
  beforeEach =>

    # This test case is based on the following example code:
    # import fake.pkg.Klazz;"
    # import fake.pkg.FakeException1;"
    # import fake.pkg.FakeException2;"
    # "
    # public class Example {"
    #   public static void main(String[] args) {"
    #     Klazz k = new Klazz();"
    #     try {"
    #       k.riskyMethod1();  // throws FakeException1"
    #     } catch (FakeException1 e) {"
    #       k.riskyMethod1();  // throws FakeException1"
    #     }"
    #     k.riskyMethod2();  // throws FakeException1, FakeException2"
    #   }"
    # }"
    model = new ExampleModel()

    throwsTable = new ThrowsTable()
    exception1 = new Exception "fake.pkg.FakeException1", new Exception "java.lang.Exception"
    exception2 = new Exception "fake.pkg.FakeException2", new Exception "java.lang.Exception"
    throwsTable.addException (new Range [8, 6], [8, 22]), exception1
    throwsTable.addException (new Range [10, 6], [10, 22]), exception1
    throwsTable.addException (new Range [12, 8], [12, 20]), exception1
    throwsTable.addException (new Range [12, 8], [12, 20]), exception2
    model.setThrowsTable throwsTable

    catchTable = new CatchTable()
    catchTable.addCatch (new Range [8, 6], [8, 22]), new Range [9, 6], [11, 5]
    model.setCatchTable catchTable

    detector = new MissingThrowsDetector model

  it "enqueues an event when a snippet has been added in a method " +
      "that throws an exception", ->
    (expect model.getEvents().length).toBe 0
    model.getRangeSet().getSnippetRanges().push new Range [8, 0], [8, 23]
    (expect model.getEvents().length).toBe 1
    event = model.getEvents()[0]
    (expect event instanceof MissingThrowsEvent).toBe true
    (expect event.getException().getName()).toBe "fake.pkg.FakeException1"
    (expect event.getRange()).toEqual new Range [8, 6], [8, 22]

  it "enqueues multiple exceptions for the same range", ->
    model.getRangeSet().getSnippetRanges().push new Range [12, 0], [12, 21]
    (expect model.getEvents().length).toBe 2

  it "doesn't enqueue the event if the exception is already thrown", ->
    model.getThrows().push "FakeException1"
    model.getRangeSet().getSnippetRanges().push new Range [8, 0], [8, 23]
    (expect model.getEvents().length).toBe 0

  it "doesn't enqueue the event if the exception's superclass is thrown", ->
    model.getThrows().push "Exception"
    model.getRangeSet().getSnippetRanges().push new Range [8, 0], [8, 23]
    (expect model.getEvents().length).toBe 0

  it "doesn't enqueue the event if it is already caught", ->
    # The first range is part of the try-catch block.  This suggests that the
    # exception is already getting handled!
    model.getRangeSet().getSnippetRanges().push new Range [9, 0], [9, 32]
    model.getRangeSet().getSnippetRanges().push new Range [8, 0], [8, 23]
    (expect model.getEvents().length).toBe 0

  it "does not enqueue an event when a line has been added to a method " +
      "that does not throw an exception", ->
    model.getRangeSet().getSnippetRanges().push new Range [6, 4], [6, 26]
    (expect model.getEvents().length).toBe 0

  it "marks an event obsolete when a 'throw' is added for the exception", ->
    model.getRangeSet().getSnippetRanges().push new Range [8, 0], [8, 23]
    (expect model.getEvents().length).toBe 1
    model.getThrows().push "FakeException1"
    (expect model.getEvents().length).toBe 0

  it "marks an event obsolete when a 'catch' is added for the exception'", ->
    model.getRangeSet().getSnippetRanges().push new Range [8, 0], [8, 23]
    (expect model.getEvents().length).toBe 1
    model.getRangeSet().getSnippetRanges().push new Range [9, 0], [9, 32]
    (expect model.getEvents().length).toBe 0
