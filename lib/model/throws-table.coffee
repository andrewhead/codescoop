{ Range } = require "./range-set"
{ Point } = require "atom"


module.exports.Exception = class Exception

  constructor: (name, superclass) ->
    @name = name
    @superclass = superclass

  getName: ->
    @name

  getSuperclass: ->
    @superclass

  equals: (other) ->
    ((other instanceof Exception) and
     (other.getName() == @name) and
     (other.getSuperclass()? and other.getSuperclass().equals @superclass))


module.exports.ThrowsTable = class ThrowsTable

  constructor: ->
    @table = {}

  _getRangeKey: (range) ->
    range.toString()

  _toRange: (rangeKey) ->
    regexp = /\[\(([0-9]+), ([0-9]+)\) - \(([0-9]+), ([0-9]+)\)\]/
    match = regexp.exec rangeKey
    new Range [Number(match[1]), Number(match[2])],
      [Number(match[3]), Number(match[4])]

  addException: (range, exception) ->
    rangeKey = @_getRangeKey range
    if rangeKey not of @table
      @table[rangeKey] = []
    @table[rangeKey].push exception

  getExceptions: (range) ->
    rangeKey = @_getRangeKey range
    if rangeKey not of @table
      return []
    @table[rangeKey]

  getRangesWithThrows: ->
    ranges = []
    for rangeKey of @table
      ranges.push @_toRange rangeKey
    ranges
