{ buildRangeGroupTable, RangeGroupTable } = require "../../lib/analysis/range-groups"
{ Range } = require "../../lib/model/range-set"
{ parse } = require "../../lib/analysis/parse-tree"


describe "buildRangeGroupTable", ->

  it "creates a range group for a control structure", ->
    code = [
      "public class Example {"
      "  public static void main(String[] args) {"
      "    if (true) {"
      "    }"
      "  }"
      "}"
    ].join "\n"
    parseTree = parse code
    rangeGroupTable = buildRangeGroupTable parseTree
    relatedRanges = rangeGroupTable.getRelatedRanges new Range [2, 4], [2, 15]
    (expect relatedRanges.length).toBe 1
    (expect relatedRanges[0]).toEqual new Range [3, 4], [3, 5]


describe "RangeGroupTable", ->

  _rangeInRanges = (range, ranges) ->
    for otherRange in ranges
      if range.isEqual otherRange
        return true
    false

  it "returns all ranges related to an input range", ->
    rangeGroupTable = new RangeGroupTable()
    rangeGroup = [
      new Range [0, 0], [0, 10]
      new Range [1, 0], [1, 10]
      new Range [2, 0], [2, 10]
    ]
    rangeGroupTable.putGroup rangeGroup
    relatedRanges = rangeGroupTable.getRelatedRanges new Range [1, 0], [1, 10]
    (expect relatedRanges.length).toBe 2
    (expect _rangeInRanges (new Range [0, 0], [0, 10]), relatedRanges).toBe true
    (expect _rangeInRanges (new Range [2, 0], [2, 10]), relatedRanges).toBe true

  it "can return ranges from multiple groups", ->
    rangeGroupTable = new RangeGroupTable()
    rangeGroup1 = [
      new Range [0, 0], [0, 10]
      new Range [1, 0], [1, 10]
      new Range [2, 0], [2, 10]
    ]
    rangeGroup2 = [
      new Range [1, 0], [1, 10]
      new Range [3, 0], [3, 10]
    ]
    rangeGroupTable.putGroup rangeGroup1
    rangeGroupTable.putGroup rangeGroup2
    relatedRanges = rangeGroupTable.getRelatedRanges new Range [1, 0], [1, 10]
    (expect relatedRanges.length).toBe 3
    (expect _rangeInRanges (new Range [0, 0], [0, 10]), relatedRanges).toBe true
    (expect _rangeInRanges (new Range [2, 0], [2, 10]), relatedRanges).toBe true
    (expect _rangeInRanges (new Range [3, 0], [3, 10]), relatedRanges).toBe true

  it "returns related ranges for a range that subsumes others", ->
    rangeGroupTable = new RangeGroupTable()
    rangeGroup = [
      new Range [0, 0], [0, 10]
      new Range [1, 0], [1, 10]
    ]
    rangeGroupTable.putGroup rangeGroup
    relatedRanges = rangeGroupTable.getRelatedRanges new Range [0, 0], [0, 11]
    (expect relatedRanges.length).toBe 1

  it "skips related ranges already included in the input range", ->
    rangeGroupTable = new RangeGroupTable()
    rangeGroup = [
      new Range [0, 0], [0, 10]
      new Range [1, 0], [1, 10]
    ]
    rangeGroupTable.putGroup rangeGroup
    relatedRanges = rangeGroupTable.getRelatedRanges new Range [0, 0], [1, 11]
    (expect relatedRanges.length).toBe 0
