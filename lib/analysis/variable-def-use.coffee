{ Range } = require '../model/range-set'
{ Symbol } = require '../model/symbol-set'
{ loadJson } = require "../config/paths"


# The naming convention differs slightly for this file.
# Any object that represents an object in the Java
# runtime has the suffix "J".  No objects with this suffix
# should be passed out from this interface.
module.exports.VariableDefUseAnalysis = class VariableDefUseAnalysis

  constructor: (file) ->
    @file = file

  getDefs: ->
    @defs

  getUses: ->
    @uses

  run: (callback, err) ->
    @defs = []
    @uses = []
    loadJson @file.getName(), "Defs", (error, json) =>
      err error if error
      for defData in json
        @defs.push Symbol.deserialize defData
      loadJson @file.getName(), "Uses", (error, json) =>
        err error if error
        for useData in json
          @uses.push Symbol.deserialize useData
        callback @
