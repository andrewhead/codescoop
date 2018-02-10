{ loadJson } = require "../config/paths"
_ = require "lodash"


# A nest map that maps a filename, line number, and variable name to the values
# that that variable took on on that line.
module.exports.ValueMap = class ValueMap

  @deserialize: (json) ->
    valueMap = new ValueMap()
    _.merge valueMap, json


# While this currently relies on a Map loaded from Java using the node-java
# connector, it's reasonable to expect that this could also read in a
# pre-written local file instead.
module.exports.ValueAnalysis = class ValueAnalysis

  constructor: (file) ->
    @file = file

  run: (callback, err) ->
    loadJson @file.getName(), "ValueMap", (error, json) =>
      err error if error
      callback ValueMap.deserialize json
