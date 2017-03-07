{ makeObservableArray } = require './observable-array'


module.exports.Range = (require 'atom').Range


module.exports.RangeSetProperty = RangeSetProperty =
  UNKNOWN: { value: -1, name: "unknown" }
  ACTIVE_RANGES_CHANGED: { value: 0, name: "active-ranges-changed" }
  SUGGESTED_RANGES_CHANGED: { value: 1, name: "suggested-line-numbers-changed" }


module.exports.RangeSet = class RangeSet

  constructor: (activeRanges, suggestedRanges)->
    @activeRanges = makeObservableArray activeRanges
    @suggestedRanges = makeObservableArray suggestedRanges
    @activeRanges.addObserver @
    @suggestedRanges.addObserver @
    @observers = []

  onPropertyChanged: (object, propertyName, propertyValue) ->
    if object is @activeRanges
      propertyName = RangeSetProperty.ACTIVE_RANGES_CHANGED
      propertyValue = @getActiveRanges()
    else if object is @suggestedRanges
      propertyName = RangeSetProperty.SUGGESTED_RANGES_CHANGED
      propertyValue = @getSuggestedRanges()
    else
      propertyName = RangeSetProperty.UNKNOWN
    @notifyObservers this, propertyName, propertyValue

  addObserver: (observer) ->
    @observers.push observer

  notifyObservers: (object, propertyName, propertyValue) ->
    # TODO: Have different events for changes to the different line sets
    for observer in @observers
      observer.onPropertyChanged object, propertyName, propertyValue

  getActiveRanges: ->
    @activeRanges

  getSuggestedRanges: ->
    @suggestedRanges

  setSuggestedRanges: (ranges) ->
    # Although this looks verbose, it's important that we manually transfer
    # all new elements.  The current list of suggested line numbers has
    # observers that will be trashed if we start the array from scratch.
    @suggestedRanges.splice(0, @suggestedRanges.length)
    for range in ranges
      @suggestedRanges.push range

  removeSuggestedRange: (range) ->
    @suggestedRanges.splice((@suggestedRanges.indexOf range), 1)

  getActiveSymbols: (symbols) ->
    activeSymbols = []
    for symbol in symbols
      for activeRange in @activeRanges
        if activeRange.containsRange symbol.getRange()
          activeSymbols.push symbol
    activeSymbols
