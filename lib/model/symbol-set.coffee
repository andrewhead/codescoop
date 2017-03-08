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


module.exports.Symbol = class Symbol

  # The range includes encompasses the start and end positions of the symbol
  # in the GitHub Atom text editor.  Lines and columns are zero-indexed.
  constructor: (file, name, range) ->
    @file = file
    @name = name
    @range = range

  equals: (other) ->
    (@file.equals other.file) and
      (@name is other.name) and
      (@range.isEqual other.range)

  getFile: ->
    @file

  getRange: ->
    @range

  getName: ->
    @name


module.exports.SymbolSet = class SymbolSet

  constructor: (symbolArrays = undefined) ->
    symbolArrays or= {}
    @uses = makeObservableArray (symbolArrays.uses or [])
    @defs = makeObservableArray (symbolArrays.defs or [])
    @allSymbols = makeObservableArray (symbolArrays.all or [])
    @observers = []

  addObserver: (observer) ->
    @observers.push observer

  notifyObservers: (propertyName, propertyValue) ->
    for observer in @observers
      observer.onPropertyChanged this, propertyName, propertyValue

  getAllSymbols: ->
    @allSymbols

  setUses: (uses) ->
    @uses.reset uses

  getUses: ->
    @uses

  setDefs: (defs) ->
    @defs.reset defs

  getDefs: ->
    @defs
