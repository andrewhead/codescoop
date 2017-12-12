{ toControlStructure, getControlStructureRanges } = require "./parse-tree"
{ Range, RangeSet, RangeTable } = require "../model/range-set"
{ JavaListener } = require "../grammar/Java/JavaListener"
ParseTreeWalker = (require 'antlr4').tree.ParseTreeWalker.DEFAULT


class ControlStructureSearcher extends JavaListener

  constructor: ->
    @controlStructures = []

  exitEveryRule: (ctx) ->
    controlStructure = toControlStructure ctx
    if controlStructure?
      @controlStructures.push controlStructure

  getControlStructures: ->
    @controlStructures


module.exports.buildRangeGroupTable = buildRangeGroupTable = (parseTree) ->

  # Search the parse tree for control structures
  controlStructureSearcher = new ControlStructureSearcher()
  ParseTreeWalker.walk controlStructureSearcher, parseTree.getRoot()

  # For each one, add a group of ranges to the table for that structure
  rangeGroupTable = new RangeGroupTable()
  for controlStructure in controlStructureSearcher.getControlStructures()
    relatedRanges = getControlStructureRanges controlStructure
    rangeGroupTable.putGroup relatedRanges

  rangeGroupTable


module.exports.RangeGroupTable = class RangeGroupTable extends RangeTable

  putGroup: (ranges) ->
    # Every range in a group points to every other range in its group.
    for range in ranges
      for otherRange in ranges
        if not (otherRange.isEqual range)
          if not @containsRange range
            @put range, []
          (@get range).push otherRange

  getRelatedRanges: (range) ->

    relatedRanges = []

    # If this range is in the table, just get the related ranges
    if @containsRange range
      relatedRanges = @get range

    # Otherwise, look for the first range that this one contains.  If one
    # exists, return the related range for that range.
    else
      for otherRange in @getRanges()
        if range.containsRange otherRange
          relatedRanges = (@get otherRange) or []

    # Only return ranges that aren't *within* the input range
    newRelatedRanges = []
    for relatedRange in relatedRanges
      if not range.containsRange relatedRange
        newRelatedRanges.push relatedRange

    newRelatedRanges


module.exports.RangeGroupsAnalysis = class RangeGroupsAnalysis

  constructor: (parseTree) ->
    @parseTree = parseTree

  run: (callback, err) ->
    rangeGroupTable = buildRangeGroupTable @parseTree
    callback rangeGroupTable
