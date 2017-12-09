module.exports.AddThrows = class AddThrows

  constructor: (throwableName) ->
    @throwableName = throwableName

  apply: (model) ->
    model.getThrows().push @throwableName

  revert: (model) ->
    model.getThrows().remove @throwableName

  getThrowableName: ->
    @throwableName
