module.exports.Range = (require 'atom').Range


module.exports.RangeSetProperty = RangeSetProperty =
  UNKNOWN: { value: -1, name: "unknown" }
  ACTIVE_RANGES_CHANGED: { value: 0, name: "active-ranges-changed" }
  SUGGESTED_RANGES_CHANGED: { value: 1, name: "suggested-line-numbers-changed" }


module.exports.RangeSet = class RangeSet

  constructor: (activeRanges, suggestedRanges)->
    @activeRanges = @_makeObservableArray activeRanges
    @suggestedRanges = @_makeObservableArray suggestedRanges
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

  _makeObservableArray: (array = undefined) ->

    array or= []

    array.observers = []

    array.addObserver = (observer) ->
      @observers.push observer

    array.notifyObservers = (object, propertyName, propertyValue) ->
      for observer in @observers
        observer.onPropertyChanged object, propertyName, propertyValue

    # It should be easy to copy the array, so that people can modify a copy of
    # the array without needing to observe it
    array.copy = ->
      @concat()

    # REUSE: Snippet for watching change to array is based on
    # answer from http://stackoverflow.com/questions/35610242
    proxy = new Proxy array, {
      set: (target, property, value, receiver) ->
        # Importantly, we provide the proxy instead of the array
        # to make sure that any mutations made to the array after
        # notification also get noticed.
        target[property] = value
        target.notifyObservers proxy, RangeSetProperty.ARRAY_CHANGE, proxy
        true
    }

    proxy

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
