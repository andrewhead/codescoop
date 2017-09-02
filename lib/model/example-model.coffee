
{ makeObservableArray } = require "./observable-array"
{ RangeSet, RangeSetProperty } = require "./range-set"
{ SymbolSet } = require "./symbol-set"


module.exports.ExampleModelProperty = ExampleModelProperty =
  UNKNOWN: { value: -1, name: "unknown" }
  ACTIVE_RANGES: { value: 0, name: "active-ranges" }
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
  STUB_SPEC_TABLE: { value: 12, name: "stub-table" }
  STUB_SPECS: { value: 13, name: "stub-specs" }
  PARSE_TREE: { value: 14, name: "parse-tree" }
  IMPORT_TABLE: { value: 15, name: "import-table" }
  IMPORTS: { value: 16, name: "imports" }
  EVENTS: { value: 17, name: "events" }
  VIEWED_EVENTS: { value: 18, name: "viewed-events" }
  PROPOSED_EXTENSION: { value: 19, name: "proposed-extension" }
  FOCUSED_EVENT: { value: 20, name: "focused-event" }
  EXTENSION_DECISION: { value: 21, name: "extension-decision-made" }
  THROWS: { value: 22, name: "throws-changed" }
  CHOSEN_RANGES: { value: 23, name: "chosen-ranges" }
  SYMBOL_TABLE: { value: 24, name: "symbol-table" }
  RANGE_GROUP_TABLE: { value: 25, name: "range-group-table" }
  PRINTED_SYMBOLS: { value: 26, name: "printed-symbols" }


