module.exports.SymbolSetProperty = SymbolSetProperty =
  UNDEFINED_USE_ADDED: { value: 0, name: "undefined-use-added" }
  UNDEFINED_USES: { value: 1, name: "undefined-uses" }
  DEFINITION: { value: 2, name: "definition-set" }


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

  setUndefinedUses: (uses) ->
    @undefinedUses = uses
    @notifyObservers SymbolSetProperty.UNDEFINED_USES, @undefinedUses

  getDefinition: ->
    @definition

  setDefinition: (def) ->
    @definition = def
