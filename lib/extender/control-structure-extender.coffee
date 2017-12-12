{ getControlStructureRanges } = require "../../lib/analysis/parse-tree"
{ ControlCrossingEvent } = require "../event/control-crossing"
{ Range } = require "../model/range-set"
{ Extender } = require "./extender"


module.exports.ControlStructureExtension = class ControlStructureExtension

  constructor: (controlStructure, ranges, event) ->
    @controlStructure = controlStructure
    @ranges = ranges
    @event = event

  getControlStructure: ->
    @controlStructure

  getRanges: ->
    @ranges

  getEvent: ->
    @event


module.exports.ControlStructureExtender = class ControlStructureExtender extends Extender

  getExtension: (event) ->

    return null if not (event instanceof ControlCrossingEvent)

    controlStructure = event.getControlStructure()
    ranges = getControlStructureRanges controlStructure
    extension = new ControlStructureExtension controlStructure, ranges, event
