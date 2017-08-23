module.exports.ObservableArrayProperty = ObservableArrayProperty =
  UNKNOWN: { value: -1, name: "unknown" }
  ARRAY_CHANGE: { value: 0, name: "array-change" }


module.exports.makeObservableArray = (array = undefined) ->

  array or= []

  array.observers = []

  array.addObserver = (observer) ->
    @observers.push observer

  array.notifyObservers = (arrayBefore) ->
    for observer in @observers
      observer.onPropertyChanged @, ObservableArrayProperty.ARRAY_CHANGE,
        arrayBefore, @

  # It should be easy to copy the array, so that people can modify a copy of
  # the array without needing to observe it
  array.copy = ->
    @concat()

  # Mark the proxy with a flag that callers can check to see if the array
  # they are manipulated is an observable array, or a typical array
  array.isProxy = true

  # The mutators below are the actions that we want to notify observers
  # of when they occur.  We expect all accesses to the array will be made
  # through push, reset, and remove.
  array.originalPush = array.push
  array.push = (element) ->
    arrayBefore = @.copy()
    @originalPush element
    @notifyObservers arrayBefore

  # This function should be used to fully reset the contents of the array.
  # Although it looks verbose compared to just defining a new array, we
  # do this manually to make sure not to clobber the observers of the array.
  array.reset = (elements) ->
    arrayBefore = @.copy()
    @splice 0, @length
    if elements?
      for element in elements
        @originalPush element
    @notifyObservers arrayBefore

  # Convenience method as we often have to remove things from arrays
  # Only removes the first instance of the element from the array.
  array.remove = (element) ->
    arrayBefore = @.copy()
    for arrayElement, index in @
      if element is arrayElement
        @.splice index, 1
        break
    @notifyObservers arrayBefore

  array
