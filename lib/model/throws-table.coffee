{ Range, RangeTable } = require "./range-set"
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


module.exports.ThrowsTable = class ThrowsTable extends RangeTable

  getExceptions: (range) ->
    (@get range) or []

  addException: (range, exception) ->
    if not @containsRange range
      @put range, []
    (@get range).push exception

  getRangesWithThrows: ->
    @getRanges()
