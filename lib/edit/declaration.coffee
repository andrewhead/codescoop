module.exports.Declaration = class Declaration

  constructor: (name, type) ->
    @name = name
    @type = type

  getName: ->
    @name

  getType: ->
    @type
