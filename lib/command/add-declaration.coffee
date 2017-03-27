module.exports.AddDeclaration = class AddDeclaration

  constructor: (declaration) ->
    @declaration = declaration

  apply: (model) ->
    model.getAuxiliaryDeclarations().push @declaration

  revert: (model) ->
    model.getAuxiliaryDeclarations().remove @declaration

  getDeclaration: ->
    @declaration
