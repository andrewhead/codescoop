module.exports.SymbolSetProperty = SymbolSetProperty =
  UNDEFINED_USE_ADDED: 0


module.exports.SymbolSet = class SymbolSet

  constructor: ->
    @undefinedUses = []
    @observers = []

  addUndefinedUse: (use) ->
    @undefinedUses.push use
    @notifyObservers SymbolSetProperty.UNDEFINED_USE_ADDED, use

  addObserver: (observer) ->
    @observers.push observer

  notifyObservers: (propertyName, propertyValue) ->
    for observer in @observers
      observer.onPropertyChanged this, propertyName, propertyValue

  getUndefinedUses: ->
    @undefinedUses
