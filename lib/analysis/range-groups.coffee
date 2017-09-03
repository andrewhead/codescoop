{ toControlStructure, getControlStructureRanges } = require "./parse-tree"
{ Range } = require "../model/range-set"
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


module.exports.RangeGroupTable = class RangeGroupTable

  constructor: () ->
    @relatedRanges = {}

  _getRangeKey: (range) ->
    String(range)

  _toRange: (rangeKey) ->
    regexp = /\[\(([0-9]+), ([0-9]+)\) - \(([0-9]+), ([0-9]+)\)\]/
    match = regexp.exec rangeKey
    new Range [Number(match[1]), Number(match[2])],
      [Number(match[3]), Number(match[4])]

  putGroup: (ranges) ->
    # Every range in a group points to every other range in its group.
    for range in ranges
      rangeKey = @_getRangeKey range
      for otherRange in ranges
        if not (otherRange.isEqual range)
          if rangeKey not of @relatedRanges
            @relatedRanges[rangeKey] = []
          @relatedRanges[rangeKey].push otherRange

  getRelatedRanges: (range) ->

    relatedRanges = []

    # If this range is in the table, just get the related ranges
    rangeKey = @_getRangeKey range
    if rangeKey of @relatedRanges
      relatedRanges = @relatedRanges[rangeKey]

    # Otherwise, look for the first range that this one contains.  If one
    # exists, return the related range for that range.
    else
      for rangeKey of @relatedRanges
        otherRange = @_toRange rangeKey
        if range.containsRange otherRange
          relatedRanges = @relatedRanges[rangeKey]

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
