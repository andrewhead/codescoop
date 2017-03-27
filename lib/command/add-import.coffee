module.exports.AddImport = class AddImport

  constructor: (import_) ->
    @import = import_

  apply: (model) ->
    model.getImports().push @import

  revert: (model) ->
    model.getImports().remove @import

  getImport: ->
    @import
