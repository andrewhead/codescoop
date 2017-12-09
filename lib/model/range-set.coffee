{ makeObservableArray } = require "./observable-array"
{ makeObservableRangeArray } = require "./observable-range-array"
{ Range } = require "atom"


module.exports.RangeSetProperty = RangeSetProperty =
  UNKNOWN: { value: -1, name: "unknown" }
  # Active ranges is the total of all ranges that have currently been added
  # to the example, from snippets, methods, classes, etc.
  ACTIVE_RANGES_CHANGED: { value: 0, name: "active-ranges-changed" }
  # Ranges that are "suggested" for a suggested edit.
  SUGGESTED_RANGES_CHANGED: { value: 1, name: "suggested-ranges-changed" }
  # Ranges that hold an inner class.
  CLASS_RANGES_CHANGED: { value: 2, name: "class-ranges-changed" }
  # Ranges that include a user-selected snippet.
  SNIPPET_RANGES_CHANGED: { value: 3, name: "snippet-ranges-changed" }
  # Ranges that hold a full method.
  METHOD_RANGES_CHANGED: { value: 4, name: "method-ranges-changed" }
  # Lines a user chose that haven't yet been added to the snippet ranges.
  CHOSEN_RANGES_CHANGED: { value: 5, name: "chosen-ranges-changed" }
  DELETE_RANGES_CHANGED: { value: 6, name: "delete-ranges-changed" }


module.exports.Range = Range


module.exports.MethodRange = class MethodRange

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


# One common data structure is looking up information by range.  This table
# provides a standard interface to a table where the range is the key.
module.exports.RangeTable = class RangeTable

  constructor: ->
    @table = {}

  get: (range) ->
    @table[@_getRangeKey range]

  put: (range, item) ->
    rangeKey = @_getRangeKey range
    @table[rangeKey] = item

  containsRange: (range) ->
    (@_getRangeKey range) of @table

  getRanges: ->
    ranges = []
    for rangeKey of @table
      ranges.push @_toRange rangeKey
    ranges

  _getRangeKey: (range) ->
    range.toString()

  _toRange: (rangeKey) ->
    regexp = /\[\(([0-9]+), ([0-9]+)\) - \(([0-9]+), ([0-9]+)\)\]/
    match = regexp.exec rangeKey
    new Range [Number(match[1]), Number(match[2])],
      [Number(match[3]), Number(match[4])]


module.exports.RangeSet = class RangeSet

  constructor: (snippetRanges, suggestedRanges)->

    @snippetRanges = makeObservableRangeArray snippetRanges
    @chosenRanges = makeObservableArray []
    @deleteRanges = makeObservableArray []
    @methodRanges = makeObservableArray []
    @classRanges = makeObservableArray []
    @suggestedRanges = makeObservableArray suggestedRanges
    @snippetRanges.addObserver @
    @chosenRanges.addObserver @
    @deleteRanges.addObserver @
    @methodRanges.addObserver @
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
      (methodRange.getRange() for methodRange in @methodRanges),
      (classRange.getRange() for classRange in @classRanges)
    @activeRanges.reset newRanges

  onPropertyChanged: (object, propertyName, oldValue, newValue) ->

    # Map the changes in specialized lists of ranges to more descriptive events.
    if object is @snippetRanges
      propertyName = RangeSetProperty.SNIPPET_RANGES_CHANGED
    else if object is @methodRanges
      propertyName = RangeSetProperty.METHOD_RANGES_CHANGED
    else if object is @classRanges
      propertyName = RangeSetProperty.CLASS_RANGES_CHANGED
    else if object is @suggestedRanges
      propertyName = RangeSetProperty.SUGGESTED_RANGES_CHANGED
    else if object is @chosenRanges
      propertyName = RangeSetProperty.CHOSEN_RANGES_CHANGED
    else if object is @deleteRanges
      propertyName = RangeSetProperty.DELETE_RANGES_CHANGED
    @notifyObservers @, propertyName, oldValue, newValue

    # Whenever one of the constituent range lists of active ranges updates,
    # recompute the active ranges, and notify listeners that it changed.
    # This requires a little bit of care, as not all range objects are pure
    # ranges (e.g., class ranges are more complex data types)
    if object in [ @snippetRanges, @methodRanges, @classRanges ]
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

  getMethodRanges: ->
    @methodRanges

  getClassRanges: ->
    @classRanges

  getSuggestedRanges: ->
    @suggestedRanges

  getChosenRanges: ->
    @chosenRanges

  getDeleteRanges: ->
    @deleteRanges

  getActiveSymbols: (symbols) ->
    activeSymbols = []
    for symbol in symbols
      for activeRange in @activeRanges
        if activeRange.containsRange symbol.getRange()
          activeSymbols.push symbol
    activeSymbols
