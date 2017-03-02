module.exports.LineSetProperty = LineSetProperty =
  UNKNOWN: { value: -1, name: "unknown" }
  ACTIVE_LINE_NUMBERS_CHANGED: { value: 0, name: "active-line-numbers-changed" }
  SUGGESTED_LINE_NUMBERS_CHANGED: { value: 1, name: "suggested-line-numbers-changed" }


module.exports.LineSet = class LineSet

  constructor: (activeLineNumbers, suggestedLineNumbers)->
    @activeLineNumbers = @_makeObservableArray activeLineNumbers
    @suggestedLineNumbers = @_makeObservableArray suggestedLineNumbers
    @activeLineNumbers.addObserver @
    @suggestedLineNumbers.addObserver @
    @observers = []

  onPropertyChanged: (object, propertyName, propertyValue) ->
    if object is @activeLineNumbers
      propertyName = LineSetProperty.ACTIVE_LINE_NUMBERS_CHANGED
      propertyValue = @getActiveLineNumbers()
    else if object is @suggestedLineNumbers
      propertyName = LineSetProperty.SUGGESTED_LINE_NUMBERS_CHANGED
      propertyValue = @getSuggestedLineNumbers()
    else
      propertyName = LineSetProperty.UNKNOWN
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
        target.notifyObservers proxy, LineSetProperty.ARRAY_CHANGE, proxy
        true
    }

    proxy

  getActiveLineNumbers: ->
    @activeLineNumbers

  getSuggestedLineNumbers: ->
    @suggestedLineNumbers
