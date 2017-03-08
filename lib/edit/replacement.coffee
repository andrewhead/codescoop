module.exports.Replacement = class Replacement

  constructor: (range, text) ->
    @range = range
    @text = text

  getRange: ->
    @range

  getText: ->
    @text
