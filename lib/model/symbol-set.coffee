{ makeObservableArray } = require './observable-array'


module.exports.SymbolSetProperty = SymbolSetProperty =
  DEFINITION: { value: 2, name: "definition-set" }


# Symbol position is ambiguous without knowing the file in which it was found.
# This structure retains information about the file where a symbol was found.
module.exports.File = class File

  constructor: (path, fileName) ->
    @path = path
    @fileName = fileName

  getName: ->
    @fileName

  getPath: ->
    @path

  equals: (other) ->
    (other instanceof File) and
      (other.getPath() is @path) and
      (other.getName() is @fileName)


# This is a 'lite' version of Symbol, where all that is known is the
# range in a buffer where it appeared, and its name.  This can be useful,
# for instance, when we don't have the type, but still want to compare
# it to other symbols.
module.exports.SymbolText = class SymbolText

  constructor: (name, range) ->
    @name = name
    @range = range

  getName: ->
    @name

  getRange: ->
    @range

  equals: (other) ->
    (other instanceof SymbolText) and
      (@name is other.getName()) and
      (@range.isEqual other.getRange())


module.exports.Symbol = class Symbol

  # The range includes encompasses the start and end positions of the symbol
  # in the GitHub Atom text editor.  Lines and columns are zero-indexed.
  constructor: (file, name, range, type) ->
    @file = file
    @name = name
    @range = range
    @type = type

  equals: (other) ->
    (@file.equals other.getFile()) and
      (@name is other.getName()) and
      (@range.isEqual other.getRange()) and
      (@type is other.getType())

  matchesText: (symbolText) ->
    (@name is symbolText.getName()) and
      (@range is symbolText.getRange())

  getFile: ->
    @file

  getRange: ->
    @range

  getName: ->
    @name

  getType: ->
    @type


module.exports.SymbolSet = class SymbolSet

  constructor: (symbolArrays = undefined) ->
    symbolArrays or= {}
    @variableUses = makeObservableArray (symbolArrays.uses or [])
    @variableDefs = makeObservableArray (symbolArrays.defs or [])
    @typeUses = makeObservableArray (symbolArrays.typeUses or [])
    @typeDefs = makeObservableArray (symbolArrays.typeDefs or [])
    @observers = []

  addObserver: (observer) ->
    @observers.push observer

  notifyObservers: (propertyName, oldValue, newValue) ->
    for observer in @observers
      observer.onPropertyChanged this, propertyName, oldValue, newValue

  getAllSymbols: ->
    # Exhaustively accrue all symbols from the various subsets
    @variableUses.copy().concat @variableDefs.copy()

  setVariableUses: (variableUses) ->
    @variableUses.reset variableUses

  getVariableUses: ->
    @variableUses

  setVariableDefs: (variableDefs) ->
    @variableDefs.reset variableDefs

  getVariableDefs: ->
    @variableDefs

  setTypeUses: (typeUses) ->
    @typeUses.reset typeUses

  getTypeUses: ->
    @typeUses

  setTypeDefs: (typeDefs) ->
    @typeDefs.reset typeDefs

  getTypeDefs: ->
    @typeDefs
