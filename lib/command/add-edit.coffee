module.exports.AddEdit = class AddEdit

  constructor: (edit) ->
    @edit = edit

  apply: (model) ->
    model.getEdits().push @edit

  revert: (model) ->
    model.getEdits().remove @edit

  getEdit: ->
    @edit
