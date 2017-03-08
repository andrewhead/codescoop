{ makeObservableArray } = require './observable-array'
{ RangeSetProperty } = require './range-set'


module.exports.ExampleModelProperty = ExampleModelProperty =
  UNKNOWN: { value: -1, name: "unknown" }
  ACTIVE_RANGES: { value: 0, name: "lines-changed" }
  STATE: { value: 2, name: "state" }
  ERROR_CHOICE: { value: 3, name: "error-choice"}
  RESOLUTION_CHOICE: { value: 4, name: "resolution-choice" }
  VALUE_MAP: { value: 5, name: "value-map" }
  ERRORS: { value: 6, name: "errors" }
  SUGGESTIONS: { value: 7, name: "suggestions" }
  EDITS: { value: 8, name: "edits" }


module.exports.ExampleModelState = ExampleModelState =
  ANALYSIS: { value: 0, name: "analysis" }
  IDLE: { value: 1, name: "idle" }
  ERROR_CHOICE: { value: 2, name: "error-choice" }
  RESOLUTION: { value: 3, name: "resolution" }


module.exports.ExampleModel = class ExampleModel

  constructor: (codeBuffer, rangeSet, symbols, parseTree, valueMap) ->

    @observers = []

    @rangeSet = rangeSet
    @rangeSet.addObserver @

    @symbols = symbols
    @symbols.addObserver @

    @errors = makeObservableArray []
    @errors.addObserver @

    @suggestions = makeObservableArray []
    @suggestions.addObserver @

    @edits = makeObservableArray []
    @edits.addObserver @

    @codeBuffer = codeBuffer
    @parseTree = parseTree
    @valueMap = valueMap
    @errorChoice = null
    @resolutionChoice = null

    @state = ExampleModelState.ANALYSIS

  onPropertyChanged: (object, propertyName, propertyValue) ->
    @notifyObservers object, propertyName, propertyValue

  addObserver: (observer) ->
    @observers.push observer

  notifyObservers: (object, propertyName, propertyValue) ->
    # For now, it's sufficient to bubble up the event
    if propertyName is RangeSetProperty.ACTIVE_RANGES_CHANGED
      propertyName = ExampleModelProperty.ACTIVE_RANGES
    else if object is @symbols
      propertyName = ExampleModelProperty.UNDEFINED_USES
    else if object is @edits
      propertyName = ExampleModelProperty.EDITS
    else if object is @
      proprtyName = propertyName
    else
      propertyName = ExampleModelProperty.UNKNOWN
    for observer in @observers
      observer.onPropertyChanged this, propertyName, propertyValue

  setState: (state) ->
    @state = state
    @notifyObservers this, ExampleModelProperty.STATE, @state

  getState: ->
    @state

  getRangeSet: ->
    @rangeSet

  getCodeBuffer: ->
    @codeBuffer

  getSymbols: ->
    @symbols

  setErrorChoice: (error) ->
    @errorChoice = error
    @notifyObservers @, ExampleModelProperty.ERROR_CHOICE, @errorChoice

  getErrorChoice: ->
    @errorChoice

  setResolutionChoice: (resolution) ->
    @resolutionChoice = resolution
    @notifyObservers @, ExampleModelProperty.RESOLUTION_CHOICE, @resolutionChoice

  getResolutionChoice: ->
    @resolutionChoice

  getValueMap: ->
    @valueMap

  setValueMap: (valueMap) ->
    @valueMap = valueMap
    @notifyObservers @, ExampleModelProperty.VALUE_MAP, @valueMap

  setErrors: (errors) ->
    @errors.reset errors
    @notifyObservers @, ExampleModelProperty.ERRORS, @errors

  getErrors: ->
    @errors

  getParseTree: ->
    @parseTree

  setSuggestions: (suggestions) ->
    @suggestions.reset suggestions

  getSuggestions: ->
    @suggestions

  getEdits: ->
    @edits
