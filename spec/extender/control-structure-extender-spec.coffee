{ ControlStructureExtender, ControlStructureExtension } = require "../../lib/extender/control-structure-extender"
{ ControlCrossingEvent } = require "../../lib/event/control-crossing"
{ IfControlStructure, ForControlStructure, WhileControlStructure, DoWhileControlStructure, TryCatchControlStructure } = require "../../lib/analysis/parse-tree"
{ File, Symbol, SymbolSet } = require "../../lib/model/symbol-set"
{ Range, RangeSet } = require "../../lib/model/range-set"
{ parse, partialParse } = require "../../lib/analysis/parse-tree"


describe "ControlStructureExtender", ->

  _rangeInRanges = (range, ranges) ->
    for otherRange in ranges
      if range.isEqual otherRange
        return true
    false

  extender = undefined

  beforeEach =>
    extender = new ControlStructureExtender()

  it "includes all ranges for an if statement", ->
    event = new ControlCrossingEvent \
      new IfControlStructure partialParse "if (true) {}", "statement"
    extension = extender.getExtension event
    (expect extension instanceof ControlStructureExtension).toBe true
    ranges = extension.getRanges()
    (expect _rangeInRanges (new Range [0, 0], [0, 11]), ranges).toBe true
    (expect _rangeInRanges (new Range [0, 11], [0, 12]), ranges).toBe true

  it "includes all ranges for a for statement", ->
    event = new ControlCrossingEvent \
      new ForControlStructure partialParse "for (;;) {}", "statement"
    extension = extender.getExtension event
    ranges = extension.getRanges()
    (expect _rangeInRanges (new Range [0, 0], [0, 10]), ranges).toBe true
    (expect _rangeInRanges (new Range [0, 10], [0, 11]), ranges).toBe true

  it "includes all ranges for a while statement", ->
    event = new ControlCrossingEvent \
      new WhileControlStructure partialParse "while (true) {}", "statement"
    extension = extender.getExtension event
    ranges = extension.getRanges()
    (expect _rangeInRanges (new Range [0, 0], [0, 14]), ranges).toBe true
    (expect _rangeInRanges (new Range [0, 14], [0, 15]), ranges).toBe true

  it "includes all ranges for a do-while statement", ->
    event = new ControlCrossingEvent \
      new DoWhileControlStructure partialParse "do {} while (true);", "statement"
    extension = extender.getExtension event
    ranges = extension.getRanges()
    (expect _rangeInRanges (new Range [0, 0], [0, 4]), ranges).toBe true
    (expect _rangeInRanges (new Range [0, 4], [0, 19]), ranges).toBe true

  it "includes all ranges for a try-catch statement", ->
    event = new ControlCrossingEvent \
      new TryCatchControlStructure partialParse \
        "try {} catch (Exception e) {}", "statement"
    extension = extender.getExtension event
    ranges = extension.getRanges()
    (expect _rangeInRanges (new Range [0, 0], [0, 5]), ranges).toBe true
    (expect _rangeInRanges (new Range [0, 5], [0, 28]), ranges).toBe true
    (expect _rangeInRanges (new Range [0, 28], [0, 29]), ranges).toBe true
