{ makeObservableArray } = require "../../lib/model/observable-array"


describe "makeObservableArray", ->

  it "returns an old non-proxy as old value, and current proxy as new value", ->

    observer =
      onPropertyChanged: (object, propertyName, oldValue, newValue) ->
        # We're only interested in the change associated with the push,
        # even though others property change events will be triggered
        # (for example, a change to the "length" variable)
        if newValue.length > oldValue.length
          @oldValue = oldValue
          @newValue = newValue

    array = makeObservableArray []
    array.addObserver observer
    array.push 1

    (expect observer.oldValue.isProxy).not.toBe true
    (expect observer.oldValue.length).toBe 0
    (expect observer.newValue.isProxy).toBe true
    (expect observer.newValue.length).toBe 1
