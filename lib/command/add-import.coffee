module.exports.AddImport = class AddImport

  constructor: (import_) ->
    @import = import_

  apply: (model) ->
    model.getImports().push @import

  getImport: ->
    @import
