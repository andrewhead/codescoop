{ makeObservableArray } = require './observable-array'


module.exports.RangeSetProperty = RangeSetProperty =
  UNKNOWN: { value: -1, name: "unknown" }
  ACTIVE_RANGES_CHANGED: { value: 0, name: "active-ranges-changed" }
  SUGGESTED_RANGES_CHANGED: { value: 1, name: "suggested-ranges-changed" }
  CLASS_RANGES_CHANGED: { value: 2, name: "class-ranges-changed" }
  SNIPPET_RANGES_CHANGED: { value: 3, name: "snippet-ranges-changed" }


module.exports.Range = (require 'atom').Range


module.exports.ClassRange = class ClassRange

  constructor: (range, symbol, static_) ->
    @range = range
    @symbol = symbol
    @static = static_

  getRange: ->
    @range

  getSymbol: ->
    @symbol

  isStatic: ->
    @static


module.exports.RangeSet = class RangeSet

  constructor: (snippetRanges, suggestedRanges)->

    @snippetRanges = makeObservableArray snippetRanges
    @classRanges = makeObservableArray []
    @suggestedRanges = makeObservableArray suggestedRanges
    @snippetRanges.addObserver @
    @classRanges.addObserver @
    @suggestedRanges.addObserver @

    # Active ranges is a conglomerate list that updates whenever any one
    # of its constituent lists updates.  It's up to this class to maintain
    # that list and make sure it's up to date.
    @activeRanges = makeObservableArray []
    @_updateActiveRanges()

    # Observers watch for changes to all ranges
    @observers = []

  addObserver: (observer) ->
    @observers.push observer

  _updateActiveRanges: ->
    newRanges = @snippetRanges.concat \
      (classRange.getRange() for classRange in @classRanges)
    @activeRanges.reset newRanges

  onPropertyChanged: (object, propertyName, oldValue, newValue) ->

    # Map the changes in specialized lists of ranges to more descriptive events.
    if object is @snippetRanges
      propertyName = RangeSetProperty.SNIPPET_RANGES_CHANGED
    else if object is @classRanges
      propertyName = RangeSetProperty.CLASS_RANGES_CHANGED
    else if object is @suggestedRanges
      propertyName = RangeSetProperty.SUGGESTED_RANGES_CHANGED
    @notifyObservers @, propertyName, oldValue, newValue

    # Whenever one of the constituent range lists of active ranges updates,
    # recompute the active ranges, and notify listeners that it changed.
    # This requires a little bit of care, as not all range objects are pure
    # ranges (e.g., Class ranges are more complex data types)
    if object in [ @snippetRanges, @classRanges ]
      previousActiveRanges = @activeRanges.copy()
      @_updateActiveRanges()
      @notifyObservers @, RangeSetProperty.ACTIVE_RANGES_CHANGED,
        previousActiveRanges, @activeRanges

  notifyObservers: (object, propertyName, oldValue, newValue) ->
    for observer in @observers
      observer.onPropertyChanged object, propertyName, oldValue, newValue

  # Unlike all other range lists on this object, this one shouldn't be
  # mutated.  It updates to reflect its constituent lists
  getActiveRanges: ->
    @activeRanges

  getSnippetRanges: ->
    @snippetRanges

  getClassRanges: ->
    @classRanges

  getSuggestedRanges: ->
    @suggestedRanges

  getActiveSymbols: (symbols) ->
    activeSymbols = []
    for symbol in symbols
      for activeRange in @activeRanges
        if activeRange.containsRange symbol.getRange()
          activeSymbols.push symbol
    activeSymbols
