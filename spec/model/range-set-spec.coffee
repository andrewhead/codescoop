{ Range, ClassRange, RangeSet } = require "../../lib/model/range-set"


describe "RangeSet", ->

  it "returns all class and snippet ranges when active ranges are queried", ->
    rangeSet = new RangeSet()
    # Initialize ranges with dummy ranges (not real range objects)
    # to keep this code readable.
    rangeSet.getSnippetRanges().reset [ new Range [0, 0], [0, 20] ]
    rangeSet.getClassRanges().reset [
      new ClassRange (new Range [4, 2], [5, 3]), undefined, false
    ]
    (expect rangeSet.getActiveRanges().length).toBe 2
