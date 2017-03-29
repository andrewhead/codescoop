{ makeObservableArray } = require './observable-array'


module.exports.Range = (require 'atom').Range


module.exports.RangeSetProperty = RangeSetProperty =
  UNKNOWN: { value: -1, name: "unknown" }
  ACTIVE_RANGES_CHANGED: { value: 0, name: "active-ranges-changed" }
  SUGGESTED_RANGES_CHANGED: { value: 1, name: "suggested-ranges-changed" }


module.exports.RangeSet = class RangeSet

  constructor: (activeRanges, suggestedRanges)->
    @activeRanges = makeObservableArray activeRanges
    @suggestedRanges = makeObservableArray suggestedRanges
    @activeRanges.addObserver @
    @suggestedRanges.addObserver @
    @observers = []

  onPropertyChanged: (object, propertyName, oldValue, newValue) ->
    if object is @activeRanges
      propertyName = RangeSetProperty.ACTIVE_RANGES_CHANGED
    else if object is @suggestedRanges
      propertyName = RangeSetProperty.SUGGESTED_RANGES_CHANGED
    else
      propertyName = RangeSetProperty.UNKNOWN
    @notifyObservers this, propertyName, oldValue, newValue

  addObserver: (observer) ->
    @observers.push observer

  notifyObservers: (object, propertyName, oldValue, newValue) ->
    for observer in @observers
      observer.onPropertyChanged object, propertyName, oldValue, newValue

  getActiveRanges: ->
    @activeRanges

  getSuggestedRanges: ->
    @suggestedRanges

  setSuggestedRanges: (ranges) ->
    @suggestedRanges.reset ranges

  addSuggestedRange: (range) ->
    @suggestedRanges.push range

  getActiveSymbols: (symbols) ->
    activeSymbols = []
    for symbol in symbols
      for activeRange in @activeRanges
        if activeRange.containsRange symbol.getRange()
          activeSymbols.push symbol
    activeSymbols
