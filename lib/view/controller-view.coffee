$ = require 'jquery'
log = require "examplify-log"


module.exports.ControllerView = class ControllerView extends $

  constructor: (exampleEditor) ->
    @exampleEditor = exampleEditor

    element = $ "<div></div>"
      .addClass "controller"

    @undoButton = $ "<button></button>"
      .attr "id", "undo-button"
      .append @_svgForIcon "action-undo"
      .append "Undo"
      .click =>
        log.debug "Button press for undo"
        atom.commands.dispatch (atom.views.getView exampleEditor), "core:undo"
      .appendTo element

    @runButton = $ "<button></button>"
      .attr "id", "run-button"
      .append @_svgForIcon "play-circle"
      .append "Run"
      .click =>
        atom.commands.dispatch (atom.views.getView exampleEditor), "script:run"
      .appendTo element

    @.extend @, element

  _svgForIcon: (iconName )->
    PACKAGE_PATH = __dirname + "/../.."
    use = $ "<use></use>"
      .attr "xlink:href", "#{PACKAGE_PATH}/styles/open-iconic.svg##{iconName}"
      .addClass "icon-#{iconName}"
    svg = $ "<svg></svg>"
      .addClass "icon"
      .attr "width", "100%"
      .attr "height", "100%"
      .attr "viewBox", "0 0 8 8"
      .append use
    # We return HTML instead of the object based on this recommended hack:
    # https://stackoverflow.com/questions/3642035/
    $ "<div></div>"
      .append svg
      .html()

  getNode: ->
    @[0]