module.exports.ExampleModelState = ExampleModelState =
  ANALYSIS: { value: 0, name: "analysis" }
  IDLE: { value: 1, name: "idle" }
  ERROR_CHOICE: { value: 2, name: "error-choice" }
  RESOLUTION: { value: 3, name: "resolution" }
  EXTENSION: { value: 4, name: "extension" }


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

    @events = makeObservableArray []
    @events.addObserver @
    @viewedEvents = makeObservableArray []
    @viewedEvents.addObserver @

    @edits = makeObservableArray []
    @edits.addObserver @

    @auxiliaryDeclarations = makeObservableArray []
    @auxiliaryDeclarations.addObserver @

    @printedSymbols = makeObservableArray []
    @printedSymbols.addObserver @

    @imports = makeObservableArray []
    @imports.addObserver @

    @throws = makeObservableArray []
    @throws.addObserver @

    @errorChoice = null
    @resolutionChoice = null
    @activeCorrector = null

    @codeBuffer = codeBuffer
    @parseTree = parseTree
    @valueMap = valueMap
    @stubOption = null
    @stubSpecTable = null
    @stubSpecs = makeObservableArray []
    @symbolTable = null
    @rangeGroupTable = null

    @focusedEvent = null
    @proposedExtension = null
    @extensionDecision = null

    @state = ExampleModelState.ANALYSIS

  onPropertyChanged: (object, propertyName, oldValue, newValue) ->
    @notifyObservers object, propertyName, oldValue, newValue

  addObserver: (observer) ->
    @observers.push observer

  notifyObservers: (object, propertyName, oldValue, newValue) ->
    # For now, it's sufficient to bubble up the event
    if propertyName is RangeSetProperty.ACTIVE_RANGES_CHANGED
      propertyName = ExampleModelProperty.ACTIVE_RANGES
    else if propertyName is RangeSetProperty.CHOSEN_RANGES_CHANGED
      propertyName = ExampleModelProperty.CHOSEN_RANGES
    else if object is @edits
      propertyName = ExampleModelProperty.EDITS
    else if object is @auxiliaryDeclarations
      propertyName = ExampleModelProperty.AUXILIARY_DECLARATIONS
    else if object is @imports
      propertyName = ExampleModelProperty.IMPORTS
    else if object is @throws
      propertyName = ExampleModelProperty.THROWS
    else if object is @errors
      propertyName = ExampleModelProperty.ERRORS
    else if object is @events
      propertyName = ExampleModelProperty.EVENTS
    else if object is @viewedEvents
      propertyName = ExampleModelProperty.VIEWED_EVENTS
    else if object is @printedSymbols
      propertyName = ExampleModelProperty.PRINTED_SYMBOLS
    else if object is @
      proprtyName = propertyName
    else
      propertyName = ExampleModelProperty.UNKNOWN
    for observer in @observers
      observer.onPropertyChanged this, propertyName, oldValue, newValue

  setState: (state) ->
    oldState = state
    @state = state
    @notifyObservers this, ExampleModelProperty.STATE, oldState, @state

  getState: ->
    @state

  getRangeSet: ->
    @rangeSet

  getCodeBuffer: ->
    @codeBuffer

  getSymbols: ->
    @symbols

  setErrorChoice: (errorChoice) ->
    oldErrorChoice = @errorChoice
    @errorChoice = errorChoice
    @notifyObservers @, ExampleModelProperty.ERROR_CHOICE, oldErrorChoice,
      @errorChoice

  getErrorChoice: ->
    @errorChoice

  setActiveCorrector: (corrector) ->
    oldCorrector = @activeCorrector
    @activeCorrector = corrector
    @notifyObservers @, ExampleModelProperty.ACTIVE_CORRECTOR, oldCorrector,
      @activeCorrector

  getActiveCorrector: ->
    @activeCorrector

  setResolutionChoice: (resolution) ->
    oldResolution = @resolutionChoice
    @resolutionChoice = resolution
    @notifyObservers @, ExampleModelProperty.RESOLUTION_CHOICE, oldResolution,
      @resolutionChoice

  getResolutionChoice: ->
    @resolutionChoice

  getValueMap: ->
    @valueMap

  setValueMap: (valueMap) ->
    oldValueMap = @valueMap
    @valueMap = valueMap
    @notifyObservers @, ExampleModelProperty.VALUE_MAP, oldValueMap, @valueMap

  setErrors: (errors) ->
    @errors.reset errors

  getErrors: ->
    @errors

  setParseTree: (parseTree) ->
    oldParseTree = @parseTree
    @parseTree = parseTree
    @notifyObservers @, ExampleModelProperty.PARSE_TREE, oldParseTree,
      @parseTree

  getParseTree: ->
    @parseTree

  setSuggestions: (suggestions) ->
    @suggestions.reset suggestions

  getSuggestions: ->
    @suggestions

  getEdits: ->
    @edits

  getEvents: ->
    @events

  getViewedEvents: ->
    @viewedEvents

  getAuxiliaryDeclarations: ->
    @auxiliaryDeclarations

  getStubOption: ->
    @stubOption

  setStubOption: (stubOption) ->
    oldStubOption = @stubOption
    @stubOption = stubOption
    @notifyObservers @, ExampleModelProperty.STUB_OPTION, oldStubOption,
      @stubOption

  getStubSpecTable: ->
    @stubSpecTable

  setStubSpecTable: (stubSpecTable) ->
    oldStubSpecTable = @stubSpecTable
    @stubSpecTable = stubSpecTable
    @notifyObservers @, ExampleModelProperty.STUB_SPEC_TABLE, oldStubSpecTable,
      @stubSpecTable

  getStubSpecs: ->
    @stubSpecs

  setImportTable: (importTable) ->
    oldImportTable = @importTable
    @importTable = importTable
    @notifyObservers @, ExampleModelProperty.IMPORT_TABLE, oldImportTable,
      @importTable

  getImportTable: ->
    @importTable

  setSymbolTable: (symbolTable) ->
    oldSymbolTable = @symbolTable
    @symbolTable = symbolTable
    @notifyObservers @, ExampleModelProperty.SYMBOL_TABLE, oldSymbolTable,
      @symbolTable

  getSymbolTable: ->
    @symbolTable

  setRangeGroupTable: (rangeGroupTable) ->
    oldRangeGroupTable = @rangeGroupTable
    @rangeGroupTable = rangeGroupTable
    @notifyObservers @, ExampleModelProperty.RANGE_GROUP_TABLE,
      oldRangeGroupTable, @rangeGroupTable

  getPrintedSymbols: () ->
    @printedSymbols

  getRangeGroupTable: ->
    @rangeGroupTable

  getImports: ->
    @imports

  getThrows: ->
    @throws

  getProposedExtension: ->
    @proposedExtension

  setProposedExtension: (proposedExtension) ->
    oldProposedExtension = @proposedExtension
    @proposedExtension = proposedExtension
    @notifyObservers @, ExampleModelProperty.PROPOSED_EXTENSION,
      oldProposedExtension, proposedExtension

  getFocusedEvent: ->
    @focusedEvent

  setFocusedEvent: (focusedEvent) ->
    oldFocusedEvent = @focusedEvent
    @focusedEvent = focusedEvent
    @notifyObservers @, ExampleModelProperty.FOCUSED_EVENT,
      oldFocusedEvent, focusedEvent

  getExtensionDecision: ->
    @extensionDecision

  setExtensionDecision: (extensionDecision) ->
    oldExtensionDecision = @extensionDecision
    @extensionDecision = extensionDecision
    @notifyObservers @, ExampleModelProperty.EXTENSION_DECISION,
      oldExtensionDecision, extensionDecision
