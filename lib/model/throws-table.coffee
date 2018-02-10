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

  @deserialize: (json) ->
    if json.superclass?
      superclass = Exception.deserialize json.superclass
    new Exception json.name, superclass


module.exports.ThrowsTable = class ThrowsTable extends RangeTable

  getExceptions: (range) ->
    (@get range) or []

  addException: (range, exception) ->
    if not @containsRange range
      @put range, []
    (@get range).push exception

  getRangesWithThrows: ->
    @getRanges()

  @deserialize: (json) ->
    table = new ThrowsTable()
    for rangeString, exceptions of json.table
      for exceptionData in exceptions
        range = table._toRange rangeString
        exception = Exception.deserialize exceptionData
        table.addException range, exception
    return table
