module.exports.ObservableArrayProperty = ObservableArrayProperty =
  UNKNOWN: { value: -1, name: "unknown" }
  ARRAY_CHANGE: { value: 0, name: "array-change" }


module.exports.makeObservableArray = (array = undefined) ->

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
      target.notifyObservers proxy, ObservableArrayProperty.ARRAY_CHANGE, proxy
      true
  }

  # This function should be used to fully reset the contents of the array.
  # Although it looks verbose compared to just defining a new array, we
  # do this manually to make sure not to clobber the observers of the array.
  array.reset = (elements) ->
    @splice(0, @length)
    for element in elements
      @push element

  proxy
