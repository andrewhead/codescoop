{ Range } = require "../model/range-set"
{ ThrowsTable, Exception } = require "../model/throws-table"
{ loadJson } = require "../config/paths"


# See DataflowAnalysis for note about naming convention with "J" suffix
module.exports.ThrowsAnalysis = class ThrowsAnalysis

  constructor: (file) ->
    @file = file

  run: (callback, err) ->
    loadJson @file.getName(), "ThrowsTable", (error, json) =>
      err error if error
      callback ThrowsTable.deserialize json
