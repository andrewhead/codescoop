{ parse } = require "../../lib/analysis/parse-tree"
{ ExampleModel } = require "../../lib/model/example-model"
{ File, Symbol } = require "../../lib/model/symbol-set"
{ Range } = require "../../lib/model/range-set"
{ MediatingUseEvent, MediatingUseDetector } = require "../../lib/event/mediating-use"


describe "MediatingUseDetector", ->

  model = undefined
  detector = undefined
  testFile = undefined
  beforeEach =>
    parseTree = parse [
      "public class Example {"
      "  public static void main(String[] args) {"
      "    int i = 1;"
      "    int j = 2;"
      "    System.out.println(i);"
      "    System.out.println(i);"
      "    System.out.println(j);  // Ignored, it isn't i"
      "    i + 1;"
      "  }"
      "  public static void anotherMethod() {"
      "    int i = 1;"
      "    System.out.println(i);"
      "  }"
      "}"
    ].join "\n"
    testFile = new File "path", "file_name"
    defs = [
      # In the 'main' function: this is where most tests will focus
      new Symbol testFile, "i", (new Range [2, 8], [2, 9]), "int"
      new Symbol testFile, "j", (new Range [3, 8], [3, 9]), "int"
      # In 'anotherMethod'.  This is for more specialized tests
      new Symbol testFile, "i", (new Range [10, 8], [10, 9]), "int"
    ]
    uses = [
      # In the 'main' function
      new Symbol testFile, "i", (new Range [4, 23], [4, 24]), "int"
      new Symbol testFile, "i", (new Range [5, 23], [5, 24]), "int"
      new Symbol testFile, "j", (new Range [6, 23], [6, 24]), "int"
      new Symbol testFile, "i", (new Range [7, 4], [7, 5]), "int"
      # In 'anotherMethod'
      new Symbol testFile, "i", (new Range [11, 23], [11, 24]), "int"
    ]
    model = new ExampleModel()
    model.setParseTree parseTree
    model.getSymbols().getVariableUses().reset uses
    model.getSymbols().getVariableDefs().reset defs
    detector = new MediatingUseDetector model

  it "finds uses between a def and use and returns them in line order", ->
    (expect model.getEvents().length).toBe 0
    activeRanges = [
      new Range [2, 0], [2, 14]  # 'i' def
      new Range [7, 0], [7, 10]  # 'i' final use
    ]
    model.getRangeSet().getActiveRanges().reset activeRanges
    (expect model.getEvents().length).toBe 2
    events = model.getEvents()
    (expect events[0] instanceof MediatingUseEvent).toBe true
    (expect events[0].getDef().getRange()).toEqual new Range [2, 8], [2, 9]
    (expect events[0].getUse().getRange()).toEqual new Range [7, 4], [7, 5]
    (expect events[0].getMediatingUse().getRange()).toEqual new Range [4, 23], [4, 24]
    (expect events[1].getMediatingUse().getRange()).toEqual new Range [5, 23], [5, 24]

  it "only recommends uses that aren't in the active ranges", ->
    activeRanges = [
      new Range [2, 0], [2, 14]  # 'i' def
      new Range [5, 0], [5, 26]  # 'i' mediating use #1
      new Range [7, 0], [7, 10]  # 'i' final use
    ]
    model.getRangeSet().getActiveRanges().reset activeRanges
    (expect model.getEvents().length).toBe 1
    (expect model.getEvents()[0].getMediatingUse().getRange()).toEqual \
      new Range [4, 23], [4, 24]

  it "only associates defs and uses in the same scope", ->
    # These two active ranges contain an unrelated def and use.  The
    # event detector should find no link between the two.
    activeRanges = [
      new Range [2, 0], [2, 14]    # 'i' def in 'main'
      new Range [11, 0], [11, 26]  # 'i' final use in 'anotherMethod'
    ]
    model.getRangeSet().getActiveRanges().reset activeRanges
    (expect model.getEvents().length).toBe 0

  it "doesn't detect an intervening use that was already queued", ->
    model.getEvents().push new MediatingUseEvent \
      (new Symbol testFile, "i", (new Range [2, 8], [2, 9]), "int"),    # 'i' def
      (new Symbol testFile, "i", (new Range [7, 4], [7, 5]), "int"),    # 'i' final use
      (new Symbol testFile, "i", (new Range [5, 23], [5, 24]), "int")   # 'i' mediating use
    # This set of active ranges will produce exactly the same mediating
    # event as the one that is already enqueued in the model's events
    activeRanges = [
      new Range [2, 0], [2, 14]  # 'i' def
      new Range [7, 0], [7, 10]  # 'i' final use
    ]
    model.getRangeSet().getActiveRanges().reset activeRanges
    (expect model.getEvents().length).toBe 2

  it "doesn't detect an intervening use that was already viewed", ->
    model.getViewedEvents().push new MediatingUseEvent \
      (new Symbol testFile, "i", (new Range [2, 8], [2, 9]), "int"),    # 'i' def
      (new Symbol testFile, "i", (new Range [7, 4], [7, 5]), "int"),    # 'i' final use
      (new Symbol testFile, "i", (new Range [5, 23], [5, 24]), "int")   # 'i' mediating use
    # This set of active ranges will produce exactly the same mediating
    # event as the one that is already enqueued in the model's events
    activeRanges = [
      new Range [2, 0], [2, 14]  # 'i' def
      new Range [7, 0], [7, 10]  # 'i' final use
    ]
    model.getRangeSet().getActiveRanges().reset activeRanges
    (expect model.getEvents().length).toBe 1

  describe "when there are nested scopes", ->

    model = undefined
    detector = undefined
    beforeEach =>
      parseTree = parse [
        "public class Example {"
        "  public static void main(String[] args) {"
        "    int i = 1;"
        "    {"
        "        int i = 2;"
        "        System.out.println(i);"
        "    }"
        "    i + 1;"
        "  }"
        "}"
      ].join "\n"
      testFile = new File "path", "file_name"
      defs = [
        new Symbol testFile, "i", (new Range [2, 8], [2, 9]), "int"
        new Symbol testFile, "j", (new Range [4, 12], [4, 13]), "int"
      ]
      uses = [
        new Symbol testFile, "i", (new Range [5, 27], [5, 28]), "int"
        new Symbol testFile, "i", (new Range [7, 4], [7, 5]), "int"
      ]
      model = new ExampleModel()
      model.setParseTree parseTree
      model.getSymbols().getVariableUses().reset uses
      model.getSymbols().getVariableDefs().reset defs
      detector = new MediatingUseDetector model

    it "only detects uses that correspond to the declaration of the def", ->
      # In other words, it shouldn't find the printed `i` on line 5, which
      # refers to a different `i`.
      activeRanges = [
        new Range [2, 0], [2, 14]  # 'i' def
        new Range [7, 0], [7, 10]  # 'i' final use
      ]
      model.getRangeSet().getActiveRanges().reset activeRanges
      (expect model.getEvents().length).toBe 0
