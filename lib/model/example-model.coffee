{ makeObservableArray } = require "./observable-array"
{ RangeSet, RangeSetProperty } = require "./range-set"
{ SymbolSet } = require "./symbol-set"


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
  ACTIVE_CORRECTOR: { value: 9, name: "active-corrector" }
  AUXILIARY_DECLARATIONS: { value: 10, name: "auxiliary-declarations" }
  STUB_OPTION: { value: 11, name: "stub-option" }
  STUB_SPEC_TABLE: {value: 12, name: "stub-table" }
  STUB_SPECS: { value: 13, name: "stub-specs" }
  PARSE_TREE: { value: 14, name: "parse-tree" }
  IMPORT_TABLE: { value: 15, name: "import-table" }
  IMPORTS: { value: 16, name: "imports" }


module.exports.ExampleModelState = ExampleModelState =
  ANALYSIS: { value: 0, name: "analysis" }
  IDLE: { value: 1, name: "idle" }
  ERROR_CHOICE: { value: 2, name: "error-choice" }
  RESOLUTION: { value: 3, name: "resolution" }


module.exports.ExampleModel = class ExampleModel

  constructor: (codeBuffer, rangeSet, symbols, parseTree, valueMap) ->

    @observers = []

    @rangeSet = rangeSet or new RangeSet()
    @rangeSet.addObserver @

    @symbols = symbols or new SymbolSet()
    @symbols.addObserver @

    @errors = makeObservableArray []
    @errors.addObserver @

    @suggestions = makeObservableArray []
    @suggestions.addObserver @

    @edits = makeObservableArray []
    @edits.addObserver @

    @auxiliaryDeclarations = makeObservableArray []
    @auxiliaryDeclarations.addObserver @

    @imports = makeObservableArray []
    @imports.addObserver @

    @codeBuffer = codeBuffer
    @parseTree = parseTree
    @valueMap = valueMap
    @errorChoice = null
    @resolutionChoice = null
    @activeCorrector = null
    @stubOption = null
    @stubSpecTable = null
    @stubSpecs = []

    @state = ExampleModelState.ANALYSIS

  onPropertyChanged: (object, propertyName, propertyValue) ->
    @notifyObservers object, propertyName, propertyValue

  addObserver: (observer) ->
    @observers.push observer

  notifyObservers: (object, propertyName, propertyValue) ->
    # For now, it's sufficient to bubble up the event
    if propertyName is RangeSetProperty.ACTIVE_RANGES_CHANGED
      propertyName = ExampleModelProperty.ACTIVE_RANGES
    else if object is @edits
      propertyName = ExampleModelProperty.EDITS
    else if object is @auxiliaryDeclarations
      propertyName = ExampleModelProperty.AUXILIARY_DECLARATIONS
    else if object is @imports
      propertyName = ExampleModelProperty.IMPORTS
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

  setActiveCorrector: (corrector) ->
    @activeCorrector = corrector
    @notifyObservers @, ExampleModelProperty.ACTIVE_CORRECTOR, @activeCorrector

  getActiveCorrector: ->
    @activeCorrector

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

  setParseTree: (parseTree) ->
    @parseTree = parseTree
    @notifyObservers @, ExampleModelProperty.PARSE_TREE, @parseTree

  getParseTree: ->
    @parseTree

  setSuggestions: (suggestions) ->
    @suggestions.reset suggestions

  getSuggestions: ->
    @suggestions

  getEdits: ->
    @edits

  getAuxiliaryDeclarations: ->
    @auxiliaryDeclarations

  getStubOption: ->
    @stubOption

  setStubOption: (stubOption) ->
    @stubOption = stubOption
    @notifyObservers @, ExampleModelProperty.STUB_OPTION, @stubOption

  getStubSpecTable: ->
    @stubSpecTable

  setStubSpecTable: (stubSpecTable) ->
    @stubSpecTable = stubSpecTable
    @notifyObservers @, ExampleModelProperty.STUB_SPEC_TABLE, @stubSpecTable

  getStubSpecs: ->
    @stubSpecs

  setImportTable: (importTable) ->
    @importTable = importTable
    @notifyObservers @, ExampleModelProperty.IMPORT_TABLE, @importTable

  getImportTable: ->
    @importTable

  getImports: ->
    @imports
