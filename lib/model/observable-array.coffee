module.exports.ObservableArrayProperty = ObservableArrayProperty =
  UNKNOWN: { value: -1, name: "unknown" }
  ARRAY_CHANGE: { value: 0, name: "array-change" }


module.exports.makeObservableArray = (array = undefined) ->

  array or= []

  array.observers = []

  array.addObserver = (observer) ->
    @observers.push observer

  array.notifyObservers = (object, propertyName, oldValue, newValue) ->
    for observer in @observers
      observer.onPropertyChanged object, propertyName, oldValue, newValue

  # It should be easy to copy the array, so that people can modify a copy of
  # the array without needing to observe it
  array.copy = ->
    @concat()

  # REUSE: Snippet for watching change to array is based on
  # answer from http://stackoverflow.com/questions/35610242
  proxy = new Proxy array, {

    set: (target, property, value, receiver) ->

      # Make a copy of the old array that we can pass to observers
      # This will NOT have a proxy associated with it (raw data)
      oldArray = target.copy()

      # Perform the modification
      target[property] = value

      # Importantly, we provide the new value as a proxy instead of the array.
      # This is because we expect observers may want to mutate the array in
      # ways that generate future events.
      target.notifyObservers proxy, ObservableArrayProperty.ARRAY_CHANGE,
        oldArray, proxy

      # Return true to indicate the change was successful
      true

  }

  # Mark the proxy with a flag that callers can check to see if the array
  # they are manipulated is an observable array, or a typical array
  proxy.isProxy = true

  # This function should be used to fully reset the contents of the array.
  # Although it looks verbose compared to just defining a new array, we
  # do this manually to make sure not to clobber the observers of the array.
  array.reset = (elements) ->
    @splice 0, @length
    for element in elements
      @push element

  # Convenience method as we often have to remove things from arrays
  # Only removes the first instance of the element from the array.
  array.remove = (element) ->
    for arrayElement, index in @
      if element is arrayElement
        @.splice index, 1
        break

  proxy
