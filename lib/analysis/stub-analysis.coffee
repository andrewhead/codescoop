{ StubSpec, StubSpecTable } = require "../model/stub"
{ loadJson } = require "../config/paths"


# We only create stubs for objects that are non-printable types.
# Those that can be easily substituted by a literal string ("printable types")
# include all primitives and strings.
module.exports.PRINTABLE_TYPE = PRINTABLE_TYPES =
  [ "byte", "short", "int", "long", "float", "double", "boolean",
    "char", "String" ]


module.exports.StubAnalysis = class StubAnalysis

  constructor: (file) ->
    @file = file

  run: (callback, err) ->
    loadJson @file.getName(), "StubSpecTable", (error, json) =>
      err error if error
      callback StubSpecTable.deserialize json
